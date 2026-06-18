import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _cartItemsKey = 'cart_items';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'prestige_men_secure', publicKey: 'prestige_men_key'),
  );

  // On web, flutter_secure_storage can fail intermittently (WebCrypto API
  // availability, browser restrictions).  We wrap every secure read/write so
  // it transparently falls back to SharedPreferences on failure.

  static Future<void> _secureWrite(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write failed ($key), falling back to prefs: $e');
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('_secure_$key', value);
      } else {
        rethrow;
      }
    }
  }

  static Future<String?> _secureRead(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) return value;
      // Fall through to prefs fallback in case a previous write used it.
    } catch (e) {
      debugPrint('SecureStorage read failed ($key), falling back to prefs: $e');
    }
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('_secure_$key');
    }
    return null;
  }

  static Future<void> _secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorage delete failed ($key): $e');
    }
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('_secure_$key');
    }
  }

  // Save authentication token (encrypted)
  static Future<void> saveToken(String token) async {
    await _secureWrite(_tokenKey, token);
  }

  // Get authentication token
  static Future<String?> getToken() async {
    return _secureRead(_tokenKey);
  }

  // Save refresh token (encrypted)
  static Future<void> saveRefreshToken(String token) async {
    await _secureWrite(_refreshTokenKey, token);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    return _secureRead(_refreshTokenKey);
  }

  // Save token expiry timestamp
  static Future<void> saveTokenExpiry(int expiryMs) async {
    await _secureWrite(_tokenExpiryKey, expiryMs.toString());
  }

  // Get token expiry
  static Future<int?> getTokenExpiry() async {
    final expiry = await _secureRead(_tokenExpiryKey);
    return expiry != null ? int.tryParse(expiry) : null;
  }

  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiry;
  }

  // Save user ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Save user email
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<void> saveCartItems(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartItemsKey, rawJson);
  }

  static Future<String?> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cartItemsKey);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  // Clear all stored data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureDelete(_tokenKey);
    await _secureDelete(_refreshTokenKey);
    await _secureDelete(_tokenExpiryKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_cartItemsKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

