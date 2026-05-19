# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                          # Install dependencies
flutter run -d chrome                    # Run on Chrome
flutter run -d macos                     # Run on macOS desktop
flutter run -d ios                       # Run on iOS simulator/device
flutter run --dart-define=API_BASE_URL=http://<IP>:3000  # Physical device
flutter test                             # Run all tests
flutter build apk                        # Build Android APK
flutter build ios                        # Build iOS
```

Run a single test file:
```bash
flutter test test/widget_test.dart
```

## Architecture

### State Management
No external state management packages. State is owned at the `MainScreen` level in `main.dart` and passed down via callbacks. Key shared state:

- **Cart**: `_cartItems: List<Map<String, dynamic>>` in `MainScreen`, passed to child pages via `onAddToCart` / `onRemoveFromCart` / `onUpdateQuantity` callbacks. Persisted to `SharedPreferences` and synced to the backend asynchronously.
- **Auth**: JWT token stored in `SharedPreferences` via `StorageService`. Fetched per API call by `ApiService._getHeaders()`.

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

### Profile & Image Upload
`MyProfilePage` uses `ImagePicker` + `http.MultipartRequest` to upload profile photos to `PATCH /users/profile`. The profile is fetched on `HomePage` init and used to populate the drawer greeting.

## Design System

All UI components must follow the design tokens documented in `design.md`. This ensures visual consistency across features.

**Reference before building new pages/components:**
- **Colors**: Primary (#111827), Secondary (#F2C94C), Surface (#1F2937), Background (#F5F5F5)
- **Typography**: Font sizes (9–28px), weights (w400–w700)
- **Spacing**: 4px base unit (8, 12, 16, 20, 24, etc.)
- **Border Radius**: sm (12px), md (16px), lg (28px)
- **Animations**: Use documented durations (260–600ms) and curves

See `design.md` for complete palette, component styles, and usage examples.

## Key Patterns

- **Cart Badge**: Bottom nav cart icon count updates reactively from `MainScreen._cartItems.length`.
- **Search Debounce**: `ProductsPage` uses a `Timer` to debounce search queries before API calls.
- **Banner Auto-Scroll**: `HomePage` cycles promo banners with a `PageController` + `Timer`.
- **No loading dialogs**: All async feedback is delivered via `SnackBar`, not modal dialogs.
- **Image normalization**: `ApiService` strips Google Images wrapper URLs to extract direct image URLs from product data.
