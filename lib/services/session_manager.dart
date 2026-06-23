import 'package:flutter/material.dart';
import '../pages/sign_in_page.dart';
import 'storage_service.dart';

/// Centralizes "the user is no longer authenticated" handling so any part
/// of the app (including non-widget code like ApiService) can force an
/// immediate redirect to the sign-in screen without depending on a
/// BuildContext that may already be deactivated (e.g. a dialog's context
/// after it has been popped) and without requiring the user to manually
/// refresh/restart the app.
class SessionManager {
  /// Attach this to MaterialApp's `navigatorKey` so we can navigate from
  /// the app's root navigator, independent of whatever screen/dialog
  /// triggered the logout.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _isRedirecting = false;

  /// Clears stored credentials and immediately pops back to the sign-in
  /// screen, removing every route in between. Safe to call multiple times
  /// concurrently (e.g. several in-flight requests failing at once) — only
  /// the first call performs the redirect.
  static Future<void> forceLogout({String? message}) async {
    if (_isRedirecting) return;
    _isRedirecting = true;
    try {
      await StorageService.clearAll();

      final navigatorState = navigatorKey.currentState;
      if (navigatorState == null || !navigatorState.mounted) return;

      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );

      if (message != null && navigatorState.mounted) {
        ScaffoldMessenger.of(navigatorState.context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      _isRedirecting = false;
    }
  }
}
