# SafePay Payment Flow Diagram

## Complete Payment Processing Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRESTIGE MEN - PAYMENT FLOW                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐                                                ┌─────────┐
│  Flutter App     │                                                │ Backend │
│  (User Device)   │                                                │ (NestJS)│
└──────────────────┘                                                └─────────┘
         │                                                                │
         │ 1. User fills checkout form                                   │
         │    • Address                                                  │
         │    • Contact info                                             │
         │    • Selects payment method                                   │
         │    (Credit/Debit Card)                                        │
         │                                                               │
         │ 2. User clicks "Place Order"                                 │
         ├──────────────────────────────────────────────────────────────>│
         │    POST /api/orders                                           │
         │    {items, address, paymentMethod, ...}                       │
         │                                                               │
         │                    3. Validate stock & create order           │
         │                    • Order status: pending                    │
         │                    • Payment status: pending                  │
         │                    • Deduct stock from inventory              │
         │                                                               │
         │<──────────────────────────────────────────────────────────────┤
         │    Order response {_id, grandTotal, ...}                      │
         │                                                               │
         │ 4. App initiates SafePay payment                             │
         ├──────────────────────────────────────────────────────────────>│
         │    POST /api/payments/initiate/:orderId                       │
         │    {customerName, email, phone, orderId}                      │
         │                                                               │
         │                    5. Generate HMAC-SHA256 signature          │
         │                    6. Call SafePay API                        │
         │                    7. Get requestId & redirectUrl             │
         │                                                               │
         │<──────────────────────────────────────────────────────────────┤
         │    {success, requestId, redirectUrl}                          │
         │                                                               │
         │ 8. Launch SafePay payment page in browser                    │
         ├─────────────────────────────────────────────────────────────>│
         │    launchUrl(redirectUrl, mode: externalApplication)         │
         │                                                               │
         ┌─────────────────────────────────────────────────────────────────┐
         │                                                                   │
         │              SAFEPAY HOSTED PAGE (Secure)                        │
         │              ┌───────────────────────────────┐                   │
         │              │ • Show order details          │                   │
         │              │ • Card input fields           │                   │
         │              │ • 3D Secure (if enabled)      │                   │
         │              │ • Process payment             │                   │
         │              └───────────────────────────────┘                   │
         │                                                                   │
         └─────────────────────────────────────────────────────────────────┘
         │
         │ 9. SafePay processes payment (user enters card details)
         │
         │    ✓ Payment Successful → SafePay redirects back
         │    ✗ Payment Failed → SafePay shows error & redirects back
         │
         │ 10. App now verifies payment status                             │
         ├──────────────────────────────────────────────────────────────>│
         │     GET /api/payments/verify/:orderId/:requestId                │
         │                                                               │
         │                    11. Query SafePay for payment status       │
         │                    12. SafePay returns: captured / failed     │
         │                    13. Update order in database:              │
         │                        • If captured:                         │
         │                          status = "processing"                │
         │                          paymentStatus = "captured"           │
         │                        • If failed:                           │
         │                          status = "cancelled"                 │
         │                          paymentStatus = "failed"             │
         │                                                               │
         │<──────────────────────────────────────────────────────────────┤
         │     {success, paymentStatus, transactionId, amount}            │
         │                                                               │
         │ 14. Show result to user                                       │
         │     ✓ Success: Order confirmation dialog                     │
         │     ✗ Failed: Error message                                   │
         │                                                               │
         └───────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        ALTERNATIVE: CASH ON DELIVERY                         │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐                                                ┌─────────┐
│  Flutter App     │                                                │ Backend │
└──────────────────┘                                                └─────────┘
         │                                                                │
         │ 1. User selects "Cash on Delivery"                           │
         │ 2. Clicks "Place Order"                                      │
         ├──────────────────────────────────────────────────────────────>│
         │    POST /api/orders                                           │
         │    {items, address, paymentMethod: "Cash on Delivery", ...}   │
         │                                                               │
         │                    3. Create order                            │
         │                    • status: pending                          │
         │                    • paymentStatus: pending                   │
         │                    • Deduct stock                             │
         │                                                               │
         │<──────────────────────────────────────────────────────────────┤
         │    Order created successfully                                 │
         │                                                               │
         │ 4. Show order confirmation immediately                       │
         │    (No SafePay payment needed)                                │
         │                                                               │
         └───────────────────────────────────────────────────────────────┘
