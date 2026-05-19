# Sync Cart

End-to-end test: Add item to cart locally → Verify persisted in SharedPreferences → Confirm synced to backend.

## When to use
- After cart feature changes
- Verify cart persistence works
- Test backend cart sync
- Debug "cart not saving" issues
- Before shipping cart-related code

---

## Prerequisites

- Backend running: `cd prestige-men-backend && npm run start:dev`
- Flutter running: `cd PrestigeMen && flutter run -d chrome`
- Logged in user (auth token in SharedPreferences)

---

## Test Steps

### 1. Start Fresh (Clear Local Cache)
```bash
# Clear SharedPreferences in Flutter
# From Chrome DevTools (Flutter Web):
localStorage.clear()  # or in code: StorageService.clearAll()
```

### 2. Log In
- Navigate to SignInPage
- Enter valid credentials (backend user)
- Verify token stored: Check browser DevTools → Application → Local Storage → `auth_token`

### 3. Add Item to Cart
- Go to Products page
- Click "Add to Cart" on any product
- Verify SnackBar shows: "Item added to cart"

### 4. Check Local Persistence (SharedPreferences)
**Chrome DevTools:**
```
Open DevTools → Application → Local Storage → http://localhost:****
Look for key: `cart_items`
Expected: JSON array with product object
```

Example:
```json
[
  {
    "id": "product_123",
    "name": "Premium Watch",
    "price": 299.99,
    "quantity": 1,
    "image": "..."
  }
]
```

### 5. Check Backend Cart
```bash
# Get auth token from localStorage
TOKEN="<your_auth_token>"

# Fetch user's cart from backend
curl -X GET http://localhost:3000/api/cart \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

Expected response:
```json
{
  "items": [
    {
      "productId": "product_123",
      "quantity": 1,
      "price": 299.99
    }
  ],
  "total": 299.99
}
```

### 6. Verify Sync Happens
- Add another item in Flutter
- Wait 2 seconds (async sync)
- Check backend cart again
- Should have 2 items

### 7. Test Persistence (Hard Refresh)
```bash
# Close Flutter app
# Hard refresh browser: Ctrl+Shift+R (or Cmd+Shift+R)
# Reopen Flutter app: flutter run -d chrome
```

- Cart items should still show
- Verify localStorage still has `cart_items` key
- Verify backend still has items

### 8. Test Remove Item
- Remove item from cart in Flutter
- Verify SnackBar: "Item removed"
- Check backend: item gone
- Hard refresh: item still gone

---

## Checklist

- ✅ Local cart saved to SharedPreferences (`cart_items`)
- ✅ Backend receives add/update/remove calls
- ✅ Cart persists after hard refresh
- ✅ Quantities sync correctly
- ✅ Cart clears on logout
- ✅ No duplicate items (same product added twice = quantity++, not new entry)

---

## Common Issues & Fixes

| Issue | Check |
|-------|-------|
| Backend cart empty after add | Auth token valid? User has cart endpoint? |
| Local cart not saved | StorageService.saveCartItems() called? |
| Items duplicate on sync | Deduplication logic in `_addToCart()` working? |
| Cart clears on logout | StorageService.clearAll() being called? |
| Quantity not updating | Backend update endpoint exists? |

---

## Code References

**Frontend:**
- `lib/main.dart` → `_addToCart()`, `_persistCart()`, `_syncAddToBackend()`
- `lib/services/storage_service.dart` → `saveCartItems()`, `getCartItems()`
- `lib/services/api_service.dart` → `addToCart()`, `updateCartItem()`, `removeFromCart()`

**Backend:**
- `src/cart/` → Controllers, service, schema
- `POST /api/cart/add` — Add item
- `PATCH /api/cart/item/:productId` — Update quantity
- `DELETE /api/cart/item/:productId` — Remove item
- `GET /api/cart` — Get user's cart

---

**Run before**: Committing cart changes, code review, release
