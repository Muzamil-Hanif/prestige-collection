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

  SafePaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.requestId,
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
        return SafePaymentResult(
          success: true,
          requestId: data['requestId'] as String?,
          message: 'Payment initiated successfully',
        );
      } else {
        return SafePaymentResult(
          success: false,
          message: 'Failed to initiate payment',
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
        );
      } else {
        return SafePaymentResult(
          success: false,
          message: 'Failed to verify payment',
        );
      }
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return SafePaymentResult(
        success: false,
        message: 'Failed to verify payment: $e',
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
