---
name: state-management-debugger
description: "Inspect app state, trace mutations, validate state consistency between SharedPreferences, MainScreen, and API. Ask questions like 'What's in the cart state?' or 'Trace cart sync flow'"
---

# State Management Debugger

Debug and inspect the PrestigeCollection app's state management system. Trace how data flows through SharedPreferences, MainScreen state, and user interactions.

## What It Does

Analyzes the app's state management layer to help you understand:
- **Current state snapshot** — What's in SharedPreferences (token, userId, email, cart items)?
- **State mutations** — How does state change during user actions (login, add to cart, etc.)?
- **State consistency** — Are cart items valid? Is the token fresh? Does user data match backend?
- **State dependencies** — Which pages depend on which state? How does state flow down?
- **Offline state** — What happens when the backend is unreachable?

## How to Use

Ask natural questions about state:

```
"What's in the app's state right now?"
"How does cart state flow from MainScreen to CartPage?"
"Trace what happens to the user token during login"
"Is the cart state consistent with the products in the database?"
"Show me the state mutations during checkout"
"What state persists when I close the app?"
```

## State Architecture

### Storage Layer (SharedPreferences)
- `auth_token` → JWT Bearer token for API calls
- `user_id` → Current user's MongoDB ID
- `user_email` → Current user's email (for display)
- `cart_items` → JSON array of cart items (id, name, price, quantity, image)

### MainScreen State
- `_cartItems: List<Map<String, dynamic>>` — In-memory cart (loaded from storage on init)
- `_cartItemCount` → Computed property for bottom nav badge
- Callbacks: `onAddToCart`, `onRemoveFromCart`, `onUpdateQuantity`

### Auth Flow
1. User logs in → `ApiService.login()` stores token + user data
2. On app start → `SplashScreen` checks `StorageService.isLoggedIn()`
3. Subsequent API calls → Include `Authorization: Bearer <token>` header
4. On logout → `StorageService.clearAll()` removes all data

### Cart Sync Strategy
1. **Load local cache** → Display persisted cart immediately (offline support)
2. **Fetch server cart** → If backend has items, merge/replace local
3. **Persist changes** → After add/remove/update, save to SharedPreferences AND sync to backend

## Key Files

- `lib/main.dart` — MainScreen._MainScreenState (state management hub)
- `lib/services/storage_service.dart` — SharedPreferences wrapper
- `lib/services/api_service.dart` — API calls and auth
- `lib/pages/my_cart.dart` → Uses MainScreen cart callbacks
- `lib/pages/checkout_page.dart` → Reads/clears cart on success

## Query Examples

### Understand Cart State
- "What cart items are persisted right now?"
- "How does a product get added to the cart?"
- "What's the difference between local cart and server cart?"

### Trace Auth State
- "Where is the JWT token stored and how is it used?"
- "What happens to state when I logout?"
- "How does the app verify if a user is logged in?"

### Check State Consistency
- "Are all cart items valid (id, name, price)?"
- "Is the user profile in sync with the backend?"
- "What state is lost if the backend is down?"

### Understand State Mutations
- "Trace the state changes during login"
- "What happens to cart state during checkout?"
- "How does the app handle API errors and state rollback?"

## Output Format

The skill will provide:
- **State snapshot** — Current values of all stored/in-memory state
- **Flow diagram** — How data moves between layers (UI → MainScreen → Storage → API)
- **Validation report** — Any inconsistencies or issues found
- **Recommendations** — Improvements or issues to address
