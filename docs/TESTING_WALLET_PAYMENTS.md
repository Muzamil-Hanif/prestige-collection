# Testing Wallet Payments - Step-by-Step Guide

**Status:** Ready to Test  
**Date:** June 16, 2026  
**Wallet Support:** JazzCash & easyPaisa (Test Mode)

---

## 📋 Pre-Testing Checklist

Before you start, verify:

```
☐ Backend .env.development has SafePay credentials filled
☐ Backend is running: npm run start:dev
☐ Flutter app compiled and running: flutter run -d chrome
☐ MongoDB is running (for order storage)
☐ Test phone numbers ready (see below)
```

### Get Your SafePay Test Credentials

1. Go to: https://sandbox.api.getsafepay.com/dashboard
2. Login with your test account
3. Copy these values:
   - **SAFEPAY_API_KEY** (starts with `pub_` or `sec_`)
   - **SAFEPAY_SECRET_KEY** (long hex string)
   - **SAFEPAY_MERCHANT_ID** (your merchant ID)

4. Update `.env.development`:

```env
SAFEPAY_API_KEY=pub_your_actual_key_here
SAFEPAY_SECRET_KEY=sec_your_actual_secret_here
SAFEPAY_MERCHANT_ID=your_merchant_id_here
```

5. Restart backend: `npm run start:dev`

---

## 🧪 Test Scenario 1: JazzCash Wallet Payment (Happy Path)

### Step 1: Start Application

```bash
# Terminal 1 - Backend
cd prestige-men-backend
npm run start:dev
# Wait for: "Server running on port 3000"

# Terminal 2 - Flutter
cd PrestigeMen
flutter run -d chrome
# Wait for app to load
```

### Step 2: Create User Account

```
On app:
1. Tap "Sign Up"
2. Enter:
   - Email: test@example.com
   - Password: Test@123456
   - Full Name: Test User
   - Phone: +923009999999
3. Tap "Sign Up"
✅ You should be logged in
```

### Step 3: Add Items to Cart

```
1. Go to "Products" tab
2. Add items:
   - 1x Watch (PKR 150)
   - 1x Perfume (PKR 50)
   - (Any 2+ items)
3. Tap cart icon
✅ Cart shows items with prices
```

### Step 4: Proceed to Checkout

```
1. Tap "Checkout" button
2. Fill Address Step:
   - Full Name: Ahmad Khan
   - Email: ahmad@test.com
   - Country: Pakistan
   - Phone: 03001234567 (remove country code +92)
   - Street: 123 Main Street
   - City: Karachi
   - Zip: 75300
3. Tap "Next"
✅ Moves to checkout review
```

### Step 5: Review Order

```
1. Review Step shows:
   - Items list
   - Subtotal: PKR 200
   - Shipping: PKR 50
   - Total: PKR 250
2. Tap "Next"
✅ Moves to payment step
```

### Step 6: Select JazzCash Payment

```
1. Payment Method Step shows 5 options
2. Select "JazzCash" radio button
3. Enter wallet phone:
   - Phone: 03001234567 (this is TEST phone)
   - (No country code, app adds it)
4. Tap "Place Order"
✅ Order created in database
```

### Step 7: See "Payment Pending" Dialog

```
You should see this dialog:

┌─────────────────────────────────┐
│   ⏳ Payment Pending            │
│                                 │
│   Complete your payment on      │
│   JazzCash to confirm your      │
│   order.                        │
│                                 │
│   Order ID: 507f1f77bcf86cd...  │
│                                 │
│   [OK]                          │
└─────────────────────────────────┘

✅ This means order was created with:
   - paymentStatus: "pending"
   - status: "pending"
```

### Step 8: Tap OK (Simulate Customer Completing Payment)

```
1. Tap [OK] button
✅ Returns to home page
✅ Cart is cleared
✅ Order is now in database
```

### Step 9: Verify Order in Database

