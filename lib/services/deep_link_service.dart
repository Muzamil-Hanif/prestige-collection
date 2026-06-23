import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Listens for the custom `prestigecollection://` URL scheme used to bring the user
/// straight back into the app after completing (or cancelling) a SafePay
/// payment in the external browser, instead of relying on a manual "switch
/// back to the app" step.
///
/// SafePay's hosted page redirects the browser to our backend's
/// `/api/payments/callback/:status` page, which immediately does a JS
/// redirect into `prestigecollection://payment-callback?status=...&order_id=...
/// &tracker=...&sig=...` — the OS hands that straight to this app (see
/// `android/.../AndroidManifest.xml` intent-filter and
/// `ios/Runner/Info.plist` CFBundleURLTypes).
///
/// Call [init] once, early in app startup (see `main.dart`). Pages waiting
/// on a payment subscribe to [paymentCallbacks].
class DeepLinkService {
  DeepLinkService._();

  static late AppLinks _appLinks;
  static final StreamController<Uri> _paymentCallbackController =
      StreamController<Uri>.broadcast();
  static bool _initialized = false;

  /// Emits every incoming `prestigecollection://payment-callback` URI.
  static Stream<Uri> get paymentCallbacks => _paymentCallbackController.stream;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => debugPrint('DeepLinkService error: $e'),
    );
  }

  static void _handleUri(Uri uri) {
    debugPrint('DeepLinkService received URI: $uri');
    if (uri.scheme == 'prestigecollection' && uri.host == 'payment-callback') {
      debugPrint('Payment callback deep link received: $uri');
      _paymentCallbackController.add(uri);
    }
  }
}