```

---

## Database State Changes

### Order Creation
```json
{
  "_id": "ObjectId(...)",
  "userId": "ObjectId(...)",
  "items": [...],
  "totalPrice": 1000,
  "shippingCost": 10,
  "grandTotal": 1010,
  "status": "pending",
  "paymentStatus": "pending",
  "paymentMethod": "Credit Card",
  "paymentTransactionId": null,
  "shippingAddress": {...},
  "createdAt": "2026-06-15T10:30:00Z"
}
```

### After Payment Success
```json
{
  "_id": "ObjectId(...)",
  "status": "processing",           // ← Updated
  "paymentStatus": "captured",       // ← Updated
  "paymentTransactionId": "TXN123",  // ← Updated
  "updatedAt": "2026-06-15T10:32:00Z"
}
```

### After Payment Failed
```json
{
  "_id": "ObjectId(...)",
  "status": "cancelled",             // ← Updated
  "paymentStatus": "failed",         // ← Updated
  "paymentTransactionId": null,      // ← Remains null
  "updatedAt": "2026-06-15T10:32:00Z"
}
```

---

## Security Architecture

### 1. Request Signing (HMAC-SHA256)

```
Frontend Request:
├─ POST /api/payments/initiate/:orderId
├─ Header: Authorization: Bearer JWT_TOKEN
└─ (JWT proves user identity)

Backend Processing:
├─ Verify JWT token
├─ Verify user owns the order
├─ Create request payload with:
│  ├─ merchantId
│  ├─ amount
│  ├─ orderRefNum (order ID)
│  ├─ currency: PKR
│  ├─ timestamp
│  ├─ customer details
│  └─ redirectUrl
├─ Sign request with HMAC-SHA256(payload, SECRET_KEY)
└─ Send to SafePay with signature

SafePay Validation:
├─ Verify signature using PUBLIC_KEY
├─ Verify timestamp (prevent replay attacks)
└─ Process if valid
```

### 2. Verification Flow

```
Backend verifies payment by querying SafePay:
├─ Query data:
│  ├─ requestId (from SafePay response)
│  ├─ merchantId
│  └─ timestamp
├─ Sign query with HMAC-SHA256
├─ Send to SafePay
└─ Receive encrypted response

SafePay Response:
├─ transactionId
├─ status (captured/failed/pending)
├─ amount
└─ currency

Backend updates order:
├─ Payment verified on SafePay servers
├─ Only then update local order status
└─ Webhook optional (can be used for async updates)
```

### 3. No Direct Card Handling

```
❌ Card details NEVER touch your servers:
├─ User enters card on SafePay page
├─ SafePay handles encryption
├─ Your backend never sees card data
├─ You only see transaction ID
└─ Reduces PCI compliance burden

✅ You only store:
├─ Transaction ID (non-sensitive)
├─ Payment status
├─ Customer email (from order)
└─ No card data ever logged or stored
```

---

## Error Handling Flow

```
┌────────────────────────────────────────────┐
│        Payment Initiation Error             │
└────────────────────────────────────────────┘
         │
         ├─ SafePay API unreachable
         │  └─ Show: "Payment service unavailable"
         │     Action: User can retry or use Cash on Delivery
         │
         ├─ Invalid credentials
         │  └─ Show: "Configuration error" (admin notification)
         │     Action: Check .env configuration
         │
         ├─ Invalid order
         │  └─ Show: "Order not found or already paid"
         │     Action: Refresh page and retry