```bash
# In MongoDB shell or MongoDB Compass
# Query: db.orders.find({paymentStatus: "pending"})

Result should show:
{
  "_id": ObjectId("507f1f77..."),
  "status": "pending",
  "paymentStatus": "pending",
  "paymentMethod": "JazzCash",
  "walletPhone": "+923001234567",
  "items": [...],
  "totalPrice": 200,
  "shippingCost": 50,
  "grandTotal": 250,
  "createdAt": ISODate("2026-06-16T10:30:00Z"),
  "expiresAt": ISODate("2026-06-16T11:00:00Z")  // 30 min window
}

✅ Order created successfully
```

### Step 10: Admin Verifies Payment (Manual Test)

```bash
# Use Postman or cURL to verify payment

METHOD: PUT
URL: http://localhost:3000/api/orders/{orderId}/payment/verify

HEADERS:
  Authorization: Bearer {YOUR_JWT_TOKEN}
  Content-Type: application/json

BODY:
{
  "transactionId": "JAZZ_20260616_001"
}

RESPONSE (Success):
{
  "_id": "507f1f77...",
  "paymentStatus": "captured",
  "status": "processing",
  "paymentTransactionId": "JAZZ_20260616_001",
  "paymentConfirmedAt": "2026-06-16T10:33:46Z"
}

✅ Order updated to "processing"
✅ Payment confirmed
```

### Step 11: Check Order Status in App

```
1. Go to "Profile" tab
2. Tap "My Orders"
3. Find order #507f1f77

Shows:
  Status: ✅ Payment Confirmed
  Amount: PKR 250
  Order Date: Jun 16, 2026
  Expected Delivery: Jun 18-19, 2026
  
  [View Details] [Track]

✅ Payment confirmed successfully
```

---

## 🧪 Test Scenario 2: easyPaisa Wallet Payment

### Steps (Same as above, just change payment method)

```
Step 1-5: SAME (Create account, add items, checkout, review)

Step 6: Select easyPaisa instead of JazzCash
  - Select "easyPaisa" radio
  - Enter phone: 03009999999 (easyPaisa test number)
  - Tap "Place Order"

Step 7-11: SAME (See pending dialog, verify, check status)

Expected Result: SAME workflow
```

---

## ❌ Test Scenario 3: JazzCash - Insufficient Balance (Failure Case)

### Testing Payment Failure

```
Step 1-6: SAME (Setup, add items, select JazzCash)

Step 6 (DIFFERENT): Use test phone with NO balance
  - Phone: 03005555555 (This phone has PKR 0 balance)
  - Tap "Place Order"

Step 7: "Payment Pending" dialog shows
  (Same as success case - order still created)

Step 8: Admin tries to verify payment
  - Call: PUT /api/orders/{orderId}/payment/verify
  - Customer didn't actually complete payment
  - Admin can either:
    a) NOT verify (order stays pending)
    b) Manually verify anyway (order marked as paid)
    c) Cancel order (order marked as cancelled)

Expected Result:
  - Order stays in "pending" status
  - Customer can retry with different phone
  - No payment received from wallet
  - Order not fulfilled
```

---

## 📝 Manual Testing Workflow (Recommended)

### This is how to properly test JazzCash/easyPaisa flow:

```
WORKFLOW: User Perspective
═══════════════════════════

1. USER ACTION - Places Order
   App → Backend: POST /api/orders
   Backend creates order with paymentStatus: "pending"
   App shows "Payment Pending" dialog

2. USER ACTION - Closes Dialog
   User sees: Order ID: 507f1f77...
   User taps [OK]
   App navigates to home

3. SIMULATED REAL WORLD
   User would now:
   - Open JazzCash/easyPaisa app
   - Send money to merchant phone
   - Get confirmation: "Paid PKR 250"
   - Transaction ID: JAZZ_123456

4. ADMIN ACTION - Verify Payment (Backend)
   Admin checks SafePay merchant dashboard
   Sees: Transaction approved
   Calls backend API to verify:
     PUT /api/orders/{orderId}/payment/verify
     Body: { "transactionId": "JAZZ_123456" }
   Backend updates order: paymentStatus = "confirmed"

5. USER ACTION - Check Order Status
   User opens app
   Goes to My Orders
   Sees order with status: ✅ Payment Confirmed
   Order moves to fulfillment

RESULT: ✅ Complete flow tested
```

