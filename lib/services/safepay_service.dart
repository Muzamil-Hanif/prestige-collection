import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'api_config.dart';
import 'storage_service.dart';

class SafePaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? requestId;
  final String? redirectUrl;
  final String? note;

  /// True while the payment is still being confirmed (webhook/tracker not
  /// final yet). The UI keeps polling on `pending` instead of showing a false
  /// "Payment Failed". Distinct from a definitive failure (`!success && !pending`).
  final bool pending;

  /// Raw backend status: 'captured' | 'failed' | 'pending'.
  final String? paymentStatus;

  SafePaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.requestId,
    this.redirectUrl,
    this.note,
    this.pending = false,
    this.paymentStatus,
  });
}

class SafePayService {
  static const String _paymentEndpoint = '/payments';

  /// Initiate SafePay payment and return hosted page URL
  static Future<SafePaymentResult> initiatePayment({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final token = await StorageService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('${ApiConfig.baseUrl}$_paymentEndpoint/initiate/$orderId');
      final response = await http.post(
        url,
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final redirectUrl = data['redirectUrl'] as String?;
        if (redirectUrl == null || redirectUrl.isEmpty) {
          return SafePaymentResult(
            success: false,
            message: 'Payment gateway did not return a checkout link',
          );
        }
        return SafePaymentResult(
          success: true,
          requestId: data['requestId'] as String?,
          redirectUrl: redirectUrl,
          message: 'Payment initiated successfully',
        );
      } else {
        return SafePaymentResult(
          success: false,
          message: _extractErrorMessage(response.body, 'Failed to initiate payment'),
        );
      }
    } catch (e) {
      debugPrint('SafePay initiation error: $e');
      return SafePaymentResult(
        success: false,
        message: 'Failed to initiate payment: $e',
      );
    }
  }

  /// Pulls the backend's actual error message out of a non-2xx response
  /// body (NestJS's default error shape is `{statusCode, message, error}`)
  /// instead of showing a generic string that hides the real cause.
  static String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      final message = decoded is Map ? decoded['message'] : null;
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join(', ');
    } catch (_) {
      // Body wasn't JSON — fall through to the generic message.
    }
    return fallback;
  }

  /// Whether the backend actually has SafePay configured. Used by the
  /// checkout page to disable Credit/Debit Card instead of letting the
  /// user pick a payment method that's guaranteed to fail at submit time.
  static Future<bool> isCardPaymentAvailable() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$_paymentEndpoint/config');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cardPaymentsEnabled'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('SafePay config check error: $e');
      return false;
    }
  }

  /// Launch SafePay hosted page in browser/webview
  static Future<void> launchPaymentPage(String redirectUrl) async {
    try {
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch payment page');
      }
    } catch (e) {
      debugPrint('Error launching payment page: $e');
      rethrow;
    }
  }

  /// Verify payment status after SafePay redirect.
  ///
  /// [tracker] is the real SafePay tracker token delivered on the return
  /// deep-link/web callback — when available it's sent as `?tracker=` so the
  /// backend can verify against the authoritative tracker rather than the
  /// pre-checkout session [requestId].
  ///
  /// On a non-200/network error this returns `pending` (not a hard failure) so
  /// callers keep polling and let the webhook confirm authoritatively.
  static Future<SafePaymentResult> verifyPaymentStatus({
    required String orderId,
    required String requestId,
    String? tracker,
  }) async {
    try {
      final token = await StorageService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse(
        '${ApiConfig.baseUrl}$_paymentEndpoint/verify/$orderId/$requestId',
      ).replace(
        queryParameters: (tracker != null && tracker.isNotEmpty)
            ? {'tracker': tracker}
            : null,
      );
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] == true;
        final paymentStatus = data['paymentStatus'] as String?;
        // Treat the backend `pending` flag (or a 'pending' status) as not-final.
        final pending =
            data['pending'] == true ||
            (!success && (paymentStatus == null || paymentStatus == 'pending'));
        return SafePaymentResult(
          success: success,
          pending: pending,
          paymentStatus: paymentStatus,
          transactionId: data['transactionId'] as String?,
          message: success
              ? 'Payment successful'
              : (pending ? 'Awaiting confirmation' : 'Payment failed'),
          note: data['note'] as String?,
        );
      } else {
        // A transient server error is not a definitive failure — keep polling.
        return SafePaymentResult(
          success: false,
          pending: true,
          message: _extractErrorMessage(response.body, 'Failed to verify payment'),
          note: 'Server error - payment status could not be verified yet',
        );
      }
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return SafePaymentResult(
        success: false,
        pending: true,
        message: 'Failed to verify payment: $e',
        note: 'Network error - check your connection and try again',
      );
    }
  }

  /// Poll [verifyPaymentStatus] until the payment resolves (captured or a
  /// definitive failure) or [maxWait] elapses. Returns as soon as the status is
  /// final; while `pending` it keeps retrying with a gentle backoff so a slow
  /// webhook no longer surfaces as a false "Payment Failed".
  ///
  /// [onAttempt] (optional) fires after each attempt for progress/debug UI.
  static Future<SafePaymentResult> pollPaymentStatus({
    required String orderId,
    required String requestId,
    String? tracker,
    Duration maxWait = const Duration(seconds: 40),
    void Function(int attempt, SafePaymentResult result)? onAttempt,
  }) async {
    final deadline = DateTime.now().add(maxWait);
    SafePaymentResult last = SafePaymentResult(
      success: false,
      pending: true,
      note: 'Awaiting payment confirmation...',
    );
    var attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      // Backoff: 1.5s, 2.5s, 3.5s, ... capped at 5s.
      final delayMs = (1500 + attempt * 1000).clamp(1500, 5000);
      await Future.delayed(Duration(milliseconds: delayMs));

      last = await verifyPaymentStatus(
        orderId: orderId,
        requestId: requestId,
        tracker: tracker,
      );
      attempt++;
      onAttempt?.call(attempt, last);

      // Stop on any final result: confirmed success OR definitive failure.
      if (last.success || !last.pending) return last;
    }

    return last; // Timed out while still pending.
  }

  /// Open payment page in WebView (for in-app payment)
  static Future<SafePaymentResult> openPaymentInWebView({
    required String paymentUrl,
  }) async {
    // Implementation for WebView - useful if you want in-app payment experience
    // For hosted page approach, use launchPaymentPage instead
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
        return SafePaymentResult(
          success: true,
          message: 'Payment page opened',
        );
      } else {
        throw Exception('Could not launch payment page');
      }
    } catch (e) {
      return SafePaymentResult(
        success: false,
        message: 'Failed to open payment page: $e',
      );
    }
  }

  /// Helper to format phone number to E164 format if needed by SafePay
  static String formatPhoneForSafePay(String phoneWithCountryCode) {
    // SafePay expects format like +923001234567
    if (!phoneWithCountryCode.startsWith('+')) {
      return '+$phoneWithCountryCode';
    }
    return phoneWithCountryCode;
  }
}