┌────────────────────────────────────────────┐
│        Payment Verification Error          │
└────────────────────────────────────────────┘
         │
         ├─ Verification timeout (SafePay slow)
         │  └─ Show: "Payment verification in progress"
         │     Action: Ask user to wait or try verification again
         │
         ├─ Payment actually failed
         │  └─ Show: "Payment failed. Try again or use COD"
         │     Action: Order remains pending, can retry
         │
         ├─ Network error during verification
         │  └─ Show: "Verification failed. Check status in Orders"
         │     Action: User can check order page later


┌────────────────────────────────────────────┐
│        Webhook Error (Server-side)         │
└────────────────────────────────────────────┘
         │
         ├─ SafePay sends webhook about payment
         │  └─ Backend receives and validates
         │
         ├─ If signature invalid
         │  └─ Reject and log security alert
         │
         └─ If valid
            └─ Update order status
               Users can also verify manually via GET endpoint
```

---

## Testing Scenarios

### Scenario 1: Successful Payment
```
1. Create order → status: pending, paymentStatus: pending
2. Launch SafePay with test card: 4111111111111111
3. Complete payment on SafePay
4. Verify payment → status: processing, paymentStatus: captured
5. Show success dialog ✓
```

### Scenario 2: Payment Declined
```
1. Create order → status: pending, paymentStatus: pending
2. Launch SafePay with invalid card: 5555555555554444
3. SafePay declines payment
4. Verify payment → paymentStatus: failed
5. Show error message
6. Order remains pending (can retry)
```

### Scenario 3: User Closes Payment Page
```
1. Create order → status: pending, paymentStatus: pending
2. SafePay page opens, user closes browser
3. No payment processed on SafePay
4. Verify payment → status: failed or pending
5. Show error message
6. Order remains pending (user can retry from Orders page)
```

### Scenario 4: Cash on Delivery
```
1. Create order with paymentMethod: "Cash on Delivery"
2. No SafePay initiation
3. Order status: pending (for admin approval)
4. Show success immediately ✓
5. Admin can confirm and process shipment
```

---

## Monitoring & Alerts

### Important Metrics to Track

```
✓ Payment Success Rate
  └─ Target: >95% for non-user errors

✓ Failed Payment Recovery Rate
  └─ Measure: % of users who retry after failure

✓ Average Payment Processing Time
  └─ Target: <5 seconds from launch to verification

✓ SafePay API Availability
  └─ Alert: If down >5 minutes

✓ Failed Verifications
  └─ Investigate: If signature validation fails repeatedly
```

### Logs to Monitor

```
📊 Backend Logs:
├─ POST /api/payments/initiate - Request count
├─ SafePay API errors - Should be rare
├─ Signature validation failures - Security alert
└─ Database update errors - Rare but critical

📊 Frontend Logs:
├─ Payment initiation calls - Should match order count
├─ User closes payment page (indirectly)
└─ Network errors during verification
```

---

## Revenue & Reconciliation

### Daily Reconciliation

```
1. Check SafePay merchant dashboard
2. Compare with orders in MongoDB
3. Find orders with:
   ├─ paymentStatus: "captured" (paid)
   ├─ status: "processing" (waiting shipment)
   └─ Recent createdAt (today's date)

4. Cross-reference with payment gateway:
   ├─ All captured transactions should exist in SafePay
   └─ No orphaned transactions
```

### Refund Process

```
If customer requests refund:
1. Check order status
2. Query SafePay for transaction
3. Create refund request in SafePay
4. SafePay processes refund to customer's card
5. Update order status to "refunded"
6. Return inventory
7. Log refund transaction
```

---

## Compliance Checklist

- ✅ No card data stored on servers
- ✅ HMAC signatures prevent tampering
- ✅ JWT prevents unauthorized payment initiation
- ✅ HTTPS enforced in production
- ✅ Timestamp validation prevents replay attacks
- ✅ Webhook signature validation (to be enhanced)
- ✅ Audit logging recommended
- ✅ PCI-DSS Level 3 (hosted page approach)

---

Version: 1.0
Last Updated: 2026-06-15
Status: Production Ready