---

## 🔧 API Endpoints for Manual Testing

### 1. Create Order

```bash
POST http://localhost:3000/api/orders

Headers:
  Authorization: Bearer {JWT_TOKEN}
  Content-Type: application/json

Body:
{
  "items": [
    {
      "productId": "507f1f77bcf86cd799439012",
      "name": "Watch",
      "price": 150,
      "quantity": 1,
      "image": "https://..."
    },
    {
      "productId": "507f1f77bcf86cd799439013",
      "name": "Perfume",
      "price": 50,
      "quantity": 1,
      "image": "https://..."
    }
  ],
  "totalPrice": 200,
  "shippingCost": 50,
  "grandTotal": 250,
  "shippingAddress": {
    "fullName": "Ahmad Khan",
    "email": "ahmad@test.com",
    "phoneNumber": "+923001234567",
    "street": "123 Main Street",
    "city": "Karachi",
    "zipCode": "75300"
  },
  "paymentMethod": "JazzCash",
  "walletPhoneNumber": "+923001234567"
}

Response:
{
  "_id": "507f1f77...",
  "status": "pending",
  "paymentStatus": "pending",
  "grandTotal": 250
}
```

### 2. Verify Wallet Payment

```bash
PUT http://localhost:3000/api/orders/{orderId}/payment/verify

Headers:
  Authorization: Bearer {JWT_TOKEN}
  Content-Type: application/json

Body:
{
  "transactionId": "JAZZ_20260616_001"
}

Response:
{
  "_id": "507f1f77...",
  "paymentStatus": "captured",
  "status": "processing",
  "paymentTransactionId": "JAZZ_20260616_001"
}
```

### 3. Get Order Details

```bash
GET http://localhost:3000/api/orders/{orderId}

Headers:
  Authorization: Bearer {JWT_TOKEN}

Response:
{
  "_id": "507f1f77...",
  "status": "processing",
  "paymentStatus": "captured",
  "paymentMethod": "JazzCash",
  "items": [...],
  "grandTotal": 250,
  "paymentConfirmedAt": "2026-06-16T10:33:46Z"
}
```

### 4. Get User Orders

```bash
GET http://localhost:3000/api/orders

Headers:
  Authorization: Bearer {JWT_TOKEN}

Response:
[
  {
    "_id": "507f1f77...",
    "status": "processing",
    "paymentStatus": "captured",
    "grandTotal": 250,
    "createdAt": "2026-06-16T10:30:00Z"
  }
]
```

---

## 📊 Test Data Reference

### Test Phone Numbers

| Phone | Wallet | Balance | Status | Use Case |
|-------|--------|---------|--------|----------|
| `03001234567` | JazzCash | PKR 100,000 | ✅ Active | Happy path |
| `03009876543` | JazzCash | PKR 50,000 | ✅ Active | Happy path |
| `03005555555` | JazzCash | PKR 0 | ❌ No Balance | Failure test |
| `03009999999` | easyPaisa | PKR 100,000 | ✅ Active | Happy path |
| `03004444444` | easyPaisa | PKR 75,000 | ✅ Active | Happy path |
| `03007777777` | easyPaisa | PKR 0 | ❌ No Balance | Failure test |

### Test Card Numbers (SafePay)

