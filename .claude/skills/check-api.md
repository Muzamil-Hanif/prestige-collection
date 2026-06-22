# Check API

Verify NestJS backend is running and list available endpoints.

## When to use
- Before running Flutter app to ensure backend is reachable
- Troubleshoot API connection issues
- Verify auth endpoint is working
- Check health of database connection

---

## Steps

### 1. Check Backend Running
```bash
curl -s http://localhost:3000/api/docs | head -20
```
- ✅ Returns Swagger UI HTML = backend live
- ❌ Connection refused = backend not running

### 2. Start Backend if Needed
```bash
cd prestige-collection-backend
npm run start:dev
```
Wait for: `[Nest] ... Application successfully started`

### 3. List Available Endpoints
Swagger UI at: `http://localhost:3000/api/docs`

Key endpoints to verify:
- `POST /api/auth/login` — User login
- `GET /api/users/{id}` — Get user profile
- `GET /api/products` — List products
- `POST /api/cart/add` — Add to cart
- `POST /api/orders` — Create order

### 4. Test Auth Endpoint
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```
Expected: `{"access_token": "...", "user": {...}}`

### 5. Report Status
- ✅ Backend running: `http://localhost:3000`
- ✅ All endpoints accessible
- ✅ Auth working
- ✅ Ready for Flutter dev

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Port 3000 in use | `lsof -i :3000` then kill process |
| MongoDB not connected | Check `mongod` running or Atlas URI |
| CORS errors | Check `CORS_ORIGIN=*` in .env |
| Auth failing | Verify user exists in database |

---

**Run before**: `flutter run`, API testing, backend changes
