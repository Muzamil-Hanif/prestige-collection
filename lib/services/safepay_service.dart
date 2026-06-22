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

  SafePaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.requestId,
    this.redirectUrl,
    this.note,
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

  /// Verify payment status after SafePay redirect
  static Future<SafePaymentResult> verifyPaymentStatus({
    required String orderId,
    required String requestId,
  }) async {
    try {
      final token = await StorageService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse(
        '${ApiConfig.baseUrl}$_paymentEndpoint/verify/$orderId/$requestId',
      );
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] == true;
        return SafePaymentResult(
          success: success,
          transactionId: data['transactionId'] as String?,
          message: success ? 'Payment successful' : 'Payment failed',
          note: data['note'] as String?,
        );
      } else {
        return SafePaymentResult(
          success: false,
          message: _extractErrorMessage(response.body, 'Failed to verify payment'),
          note: 'Server error - payment status could not be verified',
        );
      }
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return SafePaymentResult(
        success: false,
        message: 'Failed to verify payment: $e',
        note: 'Network error - check your connection and try again',
      );
    }
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
