# Wallet Payment Testing Guide (Safe Mode)

This guide explains how to test JazzCash and easyPaisa wallet payments in **safe mode** with manual verification.

---

## 🎯 Overview

Wallet payments (JazzCash & easyPaisa) are now implemented with **"Payment Pending" status** instead of immediate confirmation. This ensures:

✅ Orders are created but payment is verified before fulfillment  
✅ No orders are confirmed without actual payment  
✅ Safe testing environment without real transactions  
✅ Future API integration ready  

---

## 📱 Testing Workflow

### Step 1: User Completes Checkout (Your App)

```
1. User adds items to cart
2. Goes to checkout
3. Selects "JazzCash" or "easyPaisa"
4. Enters wallet phone number
5. Completes address & payment details
6. Clicks "Place Order"
```

**Result:** ✅ Order created with `paymentStatus: "pending"`

### Step 2: App Shows "Payment Pending" Dialog

```
App displays:
┌─────────────────────────────┐
│  ⏳ Payment Pending          │
│                             │
│  Complete your payment on   │
│  [JazzCash/easyPaisa] to    │
│  confirm your order.        │
│                             │
│  Order ID: 507f1f77...      │
│                             │
│  [OK]                       │
└─────────────────────────────┘
```

**User clicks OK** → Returns to home page  
**Order status:** `paymentStatus: "pending"` ⏳

### Step 3: User Completes Payment in Wallet App (External)

```
1. User opens JazzCash/easyPaisa app
2. Completes the payment transaction
3. Wallet app shows: "Payment successful - Transaction ID: XXXXX"
4. User notes the Transaction ID
```

### Step 4: Admin Verifies Payment (Manual Verification)

**For Testing**, you'll verify payments manually:

#### Option A: Using Backend API (cURL)

```bash
# Verify JazzCash/easyPaisa payment
curl -X PUT http://localhost:3000/api/orders/{orderId}/payment/verify \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "JAZZ_TRANS_12345"
  }'

# Response:
{
  "_id": "507f1f77...",
  "paymentStatus": "captured",
  "paymentTransactionId": "JAZZ_TRANS_12345",
  "status": "processing"
}
```

#### Option B: Using Postman

1. **Import the collection** from `prestige-collection-backend/docs`
2. **Use endpoint:** `PUT /api/orders/{orderId}/payment/verify`
3. **Headers:**
   ```
   Authorization: Bearer {your_jwt_token}
   Content-Type: application/json
   ```
4. **Body:**
   ```json
   {
     "transactionId": "JAZZ_TRANS_12345"
   }
   ```

#### Option C: Admin Dashboard (Future)

Once you build an admin panel, add a verification button that calls the same endpoint.

---

## 🧪 Complete Test Scenario

### Scenario: Test JazzCash Payment

```
Step 1: Checkout in App
├─ Add items: Watch ($150) + Perfume ($50)
├─ Select "JazzCash"
├─ Enter phone: 03001234567
├─ Complete address
└─ Click "Place Order"

✅ Result: Order created
   - orderId: "507f1f77..."
   - paymentStatus: "pending"
   - paymentMethod: "JazzCash"

Step 2: App Shows Pending Dialog
├─ Dialog shows: "Payment Pending"
├─ User sees: Order ID: 507f1f77...
└─ User clicks OK

Step 3: User Completes Payment (Manual Simulation)
├─ In real world: User opens JazzCash app
├─ Completes payment
├─ Gets transaction ID: JAZZ_20260616_001

Step 4: Admin Verifies Payment
├─ API Call: PUT /api/orders/507f1f77.../payment/verify
├─ Body: { "transactionId": "JAZZ_20260616_001" }
└─ ✅ Order updated: paymentStatus = "captured"

Step 5: Order Processing
└─ Order now shows: status = "processing"
   - Ready for fulfillment
   - Payment verified
```

---

## 📋 Order Status Flow

### For Wallet Payments (JazzCash/easyPaisa)

```
[Checkout]
    ↓
[Order Created - paymentStatus: "pending"]
    ↓
[User Sees "Payment Pending" Dialog]
    ↓
[User Completes Wallet Payment]
    ↓
[Admin Verifies Payment via API]
    ↓
[Order Updated - paymentStatus: "captured", status: "processing"]
    ↓
[Order Ready for Fulfillment]
```

### For SafePay (Credit/Debit Cards)

```
[Checkout]
    ↓
[Order Created]
    ↓
[Redirect to SafePay]
    ↓
[User Completes Payment on SafePay]
    ↓
[Backend Verifies & Updates: paymentStatus: "captured"]
    ↓
[Order Ready for Fulfillment]
```

### For Cash on Delivery

```
[Checkout]
    ↓
[Order Created - paymentStatus: "captured" (COD doesn't require online payment)]
    ↓
[Success Dialog Shown]
    ↓
[Order Ready for Fulfillment]
```

---

## 🧪 Test Cases

### Test Case 1: JazzCash - Happy Path

```
Input:
  - Phone: 03001234567 (has sufficient balance)
  - Amount: PKR 500

Expected:
  1. Order created with paymentStatus: "pending"
  2. "Payment Pending" dialog shown
  3. Admin verifies payment via API
  4. paymentStatus updated to "captured"
  5. Order status: "processing"

✅ PASS
```

