# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                          # Install dependencies
flutter run -d chrome                    # Run on Chrome
flutter run -d macos                     # Run on macOS desktop
flutter run -d ios                       # Run on iOS simulator/device
flutter run --dart-define=API_BASE_URL=http://<IP>:3000  # Physical device (dev)
flutter test                             # Run all tests
flutter build apk                        # Build Android APK
flutter build ios                        # Build iOS

# Production builds with security enforcement
flutter run --dart-define=API_BASE_URL=https://api.prestigecollection.com \
            --dart-define=IS_PRODUCTION=true
```

Run a single test file:
```bash
flutter test test/widget_test.dart
```

## Project Structure

### lib/ Organization
```
lib/
├── main.dart              # App entry, MaterialApp, theme, routing
├── models/                # Data models (User, Product, AuthResponse, MenuItem)
├── pages/                 # 23 screens (organized by feature: Auth, Products, Orders, etc.)
├── services/              # API, storage, session, navigation, SafePay integration
├── utils/                 # Helpers: responsive layout, order status, address validation
└── widgets/               # Reusable components (ResponsiveDrawer, etc.)
```

**Notable files:**
- `socket_exception_stub.dart` — Required for web compatibility (conditional import in `api_service.dart`)
- `home_page_clean.dart` — Consolidated home screen (1755-line duplicate removed June 2026)

**Archived documents:** Security and auth review reports moved to `docs/reports/`

## Architecture

### State Management
No external state management packages. State is owned at the `MainScreen` level in `main.dart` and passed down via callbacks. Key shared state:

- **Cart**: `_cartItems: List<Map<String, dynamic>>` in `MainScreen`, passed to child pages via `onAddToCart` / `onRemoveFromCart` / `onUpdateQuantity` callbacks. Persisted to `SharedPreferences` and synced to the backend asynchronously.
- **Auth**: JWT token stored encrypted via `flutter_secure_storage` (Android Keystore, iOS Keychain). Fetched per API call by `ApiService._getHeaders()` and validated for expiration.

### Authentication & Security

**Token Storage (Encrypted):**
- Tokens stored via `flutter_secure_storage` instead of SharedPreferences
- Platform-native encryption: Android Keystore, iOS Keychain
- `StorageService` handles all secure storage operations

**Token Validation:**
- JWT tokens validated before every API request using `jwt_decoder`
- Token expiration checked via `_isTokenValid()` in `ApiService`
- Expired tokens automatically trigger session cleanup and forced re-login
- Token expiry timestamp extracted from JWT claims during login

**HTTPS Enforcement:**
- Production builds enforce HTTPS-only URLs via `IS_PRODUCTION` flag
- `ApiService._validateUrl()` prevents HTTP in production
- All sensitive operations (auth, payments, profile) validate URL scheme

**Logout & Session Management:**
- `ApiService.logout()` notifies backend and clears all local credentials
- `StorageService.clearAll()` removes: token, refresh token, expiry, user data
- Graceful error handling if backend is unreachable

**Configuration:**
- `ApiConfig.isProduction` determines security enforcement level
- `ApiService.setProduction()` initialized in `main.dart` based on `ApiConfig`
- Development: HTTP allowed, Production: HTTPS required

### Navigation
Manual `Navigator.push/pushReplacement` — no named routes. `SplashScreen` is the entry gate: it checks `StorageService.isLoggedIn()` and routes to either `SignInPage` or `MainScreen`. `MainScreen` wraps all post-auth screens with a bottom navigation bar (Home, Products, Cart, Profile tabs).

### API Layer
`ApiService` (`lib/services/api_service.dart`) owns all HTTP calls. Base URL is resolved at runtime via `_getBaseUrl()`: it reads `--dart-define=API_BASE_URL`, falls back to `http://127.0.0.1:3000`, and auto-probes candidate hosts for local dev. The resolved URL is cached in `_resolvedBaseUrl`. All endpoints are defined as constants in `ApiConfig` (`lib/services/api_config.dart`).

Key normalization helpers in `ApiService`:
- `mongoIdToString()` — handles both plain string IDs and `{$oid: "..."}` MongoDB format
- `normalizeCartItemForUi()` — flattens nested product objects in cart responses
- `normalizeOrderLineForBackend()` — validates and prepares order line items for `POST /orders`

### Product Categories
Categories are integers matching the backend: `0=All, 1=Perfumes, 2=Watches, 3=Wallets, 4=Shirts`. Used for filtering in `ProductsPage` and `HomePage`.

### Checkout Flow
`CheckoutPage` is a 3-step stepper (address → review → payment). It calls `ApiService.createOrder()` on submission, which uses `normalizeOrderLineForBackend()` to validate items. On success it clears the cart and navigates home.

**Payment Methods:**
- Credit Card, Debit Card — via SafePay (external payment gateway)
- JazzCash, easyPaisa — mobile wallet options (processed as standard orders)
- Cash on Delivery — payment on delivery

