class ApiConfig {
  // Single API base URL for every platform (Android/iOS/Web/Desktop).
  // PRODUCTION: Use HTTPS URL (https://api.prestigecollection.com)
  // DEVELOPMENT: Use HTTP for local testing (http://192.168.1.100:3000)
  // Example: flutter run --dart-define=API_BASE_URL=https://api.prestigecollection.com
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Use IPv4 loopback by default to avoid localhost -> ::1 issues.
    defaultValue: 'http://127.0.0.1:3000',
  );

  // Feature flags for security settings
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);

  static String get baseUrl {
    return _normalize(_configuredBaseUrl);
  }

  /// Validate URL scheme matches environment
  static bool isValidUrl(String url) {
    if (isProduction) {
      return url.startsWith('https://');
    }
    return true;
  }

  static List<String> get candidateBaseUrls {
    final primary = baseUrl;
    final uri = Uri.parse(primary);
    final set = <String>{primary};

    final host = uri.host.toLowerCase();
    final isLocalHost =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';

    if (isLocalHost) {
      final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
      final portPart = uri.hasPort ? ':${uri.port}' : '';
      set.add(_normalize('$scheme://localhost$portPart'));
      set.add(_normalize('$scheme://127.0.0.1$portPart'));
      set.add(_normalize('$scheme://[::1]$portPart'));
      set.add(_normalize('$scheme://10.0.2.2$portPart'));
    }

    return set.toList();
  }

  static String _normalize(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/users/register';
  static const String profile = '/users/profile';
  static const String changePassword = '/users/change-password';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String cart = '/cart';
}

