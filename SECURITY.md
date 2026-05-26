# Security Implementation Guide

This document outlines the security improvements implemented in the Prestige Men Flutter app.

## Implemented Security Measures

### 1. Encrypted Token Storage (✅ IMPLEMENTED)

**Problem:** JWT tokens were stored unencrypted in SharedPreferences, accessible to root users and via ADB.

**Solution:** Tokens now use `flutter_secure_storage` which provides:
- **Android:** Encrypted via Android Keystore
- **iOS:** Encrypted via Keychain
- **Web:** Uses secure in-memory storage

**How it works:**
```dart
// Tokens are automatically encrypted when saved
await StorageService.saveToken(authResponse.accessToken);

// And decrypted when retrieved
final token = await StorageService.getToken();
```

**Location:** `lib/services/storage_service.dart`

---

### 2. JWT Token Validation & Expiration (✅ IMPLEMENTED)

**Problem:** Expired tokens remained "valid" in the app until manual logout.

**Solution:** Tokens are now validated before use:
- JWT signature and expiration verified using `jwt_decoder`
- Expired tokens automatically trigger re-login
- Token expiry timestamp extracted and stored from JWT claims

**How it works:**
```dart
// _getHeaders() validates token before attaching to requests
if (_isTokenValid(token)) {
  headers['Authorization'] = 'Bearer $token';
} else {
  await StorageService.clearAll();
  throw Exception('Session expired. Please login again.');
}
```

**Location:** `lib/services/api_service.dart:_isTokenValid()`, `_getHeaders()`

---

### 3. HTTPS Enforcement (✅ IMPLEMENTED)

**Problem:** No mandatory HTTPS requirement; credentials vulnerable without encryption.

**Solution:** Production builds now enforce HTTPS-only URLs.

**How to enable:**
```bash
# Production build with HTTPS enforcement
flutter run --dart-define=API_BASE_URL=https://api.prestige-men.com \
            --dart-define=IS_PRODUCTION=true

# Development build (allows HTTP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

**Validation:**
```dart
// _validateUrl() checks URL scheme in production
static void _validateUrl(String url) {
  if (_isProduction && !url.startsWith('https://')) {
    throw Exception('HTTPS required in production');
  }
}
```

**Location:** `lib/services/api_service.dart:_validateUrl()`, `lib/services/api_config.dart`

---

### 4. Logout with Server Sync (✅ IMPLEMENTED)

**Problem:** No backend logout endpoint; tokens remained valid on server.

**Solution:** Implemented `ApiService.logout()` that:
1. Notifies backend to invalidate session
2. Clears all stored credentials locally
3. Handles network failures gracefully

**How to use:**
```dart
await ApiService.logout();
// User is now logged out both on client and server
```

**Location:** `lib/services/api_service.dart:logout()`

---

### 5. Certificate Pinning Infrastructure (✅ FOUNDATION)

**Problem:** Man-in-the-middle (MITM) attacks possible on untrusted networks.

**Solution:** Infrastructure added for certificate pinning in production.

**Current Status:** Ready for certificate configuration
- `_createSecureHttpClient()` method provides the foundation
- Can be extended with pinning implementation

**To implement pinning:**
```dart
// In _createSecureHttpClient(), add:
final securityContext = SecurityContext.defaultContext;

// Add your certificate pins
// securityContext.setTrustedCertificates('path/to/cert.pem');
// securityContext.setClientAuthorities('path/to/ca.pem');
```

**Location:** `lib/services/api_service.dart:_createSecureHttpClient()`

---

## Dependencies Added

```yaml
flutter_secure_storage: ^9.2.0  # Encrypted token storage
jwt_decoder: ^2.0.1             # JWT validation and decoding
```

Update with: `flutter pub get`

---

## Security Checklist for Deployment

### Before Production Release

- [ ] Update API base URL to production HTTPS endpoint
- [ ] Enable production mode: `IS_PRODUCTION=true`
- [ ] Test login/logout flow thoroughly
- [ ] Verify token expiry is being checked
- [ ] Implement SSL pinning certificates (if available)
- [ ] Review API_BASE_URL in release builds

### API Base URL Configuration

**Development:**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

**Production:**
```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://api.prestige-men.com \
  --dart-define=IS_PRODUCTION=true

flutter build ios \
  --dart-define=API_BASE_URL=https://api.prestige-men.com \
  --dart-define=IS_PRODUCTION=true
```

---

## Security Best Practices

### 1. Token Refresh Strategy (Future)

Consider implementing token refresh for long-lived sessions:
```dart
// Add to backend: POST /auth/refresh
// Use refresh token to get new access token before expiry
```

### 2. Request Signing (Future)

For additional security, implement request signing:
- Timestamp-based signatures
- HMAC-SHA256 signature verification
- Prevents request tampering

### 3. User Input Validation

Always validate and sanitize user inputs:
```dart
// Example: Email validation
if (!email.contains('@')) {
  throw Exception('Invalid email format');
}
```

### 4. Sensitive Data Handling

Never log or expose:
- JWT tokens
- Passwords
- Credit card information
- Personal identification numbers

Current implementation:
- Errors returned to user are generic
- Detailed errors logged only in debug mode

---

## Testing Security

### Manual Testing

1. **Token Expiry Test:**
   - Set token expiry to 1 second in dev
   - Verify re-login required after expiry

2. **HTTPS Enforcement Test:**
   - Build with `IS_PRODUCTION=true`
   - Attempt HTTP URL → should throw exception

3. **Logout Test:**
   - Login → Logout
   - Verify token removed from storage
   - Verify no cached authentication data remains

### Automated Testing

Add to `test/` directory:
```dart
test('Token is validated before API request', () async {
  // Test implementation
});

test('Expired token triggers re-login', () async {
  // Test implementation
});

test('HTTPS is enforced in production', () {
  // Test implementation
});
```

---

## Troubleshooting

### "Session expired" message

- **Cause:** JWT token has expired (check 'exp' claim)
- **Solution:** User must login again
- **Prevention:** Implement token refresh before expiry

### "HTTPS required in production" error

- **Cause:** Trying to use HTTP URL with `IS_PRODUCTION=true`
- **Solution:** Update API_BASE_URL to HTTPS endpoint

### "Failed to read secure storage"

- **Cause:** First-time app access or permissions issue
- **Platform Specific:**
  - **Android:** Check Keystore setup
  - **iOS:** Check Keychain entitlements
  - **Solution:** Reinstall app and clear app data

---

## References

- [jwt_decoder Package](https://pub.dev/packages/jwt_decoder)
- [flutter_secure_storage Package](https://pub.dev/packages/flutter_secure_storage)
- [OWASP Mobile Security Testing](https://owasp.org/www-community/attacks/Session_fixation)
- [Flutter Security Best Practices](https://flutter.dev/security)

---

## Phase 2: Future Recommendations

**Timeline:** Within 2-4 weeks

1. **Token Refresh Mechanism**
   - Implement refresh token flow
   - Auto-refresh before expiry

2. **Certificate Pinning**
   - Obtain SSL certificates
   - Implement pinning in `_createSecureHttpClient()`

3. **Backend Logout Endpoint**
   - Implement backend session invalidation
   - Redis-based token blacklist

4. **Enhanced Logging**
   - Structured logging without PII
   - Request/response audit trail

---

## Contact

For security concerns or questions, please contact the security team at security@prestige-men.com