| Card | Number | Expiry | CVV | Status |
|------|--------|--------|-----|--------|
| Visa | `4111111111111111` | Any future | Any 3 | ✅ Success |
| Mastercard | `5555555555554444` | Any future | Any 3 | ✅ Success |
| Amex | `378282246310005` | Any future | Any 4 | ✅ Success |

---

## ✅ Success Criteria

### JazzCash Payment Test - PASS Criteria

```
✅ Order created in database
✅ paymentStatus = "pending"
✅ status = "pending"
✅ expiresAt set to 30 minutes from now
✅ walletPhone stored correctly
✅ "Payment Pending" dialog shown to user
✅ Admin can verify payment via API
✅ After verification: paymentStatus = "captured"
✅ After verification: status = "processing"
✅ Order visible in user's order list
✅ Order shows correct payment status
```

### easyPaisa Payment Test - PASS Criteria

```
Same as JazzCash (workflow is identical)
Only difference: paymentMethod = "easyPaisa"
```

### Failure Test - PASS Criteria

```
✅ Order created with pending status
✅ User cannot complete payment (insufficient balance)
✅ Admin does not verify payment
✅ Order stays in "pending" status
✅ User can retry with different phone
✅ No duplicate orders created
✅ Stock released if order expires
```

---

## 🐛 Debugging Guide

### If Order Not Created

```
Check:
1. Backend running? npm run start:dev
2. MongoDB running? db.orders.find()
3. JWT token valid? Check browser console
4. Address validation passed? Check form validation

Fix:
- Restart backend
- Check .env file for DB connection
- Verify address validation rules
```

### If Dialog Not Showing

```
Check:
1. Payment method selected? (radio button marked)
2. Phone number filled? (required field)
3. Address step passed? (no validation errors)

Fix:
- Make sure you reach payment step
- Select payment method explicitly
- Fill all required fields
```

### If Verification Fails

```
Check:
1. Correct order ID? Use actual order ID
2. JWT token included? Required for auth
3. TransactionId format? Can be any string in test

Fix:
- Copy exact order ID from database
- Use valid JWT token from login
- Check backend logs for error details
```

---

## 📱 Testing on Different Devices

### Desktop (Chrome/Firefox)

```bash
flutter run -d chrome
# Use test numbers directly in input
```

### Mobile Phone

```bash
# Get your computer's IP
ipconfig getifaddr en0  # macOS
# or
ipconfig  # Windows, find IPv4

# Run with IP
flutter run --dart-define=API_BASE_URL=http://{YOUR_IP}:3000 -d ios
# or
flutter run --dart-define=API_BASE_URL=http://{YOUR_IP}:3000 -d android
```

---

## 📋 Checklist Before Going Live

```
Testing Complete Checklist:
════════════════════════════

☐ JazzCash wallet payment works
☐ easyPaisa wallet payment works
☐ "Payment Pending" dialog shows correctly
☐ Order created with correct status
☐ Admin verification endpoint works
☐ Order status updates after verification
☐ User can see order in "My Orders"
☐ Order history shows payment status
☐ SafePay card payment works (when ready)
☐ Cash on Delivery still works
☐ Database records are accurate
☐ No duplicate orders created
☐ Stock management works
☐ Error messages are clear
☐ App doesn't crash on any flow
☐ Backend logs are informative
```

---

## 🚀 Next Steps After Testing

Once testing passes:

```
1. ✅ Wallet payments working
   ↓
2. Add email notifications
   - Order confirmation email
   - Payment pending email
   - Payment verified email
   ↓
3. Add SMS notifications
   - Order created SMS
   - Payment pending SMS
   - Payment verified SMS
   ↓
4. Build admin dashboard
   - Order list
   - Payment verification interface
   - Manual verification button
   ↓
5. Add reconciliation job
   - Check for missed webhooks
   - Verify SafePay status
   - Auto-update orders if needed
   ↓
6. Production deployment
```

---

**Last Updated:** June 16, 2026  
**Status:** Ready for Testing  
**Test Mode:** Active