### Test Case 2: easyPaisa - Happy Path

```
Input:
  - Phone: 03009999999 (has sufficient balance)
  - Amount: PKR 800

Expected:
  1. Order created with paymentStatus: "pending"
  2. "Payment Pending" dialog shown
  3. Admin verifies payment via API
  4. paymentStatus updated to "captured"
  5. Order status: "processing"

✅ PASS
```

### Test Case 3: JazzCash - Insufficient Balance

```
Input:
  - Phone: 03005555555 (balance: PKR 0)
  - Amount: PKR 500

Expected:
  1. Order created with paymentStatus: "pending"
  2. "Payment Pending" dialog shown
  3. User attempts payment on wallet app
  4. Payment fails (insufficient balance)
  5. User contacts admin
  6. Admin does NOT verify payment
  7. Order remains: paymentStatus: "pending"

✅ PASS - Order not fulfilled until payment verified
```

### Test Case 4: SafePay - Card Payment

```
Input:
  - Card: 4111111111111111
  - Expiry: Any future date
  - CVV: Any 3 digits

Expected:
  1. Order created
  2. Redirected to SafePay
  3. Payment succeeds on SafePay
  4. Backend auto-verifies & updates: paymentStatus: "captured"
  5. Order confirmed

✅ PASS
```

### Test Case 5: Cash on Delivery

```
Input:
  - No payment required
  - Amount: PKR 1000

Expected:
  1. Order created with paymentStatus: "captured"
  2. Success dialog shown
  3. Order status: "processing"

✅ PASS
```

---

## 🔄 Database Queries for Testing

### Check Pending Orders

```javascript
// MongoDB
db.orders.find({ paymentStatus: "pending" })

// Returns all orders awaiting payment verification
[
  {
    "_id": ObjectId("507f1f77..."),
    "paymentMethod": "JazzCash",
    "paymentStatus": "pending",
    "status": "pending",
    "grandTotal": 500
  }
]
```

### Check Verified Orders

```javascript
db.orders.find({ paymentStatus: "captured" })

// Returns all verified/paid orders
[
  {
    "_id": ObjectId("507f1f77..."),
    "paymentMethod": "JazzCash",
    "paymentStatus": "captured",
    "paymentTransactionId": "JAZZ_20260616_001",
    "status": "processing",
    "grandTotal": 500
  }
]
```

### Update Order to Processing

```javascript
db.orders.updateOne(
  { _id: ObjectId("507f1f77...") },
  {
    $set: {
      paymentStatus: "captured",
      paymentTransactionId: "JAZZ_20260616_001",
      status: "processing"
    }
  }
)
```

---

## 🛠️ Development Setup

### Backend Configuration

Your `.env.development` already has test credentials:

```env
SAFEPAY_API_KEY=pub_xxxxx...
SAFEPAY_SECRET_KEY=sec_xxxxx...
SAFEPAY_MERCHANT_ID=Prestige Collections
SAFEPAY_REDIRECT_URL=http://localhost:3000
```

### Start Backend

```bash
cd prestige-collection-backend
npm run start:dev
```

Verify SafePay is working:
- Checkout page shows SafePay option
- Payment initiation works (or shows proper error if credentials wrong)

### Start Flutter App

```bash
cd PrestigeCollection
flutter run -d chrome  # or -d macos
```

Test payment flows:
1. SafePay (should redirect)
2. JazzCash (should show pending)
3. easyPaisa (should show pending)
4. COD (should show success)

---

## 📊 Testing Checklist

### Frontend Tests

- [ ] SafePay payment flow works (redirects)
- [ ] JazzCash shows "Payment Pending" dialog
- [ ] easyPaisa shows "Payment Pending" dialog
- [ ] COD shows success immediately
- [ ] Order ID is displayed correctly
- [ ] Insufficient balance doesn't break flow

### Backend Tests

- [ ] Orders created with correct paymentStatus
- [ ] SafePay verification updates orders correctly
- [ ] Wallet payment verification endpoint works
- [ ] paymentTransactionId is saved correctly
- [ ] Order status updated from "pending" to "processing"

### Database Tests

- [ ] Pending orders can be queried
- [ ] Captured orders can be queried
- [ ] Transaction IDs are stored correctly
- [ ] Order history shows payment status

---

## 🚀 Next Steps (Future)

### When Ready for Real Payments

1. **JazzCash API Integration**
   - Set up real merchant account
   - Implement API endpoints for payment initiation
   - Replace manual verification with webhook verification

2. **easyPaisa API Integration**
   - Set up real merchant account
   - Implement API endpoints for payment initiation
   - Replace manual verification with webhook verification

3. **Admin Panel**
   - Build dashboard to view pending orders
   - Add button to verify/reject payments
   - Send notifications to customers

---

## ⚠️ Important Notes

- 🔐 Test credentials are **development only**
- 📱 JazzCash/easyPaisa test numbers are **sandbox only**
- 💳 SafePay test cards are **always free** (no real charges)
- 🚫 **Never use production credentials in code**
- 🔒 Always use environment variables for sensitive data

---

**Last Updated:** June 16, 2026  
**Status:** Safe Mode - Ready for Testing