### SafePay Payment Flow & Verification
When user selects Credit/Debit Card:

1. **Initiate:** `CheckoutPage` calls `SafePayService.initiatePayment()` → backend returns SafePay checkout URL + requestId
2. **External Page:** `SafePayService.launchPaymentPage()` opens SafePay in external browser (card details never touch app)
3. **Deep Link:** `DeepLinkService` listens for `prestigecollection://payment-callback?...` deep link from SafePay redirect
4. **Verification Retry:** When deep link received, `CheckoutPage._verifyAndCompletePayment()` retries verification up to 4 times with exponential backoff (1.5s, 3s, 4.5s, 6s). SafePay webhooks take 3-5s to process, so immediate verification would fail. Backend supports fallback using `requestId` if tracker token isn't available yet.
5. **Enhanced Feedback:** `SafePaymentResult.note` contains backend status details (e.g., "Webhook processing in progress...") and is displayed in error messages to users
6. **Success:** On successful verification, shows order confirmation dialog and clears cart
7. **Fallback:** If all retries fail, error message with detailed status directs user to check email or My Orders page (webhook may still be processing)

**Deep Link Configuration:**
- Android: Manifest intent-filter for `prestigecollection://payment-callback` (AndroidManifest.xml line 29-34)
- iOS: Info.plist URL scheme `prestigecollection` (Info.plist lines 54-63)
- Backend renders branded callback page with JS redirect + fallback button for web users

### Profile & Image Upload
`MyProfilePage` uses `ImagePicker` + `http.MultipartRequest` to upload profile photos to `PATCH /users/profile`. The profile is fetched on `HomePage` init and used to populate the drawer greeting.

## Backend Integration Requirements

### Logout Endpoint (CRITICAL)
The app now calls `POST /api/auth/logout` when user logs out. Add to `prestige-collection-backend`:

```typescript
// In auth.controller.ts
@Post('logout')
@UseGuards(JwtAuthGuard)
logout(@Req() req: Request) {
  // Optional: Invalidate token in Redis blacklist
  // Optional: Clear session from database
  return { message: 'Logged out successfully' };
}
```

**Error Handling:** App gracefully handles logout failures (always clears local storage).

### Token Expiry Configuration
Ensure backend JWT tokens have reasonable expiry times:
- `JWT_EXPIRES_IN=7d` (currently set in `.env`)
- App automatically detects expiry from JWT `exp` claim
- Expired tokens trigger forced re-login

### HTTPS Requirement
For production, backend must be served over HTTPS:
- Update `CORS_ORIGIN` to match HTTPS origin
- Certificate must be valid (no self-signed in production)
- App enforces HTTPS when `IS_PRODUCTION=true`

## Design System

All UI components must follow the design tokens documented in `design.md`. This ensures visual consistency across features.

**Reference before building new pages/components:**
- **Colors**: Primary (#111827), Secondary (#F2C94C), Surface (#1F2937), Background (#F5F5F5)
- **Typography**: Font sizes (9–28px), weights (w400–w700)
- **Spacing**: 4px base unit (8, 12, 16, 20, 24, etc.)
- **Border Radius**: sm (12px), md (16px), lg (28px)
- **Animations**: Use documented durations (260–600ms) and curves

See `design.md` for complete palette, component styles, and usage examples.

## Key Dependencies

| Package | Purpose | Security |
|---------|---------|----------|
| `http` | HTTP client for API calls | ✓ Used with token validation |
| `shared_preferences` | Persistent local storage | ⚠️ Only for non-sensitive data (cart) |
| `flutter_secure_storage` | Encrypted token storage | ✅ Tokens, refresh tokens, expiry |
| `jwt_decoder` | JWT validation and decoding | ✅ Token signature and expiry checks |
| `flutter_svg` | SVG asset rendering | — |
| `image_picker` | Profile photo upload | ✓ Used with multipart requests |

## Key Patterns

- **Cart Badge**: Bottom nav cart icon count updates reactively from `MainScreen._cartItems.length`.
- **Search Debounce**: `ProductsPage` uses a `Timer` to debounce search queries before API calls.
- **Banner Auto-Scroll**: `HomePage` cycles promo banners with a `PageController` + `Timer`.
- **No loading dialogs**: All async feedback is delivered via `SnackBar`, not modal dialogs.
- **Image normalization**: `ApiService` strips Google Images wrapper URLs to extract direct image URLs from product data.
- **Token Validation**: Every API request validates token expiration before attaching to headers.
- **HTTPS Enforcement**: Production builds enforce HTTPS via `IS_PRODUCTION` flag.
- **Payment Verification Error Handling**: `SafePayService.verifyPaymentStatus()` returns detailed `note` field from backend (e.g., "Webhook processing in progress..."). `CheckoutPage._verifyAndCompletePayment()` displays these notes in error SnackBar to provide users with clear feedback about what's happening. Includes 4-attempt exponential backoff (1.5–6s) and graceful fallback when webhook hasn't confirmed yet.
