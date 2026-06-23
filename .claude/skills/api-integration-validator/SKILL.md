---
name: api-integration-validator
description: "Validate API contracts between Flutter and NestJS, verify JWT auth flow, test endpoints, check request/response schemas. Ask 'Validate login endpoint?' or 'Show API coverage'"
---

# API Integration Validator

Validate the integration between the Flutter frontend and NestJS backend. Verify API contracts, test endpoints, and ensure proper request/response handling.

## What It Does

Analyzes the API layer to help you understand:
- **API Coverage** — Which endpoints are used? Which are unused? Any missing implementations?
- **Data Contracts** — Do request/response schemas match? Are all required fields present?
- **Auth Flow** — Is JWT authentication implemented correctly? Are tokens properly included?
- **Error Handling** — How are API errors handled? Are error messages informative?
- **Status Codes** — Are endpoints returning correct HTTP status codes (200, 201, 401, 400, etc.)?
- **API Compatibility** — Does the Flutter app's API usage match the NestJS backend?

## How to Use

Ask natural questions about API integration:

```
"Is the login endpoint properly configured?"
"Validate the cart API contract between Flutter and backend"
"Show me all API endpoints and which ones are tested"
"Check if the products endpoint returns the correct data format"
"Verify the auth flow - how is the JWT token used?"
"Are there any API endpoints in the backend that aren't used by Flutter?"
"Test the order creation endpoint with sample data"
"What happens if an API call fails? How is it handled?"
```

## API Architecture

### Frontend API Layer (lib/services/api_service.dart)

**Base URL Resolution:**
- Configured via `--dart-define=API_BASE_URL=<url>`
- Falls back to `http://127.0.0.1:3000`
- Auto-probes candidate hosts (localhost, 127.0.0.1, ::1, 10.0.2.2 for Android)
- Appends `/api` to all endpoints

**Authentication:**
- JWT stored in SharedPreferences under `auth_token`
- Included in all protected requests: `Authorization: Bearer <token>`
- Public endpoints (login, register, products) don't require auth

**Data Normalization:**
- `mongoIdToString()` — Handles both string IDs and `{$oid: "..."}` format
- `normalizeCartItemForUi()` — Flattens nested product objects
- `normalizeOrderLineForBackend()` — Validates and prepares order items

**Error Handling:**
- Attempts to extract `message` or `error` from response JSON
- Falls back to HTTP status code if JSON parsing fails
- Wraps all errors in Exception with context (e.g., "Login failed: ...")

### Backend API Layer (NestJS prestige-collection-backend)

**Controllers:**
- `AppController` — `GET /api` (health check)
- `AuthController` — `POST /api/auth/login`
- `UsersController` — Register, profile CRUD, password change
- `ProductsController` — Product listing, search, filtering
- `CartController` — Add/remove/update cart items, sync
- `OrdersController` — Create orders, order history

**Standard Endpoints:**
```
Authentication:
  POST /api/auth/login                 — Login with email/password

Users:
  POST /api/users/register             — Register new account
  GET /api/users/profile               — Get logged-in user profile
  PATCH /api/users/profile             — Update profile (name, photo)
  PATCH /api/users/change-password     — Change password

Products:
  GET /api/products                    — List products (filters, pagination)
  GET /api/products/:id                — Get single product

Cart:
  GET /api/cart                        — Get user's cart items
  PUT /api/cart                        — Bulk update cart
  POST /api/cart/sync                  — Sync offline cart with server
  POST /api/cart/items                 — Add item to cart
  PATCH /api/cart/items/:productId     — Update item quantity
  DELETE /api/cart/items/:productId    — Remove item from cart
  DELETE /api/cart                     — Clear entire cart

Orders:
  POST /api/orders                     — Create order
  GET /api/orders                      — Get user's orders
  GET /api/orders/all                  — Get all orders (admin)
  GET /api/orders/:id                  — Get order by ID
  PUT /api/orders/:id/status           — Update order status
```

## Key Files

### Frontend
- `lib/services/api_service.dart` — All HTTP calls and data normalization
- `lib/services/api_config.dart` — Endpoint constants
- `lib/models/*.dart` — Data models (User, Product, AuthResponse, etc.)
- `lib/pages/*.dart` — Page logic that calls API methods

### Backend
- `src/auth/auth.controller.ts` — Login/token generation
- `src/users/users.controller.ts` — User CRUD and auth
- `src/products/products.controller.ts` — Product listing/filtering
- `src/cart/cart.controller.ts` — Cart operations
- `src/orders/orders.controller.ts` — Order creation/status
- `src/**/*.dto.ts` — Request/response schemas

## Query Examples

### Validate Endpoints
- "Is every API endpoint in the backend used by Flutter?"
- "What's the contract for the products endpoint?"
- "Validate the auth flow - token generation and usage"

### Test Data Contracts
- "Does the cart item format match between Flutter and backend?"
- "Show me the product schema - does it match what ProductModel expects?"
- "What fields are required for order creation?"

### Check Auth Implementation
- "How is the JWT token handled in the Flutter app?"
- "Are all protected endpoints checking Authorization header?"
- "What happens if the token expires?"

### Debug Integration Issues
- "Why is the cart sync failing?"
- "Are request headers properly formatted?"
- "What error is the backend returning for this request?"

### Performance & Standards
- "Are API calls using the correct HTTP methods (GET vs POST)?"
- "Which endpoints have proper error handling?"
- "Are query parameters correctly built and escaped?"

## Output Format

The skill will provide:
- **Endpoint mapping** — Flutter → Backend URL matching
- **Data contract validation** — Request/response schema verification
- **Auth flow diagram** — How tokens are generated, stored, and used
- **Coverage report** — Used vs unused endpoints
- **Issue list** — Mismatches, missing implementations, error handling gaps
- **Test results** — Sample API calls and responses
