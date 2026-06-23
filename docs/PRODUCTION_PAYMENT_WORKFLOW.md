# Production-Grade Payment Workflow
## Complete SafePay + JazzCash Integration Guide

**Status:** Production-Ready  
**Last Updated:** June 16, 2026  
**Platforms:** Mobile App + Website (e-commerce)

---

## 📋 Table of Contents

1. [Complete Payment Flow](#complete-payment-flow)
2. [Customer Workflow](#customer-workflow)
3. [Payment Failure Scenarios](#payment-failure-scenarios)
4. [Payment Status Display](#payment-status-display)
5. [Abandoned Payment Handling](#abandoned-payment-handling)
6. [Industry Standards](#industry-standards-workflow)
7. [Admin Panel Requirements](#admin-panel-requirements)
8. [Payment Verification](#payment-verification)
9. [Database Structure](#database-structure)
10. [Order Lifecycle](#order-lifecycle)
11. [SafePay Integration](#safepay-integration-details)
12. [Webhook Handling](#webhook-handling)
13. [Reconciliation & Edge Cases](#reconciliation--edge-cases)
14. [Best Practices](#best-practices)

---

## 🔄 Complete Payment Flow

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    PAYMENT FLOW ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────────┘

CUSTOMER APP/WEBSITE
    │
    ├─→ [1] Create Order (pending)
    │
    ├─→ [2] Initiate Payment with SafePay/JazzCash
    │
    ├─→ [3] Redirect to Payment Gateway (SafePay)
    │
    └─→ [4] Complete Payment (user enters credentials)
            │
            └─→ [SafePay Backend]
                    │
                    ├─→ Process Payment with JazzCash
                    │
                    ├─→ Send Webhook to Your Backend
                    │
                    └─→ Redirect User to Success/Failure Page

YOUR BACKEND SERVER
    │
    ├─→ Listen for Webhooks (async)
    │
    ├─→ Verify Webhook Signature
    │
    ├─→ Query SafePay API for Status Confirmation
    │
    ├─→ Update Order Status in Database
    │
    └─→ Send Confirmation Email/SMS to Customer

ADMIN PANEL
    │
    ├─→ View All Orders with Payment Status
    │
    ├─→ Verify Payment Status
    │
    ├─→ Handle Failed/Abandoned Orders
    │
    └─→ Process Refunds if Needed
```

---

## 👥 Customer Workflow

### Step-by-Step: What Customer Sees

```
STEP 1: Checkout Page
┌──────────────────────────────────────┐
│ Cart Total: PKR 500                  │
│ Shipping: PKR 50                     │
│ Grand Total: PKR 550                 │
│                                      │
│ Payment Method:                      │
│ ○ Credit Card (SafePay)              │
│ ○ Debit Card (SafePay)               │
│ ○ JazzCash                           │
│ ● easyPaisa                          │
│                                      │
│ [Place Order Button]                 │
└──────────────────────────────────────┘
```

```
STEP 2: Order Created (Backend)
Backend creates order with:
  - status: "pending"
  - paymentStatus: "pending"
  - orderId: "507f1f77bcf86cd799439011"
  - createdAt: 2026-06-16T10:30:00Z

Database Lock: Order reserved for 15 minutes
              (prevent stock oversell)
```

```
STEP 3: Initiate Payment Request
App sends to backend:
{
  "orderId": "507f1f77bcf86cd799439011",
  "amount": 550,
  "paymentMethod": "JazzCash",
  "walletPhone": "+923009999999"
}

Backend calls SafePay API:
POST /api/v3/payment/initiate
```

```
STEP 4: SafePay Creates Payment Session
SafePay returns:
{
  "success": true,
  "requestId": "SPR_20260616_00123456",
  "redirectUrl": "https://gateway.safepay.com.pk/checkout/SPR_20260616_00123456"
}

App receives redirectUrl
```

```
STEP 5: Redirect to SafePay Hosted Page
┌─────────────────────────────────────┐
│   SafePay Secure Payment Gateway     │
│                                     │
│   Order: #507f1f77bcf86cd799439011  │
│   Amount: PKR 550                   │
│                                     │
│   Payment Method: JazzCash          │
│   Phone: +923009999999              │
│                                     │
│   [Confirm & Pay]  [Cancel]         │
└─────────────────────────────────────┘

App/Browser navigates to SafePay URL
```

```
STEP 6a: SUCCESSFUL PAYMENT PATH
┌──────────────────────────────┐
│  SafePay Processing...       │
│  ✓ JazzCash OTP verified     │
│  ✓ Amount deducted from wallet
│  ✓ Transaction successful    │
│  Transaction ID: JAZZ_123456 │
└──────────────────────────────┘
         │
         ├─→ SafePay Backend
         │   - Update transaction status
         │   - Prepare webhook
         │   - Send callback to your server
         │
         └─→ [Webhook to Your Backend]
             POST /api/webhooks/safepay
             Body: {
               "requestId": "SPR_20260616_00123456",
               "orderRefNum": "507f1f77bcf86cd799439011",
               "transactionId": "JAZZ_123456",
               "status": "captured",
               "amount": 55000, // in paisa
               "timestamp": 1687255800
             }
```

```
STEP 6b: FAILED PAYMENT PATH
┌──────────────────────────────┐
│  SafePay Processing...       │
│  ✗ JazzCash declined         │
│  ✗ Insufficient balance      │
│  ✗ OTP verification failed   │
│  Reason: INS_BALANCE         │
└──────────────────────────────┘
         │
         └─→ [Webhook to Your Backend]
             POST /api/webhooks/safepay
             Body: {
               "requestId": "SPR_20260616_00123456",
               "orderRefNum": "507f1f77bcf86cd799439011",
               "status": "failed",
               "failureReason": "INS_BALANCE",
               "amount": 55000
             }
```

```
STEP 7: Your Backend Processes Webhook
┌─────────────────────────────────────┐
│ [1] Verify Webhook Signature        │
│     ✓ Signature valid               │
│                                     │
│ [2] Check Idempotency               │
│     ✓ Not processed before          │
│                                     │
│ [3] Query SafePay API for Status    │
│     ✓ Status confirmed: "captured"  │
│                                     │
│ [4] Update Database                 │
│     Order.paymentStatus = "captured"│
│     Order.status = "processing"     │
│     TransactionLog created          │
│                                     │
│ [5] Send Notifications              │
│     - Email receipt to customer     │
│     - SMS confirmation              │
│     - In-app notification           │
│                                     │
│ [6] Trigger Fulfillment             │
│     - Reduce stock                  │
│     - Create shipment request       │
│     - Notify warehouse              │
│                                     │
│ [7] Return 200 OK to SafePay        │
└─────────────────────────────────────┘
```

```
STEP 8: Customer Redirect & Confirmation
┌────────────────────────────────────┐
│   ✅ Payment Successful!            │
│                                    │
│   Order #507f1f77bcf86cd79943...   │
│   Amount: PKR 550                  │
│   Transaction ID: JAZZ_123456      │
│                                    │
│   ✓ Payment received               │
│   ✓ Order confirmed                │
│   ✓ Shipment in progress           │
│                                    │
│   Estimated Delivery: 2-3 days     │
│                                    │
│   [View Order Details]             │
│   [Continue Shopping]              │
└────────────────────────────────────┘

User redirected to success page
```

---

## ❌ Payment Failure Scenarios

### 1. Insufficient Balance

```
Failure Code: INS_BALANCE

Cause:
  - Wallet has less than required amount
  - User's JazzCash balance is too low

Frontend Display:
┌─────────────────────────────────────┐
│   ❌ Payment Failed                  │
│                                     │
│   Insufficient Balance              │
│                                     │
│   Your JazzCash wallet has          │
│   insufficient balance to complete  │
│   this transaction.                 │
│                                     │
│   Current Balance: PKR 200          │
│   Required: PKR 550                 │
│   Shortfall: PKR 350                │
│                                     │
│   [Add Money to Wallet] [Retry]     │
│   [Try Another Method]              │
└─────────────────────────────────────┘

Backend Response:
{
  "success": false,
  "orderId": "507f1f77...",
  "failureReason": "INS_BALANCE",
  "failureMessage": "Insufficient balance in wallet",
  "actionRequired": "top-up",
  "suggestedAmount": 350
}
```

### 2. OTP/Verification Failed

```
Failure Code: OTP_FAILED, AUTH_FAILED

Cause:
  - User entered wrong OTP
  - OTP expired (5 minutes)
  - Too many failed attempts

Frontend Display:
┌─────────────────────────────────────┐
│   ❌ Verification Failed            │
│                                     │
│   Your OTP verification failed.     │
│                                     │
│   Possible reasons:                 │
│   • Wrong OTP entered               │
│   • OTP expired                     │
│   • Too many incorrect attempts     │
│                                     │
│   [Retry Payment]                   │
│   [Contact Support]                 │
└─────────────────────────────────────┘

Backend Action:
  - Cancel payment attempt
  - Allow retry after 5 minutes
  - Log failed attempts
  - Alert if >3 failures
```

### 3. Network Error / Timeout

```
Failure Code: NETWORK_ERROR, TIMEOUT

Cause:
  - Internet connection lost
  - Payment gateway timeout
  - Server downtime

Frontend Display:
┌─────────────────────────────────────┐
│   ⚠️  Connection Error              │
│                                     │
│   We lost connection to the         │
│   payment gateway.                  │
│                                     │
│   Your payment status is UNKNOWN.   │
│                                     │
│   What to do:                       │
│   1. Check your internet            │
│   2. Wait 2-3 seconds               │
│   3. [Check Payment Status]         │
│                                     │
│   If problem persists:              │
│   [Contact Support]                 │
└─────────────────────────────────────┘

Backend Action:
  - DO NOT assume payment failed
  - Query SafePay API for actual status
  - Retry webhook from SafePay
  - Wait 30 seconds before retry
```

### 4. User Cancels Payment

```
Failure Code: USER_CANCELLED

Cause:
  - User clicked Cancel button
  - User closed payment window
  - User went back intentionally

Frontend Display:
┌─────────────────────────────────────┐
│   ⏸️  Payment Cancelled              │
│                                     │
│   You cancelled this payment.       │
│                                     │
│   Your order has been saved and     │
│   is available in your cart.        │
│                                     │
│   Cart Total: PKR 550               │
│   Order ID: 507f1f77...             │
│                                     │
│   [Return to Cart]                  │
│   [Try Another Method]              │
│   [Continue Shopping]               │
└─────────────────────────────────────┘

Backend Action:
  - Release order lock
  - Mark order as "cancelled"
  - Restore stock
  - Allow reorder within 24 hours
```

### 5. Transaction Declined

```
Failure Code: TRANSACTION_DECLINED

Cause:
  - Wallet account flagged
  - Suspicious activity detected
  - Payment limit exceeded
  - Duplicate transaction

Frontend Display:
┌─────────────────────────────────────┐
│   ❌ Transaction Declined           │
│                                     │
│   Your payment was declined for     │
│   security reasons.                 │
│                                     │
│   Reason: Your JazzCash account     │
│   has flagged this transaction      │
│   as suspicious.                    │
│                                     │
│   Please contact JazzCash support:  │
│   1234-111-111                      │
│                                     │
│   [Try Another Method]              │
│   [Contact Support]                 │
└─────────────────────────────────────┘

Backend Action:
  - Contact customer via phone
  - Request verification from JazzCash
  - Allow retry after verification
  - Log security incident
```

### 6. Gateway/API Error

```
Failure Code: GATEWAY_ERROR, SERVICE_UNAVAILABLE

Cause:
  - SafePay API temporarily down
  - JazzCash gateway unavailable
  - Third-party service error

Frontend Display:
┌─────────────────────────────────────┐
│   🔧 Service Temporarily Down       │
│                                     │
│   Payment gateway is temporarily    │
│   unavailable. Please try again     │
│   in a few minutes.                 │
│                                     │
│   We'll hold your order for         │
│   30 minutes.                       │
│                                     │
│   Estimated recovery: 5 mins        │
│                                     │
│   [Retry Payment]                   │
│   [Use Another Method]              │
└─────────────────────────────────────┘

Backend Action:
  - Extend order lock to 1 hour
  - Alert admin/ops team
  - Retry webhooks automatically
  - Check gateway status API
```

### 7. Duplicate Transaction Detected

```
Failure Code: DUPLICATE_TRANSACTION

Cause:
  - User clicked "Pay" multiple times
  - Webhook received twice
  - Same requestId submitted twice

Frontend Display:
└─ Handled Transparently ─┘
(User doesn't see this - backend handles)

Backend Action:
  - Check idempotency key
  - Return 200 OK even if already processed
  - Don't create duplicate transaction log
  - Ensure order status is correct
```

---

## 📊 Payment Status Display

### Complete Status Matrix for Customer

```
┌─────────────────────────────────────────────────────────────┐
│                    CUSTOMER PAYMENT STATUS                  │
└─────────────────────────────────────────────────────────────┘

STATUS: PENDING
───────────────
Icon: ⏳ Clock
Color: Yellow/Amber
Display: "Awaiting Payment"

What it means:
  - Order created but payment not received yet
  - Payment link sent to customer
  - Customer has 30 minutes to complete
  - No items shipped

Customer Actions:
  - Complete payment via wallet app
  - Retry failed payment
  - Cancel and reorder

Example UI:
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ⏳ Payment Pending    │
│ Expires in: 28 minutes       │
│ Amount: PKR 550              │
│                              │
│ [Complete Payment] [Cancel]  │
└──────────────────────────────┘


STATUS: PROCESSING
──────────────────
Icon: 🔄 Spinner
Color: Blue
Display: "Processing Payment"

What it means:
  - Payment received but being verified
  - SafePay confirming with JazzCash
  - Should complete within 30 seconds
  - Items reserved but not shipped

Customer Actions:
  - Wait (no action needed)
  - Check email for confirmation
  - Contact support if >5 mins

Example UI:
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: 🔄 Processing...      │
│ Payment: verifying...        │
│ Amount: PKR 550              │
│                              │
│ This typically takes <1 min  │
│ Please wait...               │
└──────────────────────────────┘


STATUS: CONFIRMED / COMPLETED
──────────────────────────────
Icon: ✅ Checkmark
Color: Green
Display: "Payment Confirmed"

What it means:
  - Payment successfully received
  - Order confirmed
  - Items allocated from stock
  - Ready for shipment
  - Customer has receipt

Example UI:
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ✅ Payment Confirmed  │
│ Transaction ID: JAZZ_123456  │
│ Amount: PKR 550              │
│ Date: Jun 16, 2026 10:30 AM  │
│                              │
│ Shipment in progress         │
│ Estimated Delivery: 2-3 days │
│                              │
│ [View Receipt] [Track]       │
└──────────────────────────────┘


STATUS: FAILED
──────────────
Icon: ❌ X Mark
Color: Red
Display: "Payment Failed"

What it means:
  - Payment was declined
  - Transaction not completed
  - Order not confirmed
  - Stock released back
  - Customer can retry

Failure Reasons Display:
  - "Insufficient Balance"
  - "OTP Verification Failed"
  - "Transaction Declined"
  - "Wallet Account Locked"

Example UI:
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ❌ Payment Failed     │
│ Reason: Insufficient Balance │
│ Amount: PKR 550              │
│                              │
│ Your wallet balance is too   │
│ low for this transaction.    │
│                              │
│ [Top Up & Retry]             │
│ [Try Another Method]         │
│ [Contact Support]            │
└──────────────────────────────┘


STATUS: CANCELLED
─────────────────
Icon: ⊘ Cancel symbol
Color: Gray
Display: "Cancelled"

What it means:
  - Customer or admin cancelled
  - No payment attempt made
  - Order not fulfilled
  - Stock released back
  - Items still in cart

Cancellation Reasons:
  - "User Cancelled"
  - "Expired (30 minutes)"
  - "Admin Cancelled"
  - "Out of Stock"

Example UI:
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ⊘ Cancelled          │
│ Reason: User Cancelled       │
│ Amount: PKR 550              │
│                              │
│ Your order has been cancelled│
│ Items are back in your cart  │
│                              │
│ [View Cart] [Shop Again]     │
└──────────────────────────────┘


STATUS: REFUNDING / REFUNDED
─────────────────────────────
Icon: ↩️ Return arrow
Color: Orange/Green
Display: "Refund in Progress" / "Refunded"

What it means:
  - Payment received but refunded
  - Customer requested cancellation after payment
  - Order cancelled due to stock issue
  - Money being returned to wallet

Example UI (Refunding):
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ↩️ Refunding...       │
│ Refund Amount: PKR 550       │
│ Expected Receipt: 2-3 days   │
│                              │
│ Your refund is being         │
│ processed. Money will appear │
│ in your wallet soon.         │
│                              │
│ [Refund Details]             │
│ [Transaction ID: JAZZ_...]   │
└──────────────────────────────┘

Example UI (Refunded):
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ✅ Refunded          │
│ Refund Amount: PKR 550       │
│ Date: Jun 17, 2026 2:30 PM   │
│                              │
│ Your refund has been         │
│ successfully processed.      │
│                              │
│ Reference: REF_123456        │
│ [Download Receipt]           │
└──────────────────────────────┘


STATUS: EXPIRED
───────────────
Icon: ⏰ Expired
Color: Gray
Display: "Payment Expired"

What it means:
  - Customer didn't pay within 30 minutes
  - Order auto-cancelled
  - Stock released
  - Can create new order

Example UI:
┌──────────────────────────────┐
│ Order: #507f1f77...          │
│ Status: ⏰ Expired            │
│ Reason: Payment Not Completed│
│ Expires At: Jun 16, 10:58 AM │
│                              │
│ This order has expired.      │
│ Items are available again.   │
│                              │
│ [Create New Order]           │
│ [View Similar Items]         │
└──────────────────────────────┘
```

### Payment Status Flow Diagram

```
                    ┌─→ Cancelled
                    │   (User clicks cancel)
                    │
    Pending ────────┼─→ Processing ────→ Confirmed ─→ Fulfilling
    (Waiting)       │   (Verifying)      (Payment     (Shipping)
                    │                     Received)
                    ├─→ Failed
                    │   (Declined)
                    │
                    └─→ Expired
                        (Timeout)
```

---

## 🚫 Abandoned Payment Handling

### Definition
A payment is "abandoned" when:
- Order created but payment not completed
- 30+ minutes have passed since order creation
- Customer closes browser without completing
- Customer left payment page

### Automatic Recovery Workflow

```
TIMELINE OF ABANDONED ORDER
════════════════════════════

T=0 min     Order Created
            - paymentStatus: "pending"
            - Lock expires: T+30min
            - Stock reserved
            - Send payment link via SMS/email

T=10 min    Customer still on payment page
            - No action

T=20 min    Customer leaves payment page
            - Webhook never received
            - Order still pending

T=30 min    EXPIRATION TRIGGERED
            ├─→ Order status: "cancelled"
            ├─→ paymentStatus: "expired"
            ├─→ Release stock lock
            ├─→ Send abandonment email
            └─→ Offer recovery incentive

T=30-60 min Abandoned Cart Recovery
            ├─→ Email: "Complete your order"
            ├─→ SMS: "Your order is expiring"
            ├─→ In-app: Persistent notification
            └─→ Offer: 5% discount to retry

T=60-120 min Remind Customer
            ├─→ "Your cart is still waiting"
            └─→ Continue with 5% discount

T>120 min   Stop Recovery
            └─→ Release order from system
```

### Abandoned Cart Email Template

```
Subject: Complete Your Order & Get 5% Off! 🛒

Hi {CustomerName},

Your order was created but payment wasn't completed.

Order Details:
────────────────
Order ID: #507f1f77...
Amount: PKR 550
Items: Watch (1x), Perfume (1x)
Created: Jun 16, 2026 10:30 AM
Expires: Jun 16, 2026 10:58 AM

⏰ Hurry! Your order expires in {timeRemaining}

Why we're reminding you:
- Your items are reserved for you
- We'll release them after 30 minutes
- You're getting 5% off if you complete now!

🎁 Complete Payment & Save 5%
→ [Complete Payment] (includes discount)

Questions?
[Contact Support] | [View Order]

Best regards,
Prestige Collection Team
```

### Recovery Incentive Strategy

```
Abandoned Order Retention by Discount Level

No Incentive:     ~15% recover rate
5% Discount:      ~25% recover rate
10% Discount:     ~35% recover rate
Free Shipping:    ~28% recover rate
Combo Offer:      ~40% recover rate (5% + Free Ship)

RECOMMENDED:
First Reminder:   5% discount
Second Reminder:  Free shipping
Third Reminder:   5% + Free shipping + Free gift
```

### Backend Implementation

```typescript
// Scheduled Job: Check abandoned orders every 5 minutes
@Cron('*/5 * * * *')
async handleAbandonedOrders() {
  const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
  
  const abandonedOrders = await Order.find({
    createdAt: { $lte: thirtyMinutesAgo },
    paymentStatus: 'pending',
    status: 'pending',
    reminderCount: { $lt: 3 } // Don't over-remind
  });

  for (const order of abandonedOrders) {
    // Mark as expired
    order.status = 'cancelled';
    order.paymentStatus = 'expired';
    order.expiresAt = new Date();
    await order.save();

    // Release stock
    for (const item of order.items) {
      await releaseStock(item.productId, item.quantity);
    }

    // Send reminder email with recovery link
    await sendAbandonedCartEmail(order._id, {
      discount: 5,
      expiresAt: order.expiresAt
    });

    // Log recovery attempt
    await RecoveryLog.create({
      orderId: order._id,
      type: 'abandoned_cart_reminder',
      timestamp: new Date()
    });
  }
}

// Customer clicks recovery link
async retryAbandonedOrder(orderId: string) {
  const order = await Order.findById(orderId);
  
  // Check if items still available
  for (const item of order.items) {
    const stock = await Product.findById(item.productId);
    if (stock.available < item.quantity) {
      throw new Error('Item out of stock');
    }
  }

  // Apply recovery discount
  order.discount = { type: 'recovery', amount: 5 };
  order.grandTotal = order.grandTotal * 0.95;
  order.status = 'pending';
  order.paymentStatus = 'pending';
  order.expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 min extension
  await order.save();

  // Create new payment session
  return initiatePayment(order);
}
```

---

## 🏆 Industry Standards Workflow

### Comparison: Leading E-commerce Platforms

```
┌────────────────────────────────────────────────────────────┐
│         PAYMENT WORKFLOW STANDARDS - INDUSTRY LEADERS       │
└────────────────────────────────────────────────────────────┘

AMAZON
────────
Flow:
  1. Order Created (PENDING)
  2. Redirect to payment gateway
  3. Payment authorized (AUTHORIZED)
  4. Payment captured within 24 hours (CAPTURED)
  5. Items prepared (PROCESSING)
  6. Items shipped (SHIPPED)

Failure Handling:
  - Multiple retry attempts
  - Automatic notification on failure
  - Payment method suggestions
  - 1-click retry option

Webhook Pattern:
  - Dual verification (webhook + API query)
  - 3x retry on webhook failure
  - Idempotency key checking
  - Timeout: 30 seconds


SHOPIFY
───────
Flow:
  1. Order Created (PENDING)
  2. Payment Processing (PENDING)
  3. Payment Captured or Voided (SUCCESS/FAILED)
  4. Fulfillment (PICKING)
  5. Shipment (SHIPPED)

Failure Handling:
  - Automatic retry with exponential backoff
  - Multiple payment method options
  - Save payment method for retry
  - SMS + Email notifications

Webhook Pattern:
  - Signature verification mandatory
  - Idempotency by webhook ID
  - Retry for 5 days if delivery fails
  - Webhook timeout: 5 seconds


STRIPE
──────
Flow:
  1. Payment Intent Created (REQUIRES_ACTION)
  2. Payment Processing (PROCESSING)
  3. Payment Confirmed (SUCCEEDED/FAILED)
  4. Charge Captured (CAPTURED)
  5. Payout Issued (AVAILABLE)

Failure Handling:
  - Automatic retry logic
  - Network error recovery
  - SCA/3D Secure handling
  - Retry webhook events

Webhook Pattern:
  - Signature verification (SHA256)
  - Event versioning
  - Guaranteed at-least-once delivery
  - 5 second timeout, 5 day retry window


DARAZ (SOUTH ASIA)
──────────────────
Flow:
  1. Order Created (PENDING)
  2. Payment Initiated (PENDING)
  3. Payment Confirmed or Cancelled (PAID/UNPAID)
  4. Order Confirmed (CONFIRMED)
  5. Shipment (SHIPPED)

Failure Handling:
  - 24-hour window to retry
  - Cash on delivery option fallback
  - Instant refund on payment cancel
  - SMS confirmation on all status changes

Webhook Pattern:
  - Signature verification
  - Status polling as fallback
  - 5-minute retry interval
  - Timeout: 10 seconds
```

### Prestige Collection: Recommended Implementation (BEST PRACTICES)

```
YOUR STANDARD WORKFLOW
══════════════════════

STATES (8 states total):
  1. ORDER_PENDING      → Order created, awaiting payment
  2. PAYMENT_PENDING    → Customer in payment gateway
  3. PAYMENT_PROCESSING → Payment being verified
  4. PAYMENT_CONFIRMED  → Payment received, verified
  5. PAYMENT_FAILED     → Payment declined
  6. ORDER_CANCELLED    → Order cancelled by customer or system
  7. REFUNDING          → Refund in progress
  8. REFUNDED           → Refund completed

TRANSITIONS:
  ORDER_PENDING
    ├─→ PAYMENT_PENDING (customer initiates)
    │   ├─→ PAYMENT_PROCESSING (webhook received)
    │   │   ├─→ PAYMENT_CONFIRMED (webhook verified) ✅
    │   │   └─→ PAYMENT_FAILED (webhook failed) ❌
    │   ├─→ PAYMENT_FAILED (user cancels)
    │   └─→ ORDER_CANCELLED (30-minute timeout)
    └─→ ORDER_CANCELLED (admin cancels)

REFUND FLOW:
  PAYMENT_CONFIRMED
    ├─→ REFUNDING (refund initiated)
    │   └─→ REFUNDED (refund completed)
    └─→ REFUNDING (on order cancellation)
```

---

## 🛠️ Admin Panel Requirements

### Dashboard Overview

```
ADMIN DASHBOARD: PAYMENT MONITORING
═══════════════════════════════════

┌────────────────────────────────────────────────────────┐
│  Prestige Collection Admin • Payment Management              │
└────────────────────────────────────────────────────────┘

📊 QUICK STATS
┌───────────────┬───────────────┬───────────────┐
│ Total Revenue │ Pending Pmnts  │ Failed Pmnts  │
│  PKR 1.2M     │      23        │       5       │
├───────────────┼───────────────┼───────────────┤
│ Success Rate  │  Avg Time      │  This Month   │
│   98.5%       │   12 seconds   │  PKR 50.3K    │
└───────────────┴───────────────┴───────────────┘

⏳ PAYMENT STATUS BREAKDOWN
┌───────────────────────────────────┐
│ Status          │ Count │ Revenue │
├─────────────────┼───────┼─────────┤
│ ✅ Confirmed    │  847  │ PKR 2.1M│
│ ⏳ Pending      │   23  │ PKR 450K│
│ 🔄 Processing   │    8  │ PKR 180K│
│ ❌ Failed       │    5  │ PKR 90K │
│ ⊘  Cancelled    │   12  │ PKR 220K│
│ ↩️  Refunding    │    2  │ PKR 30K │
└───────────────────────────────────┘

📈 PAYMENT METHOD BREAKDOWN
┌──────────────────────────────────────┐
│ Method         │ Count  │ % Success │
├────────────────┼────────┼───────────┤
│ SafePay Card   │  500   │   99.2%   │
│ JazzCash       │  200   │   97.5%   │
│ easyPaisa      │  180   │   96.8%   │
│ Cash on Deliv. │  250   │  100%     │
└──────────────────────────────────────┘

🔍 RECENT TRANSACTIONS
┌─────────────┬──────────┬─────────┬─────────────┐
│ Order ID    │ Amount   │ Method  │ Status      │
├─────────────┼──────────┼─────────┼─────────────┤
│ #507f1f77   │ PKR 550  │ JazzCash│ ✅ Confirmed│
│ #507f1f78   │ PKR 1200 │ Card    │ ⏳ Pending  │
│ #507f1f79   │ PKR 800  │ easyPai │ 🔄 Proc... │
│ #507f1f7a   │ PKR 450  │ JazzCash│ ❌ Failed   │
│ #507f1f7b   │ PKR 350  │ COD     │ ✅ Confirmed│
└─────────────┴──────────┴─────────┴─────────────┘
```

### Detailed Order View

```
ADMIN VIEW: SINGLE ORDER PAYMENT DETAILS
════════════════════════════════════════

Order #507f1f77bcf86cd799439011
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 BASIC INFO
  Customer: Ahmad Khan
  Email: ahmad@example.com
  Phone: +923009999999
  Created: Jun 16, 2026 10:30 AM
  Status: Processing

💳 PAYMENT INFO
  Method: JazzCash
  Amount: PKR 550
  Status: ✅ Confirmed
  Transaction ID: JAZZ_20260616_00123456
  SafePay Request ID: SPR_20260616_00123456
  
  Payment Timeline:
    10:30 AM - Order Created
    10:31 AM - Payment Initiated
    10:32 AM - Redirected to SafePay
    10:33 AM - Payment Completed on JazzCash
    10:33:45 AM - Webhook Received
    10:33:46 AM - Payment Verified
    10:34 AM - Order Confirmed

🔐 VERIFICATION
  Signature: ✅ Valid
  Idempotency: ✅ Checked
  SafePay Confirmation: ✅ Verified
  Amount Match: ✅ PKR 550 = PKR 550

📦 ORDER ITEMS
  1. Watch ($150)       x1      PKR 150
  2. Perfume ($50)      x1      PKR 50
  
  Subtotal:                      PKR 200
  Shipping:                      PKR 50
  Discount:                      -
  Tax:                           -
  TOTAL:                         PKR 250

⚙️ ADMIN ACTIONS
  [View Wallet Receipt]
  [Request Refund]
  [Verify Payment Manually]
  [Send Confirmation Email]
  [Send SMS]
  [Cancel Order]
  [Contact Customer]

🔄 TRANSACTION LOGS
  ┌─────────────────────────────────────┐
  │ 10:34 AM - Payment confirmed        │
  │ 10:34 AM - Order status: processing │
  │ 10:35 AM - Confirmation email sent  │
  │ 10:36 AM - Shipment request created │
  └─────────────────────────────────────┘
```

### Pending Payments Management

```
ADMIN VIEW: PENDING PAYMENTS
════════════════════════════

Show Pending Payments since: ▼ Last 24 hours

Filter by:
  Status: ○ All ● Pending ○ Failed ○ Processing
  Method: ☑ JazzCash ☑ easyPaisa ☑ Card ☑ COD
  Amount: From [blank] To [blank]

┌─────────────┬──────────┬─────────┬────────┬─────────┐
│ Order ID    │ Customer │ Amount  │ Method │ Time    │
├─────────────┼──────────┼─────────┼────────┼─────────┤
│ #507f1f78   │ Ali Khan │ PKR 1200│ Card   │ 32 mins │
│ #507f1f7c   │ Sara M.  │ PKR 450 │ Jazz   │ 18 mins │
│ #507f1f7d   │ Khan A.  │ PKR 800 │ Easy   │ 5 mins  │
└─────────────┴──────────┴─────────┴────────┴─────────┘

ACTION: Verify Manually
┌──────────────────────────────────────┐
│ Select Order: #507f1f78              │
│                                      │
│ Enter SafePay Request ID:            │
│ [SPR_20260616_00123456____]          │
│                                      │
│ Verification Method:                 │
│ ○ Query SafePay API                  │
│ ○ Check Webhook Logs                 │
│ ● Call Customer to Confirm           │
│                                      │
│ Notes:                               │
│ [________________________]            │
│                                      │
│ [Verify & Confirm] [Cancel]          │
└──────────────────────────────────────┘
```

### Failed Payments Management

```
ADMIN VIEW: FAILED PAYMENTS
═══════════════════════════

Showing 15 failed payments in last 7 days

┌─────────────┬──────────┬──────────┬─────────────────┐
│ Order ID    │ Customer │ Amount   │ Failure Reason  │
├─────────────┼──────────┼──────────┼─────────────────┤
│ #507f1f7a   │ Zain M.  │ PKR 450  │ Insuf. Balance  │
│ #507f1f7e   │ Ayesha   │ PKR 600  │ OTP Failed      │
│ #507f1f7f   │ Hassan   │ PKR 350  │ User Cancelled  │
│ #507f1f80   │ Fatima   │ PKR 1200 │ Trans. Declined │
└─────────────┴──────────┴──────────┴─────────────────┘

Failure Rate by Method (Last 7 Days):
  SafePay Card:  1.2%  (2 failures out of 167)
  JazzCash:      4.8%  (4 failures out of 83)
  easyPaisa:     5.2%  (3 failures out of 58)

ACTION: Contact Customer
┌──────────────────────────────────────┐
│ Order: #507f1f7a                     │
│ Reason: Insufficient Balance         │
│                                      │
│ Customer: Zain M.                    │
│ Phone: +923001234567                 │
│ Email: zain@example.com              │
│                                      │
│ Message Template:                    │
│ [Standard Apology & Retry]           │
│ [Insufficient Balance Recovery]      │
│ [Special Discount Offer]             │
│                                      │
│ Send via: ☑ SMS ☑ Email              │
│                                      │
│ [Send] [Use Custom Message]          │
└──────────────────────────────────────┘
```

---

## ✅ Payment Verification

### How Admin Verifies Payment

#### Method 1: Query SafePay API Directly

```typescript
// Backend Endpoint
GET /api/admin/verify-payment/:orderId

// Frontend button click
async function verifyPaymentStatus(orderId: string) {
  try {
    const response = await fetch(
      `/api/admin/verify-payment/${orderId}`,
      {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const result = await response.json();
    
    // Display results
    showVerificationResults({
      safepayStatus: result.safepayStatus,
      jazzCashStatus: result.jazzCashStatus,
      transactionId: result.transactionId,
      amount: result.amount,
      timestamp: result.timestamp,
      matched: result.matched // true if matches order
    });
  } catch (error) {
    showError('Failed to verify payment');
  }
}

// Backend Implementation
@Get('admin/verify-payment/:orderId')
@UseGuards(JwtAuthGuard, AdminGuard)
async verifyPaymentStatus(
  @Param('orderId') orderId: string,
) {
  const order = await Order.findById(orderId);
  
  // Query SafePay API with requestId
  const safepayResult = await this.safepayService.queryPaymentStatus(
    order.paymentRequestId
  );

  // Query JazzCash API if wallet payment
  const jazzCashResult = order.paymentMethod === 'JazzCash'
    ? await this.jazzCashService.queryTransaction(
        order.paymentTransactionId
      )
    : null;

  return {
    safepayStatus: safepayResult.status,
    jazzCashStatus: jazzCashResult?.status,
    transactionId: safepayResult.transactionId,
    amount: safepayResult.amount,
    timestamp: safepayResult.timestamp,
    matched: safepayResult.amount === order.grandTotal,
    details: {
      created: order.createdAt,
      paymentReceived: safepayResult.completedAt,
      webhookReceived: order.webhookReceivedAt,
      databaseUpdated: order.paymentConfirmedAt
    }
  };
}
```

#### Method 2: Check Webhook Logs

```
ADMIN VIEW: WEBHOOK VERIFICATION
════════════════════════════════

Order #507f1f77
Request ID: SPR_20260616_00123456

WEBHOOK LOGS
───────────

[✅] Webhook Received
  Timestamp: 10:33:45 AM
  Source IP: 203.192.xxx.xxx (SafePay)
  Signature: ✅ Valid
  Idempotency Key: IDK_123456
  
  Body:
  {
    "requestId": "SPR_20260616_00123456",
    "orderRefNum": "507f1f77...",
    "transactionId": "JAZZ_123456",
    "status": "captured",
    "amount": 55000,
    "timestamp": 1687255425
  }

[✅] Signature Verified
  Algorithm: HMAC-SHA256
  Expected: a1b2c3d4e5f6g7h8...
  Received: a1b2c3d4e5f6g7h8...
  Match: ✅

[✅] Amount Verified
  Order Total: PKR 550 (55000 paisa)
  Webhook Amount: PKR 550 (55000 paisa)
  Match: ✅

[✅] Database Updated
  Order.paymentStatus: "pending" → "captured"
  Order.transactionId: null → "JAZZ_123456"
  Order.status: "pending" → "processing"
  Updated At: 10:33:46 AM

[✅] Idempotency Check
  Previous Receipt ID: null
  Current Receipt ID: IDK_123456
  Status: First processing (not duplicate)

CONCLUSION: ✅ VERIFIED - Payment is legitimate
```

#### Method 3: Call Customer to Verify

```
ADMIN WORKFLOW: VERBAL VERIFICATION
═══════════════════════════════════

When to Use:
  - Payment status unclear
  - Large order amount (>10k PKR)
  - Multiple failed attempts
  - Suspicious activity detected
  - Customer disputes charge

Call Script:
───────────

"Hi {CustomerName}, this is from Prestige Collection.
I'm calling to verify your order #507f1f77 
for PKR 550 placed today at 10:30 AM.

Can you confirm:
1. Did you initiate this payment? 
   [Customer: Yes/No]

2. Did your JazzCash wallet deduct PKR 550?
   [Customer: Yes/No]

3. Did you receive a payment confirmation from JazzCash?
   [Customer: Yes/No]

If all yes:
'Great! We've received your payment and order 
is being prepared for shipment. You'll receive 
tracking number within 2 hours via SMS.'

If any no:
'I understand. It seems there might be an issue 
with the payment. Let me check with our team and 
call you back within 1 hour. In the meantime, 
you can retry the payment. Would you like a 
5% discount code to retry?'"

After Call:
──────────
□ Call recorded (for compliance)
□ Notes added to order
□ Verification status updated
□ Follow-up action taken
□ Customer contacted if action needed
```

---

## 🗄️ Database Structure

### Complete Schema Design (Production)

```typescript
// Order Schema - MAIN ORDER DOCUMENT
@Schema({ timestamps: true })
export class Order {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true, unique: true })
  orderNumber: string; // Human readable: ORD-20260616-00123

  @Prop({
    type: [{
      productId: Types.ObjectId,
      name: String,
      price: Number,
      quantity: Number,
      image: String,
    }],
    required: true,
  })
  items: OrderItem[];

  @Prop({ required: true })
  totalPrice: number; // Sum of items

  @Prop({ required: true, default: 0 })
  shippingCost: number;

  @Prop({ required: true })
  grandTotal: number; // totalPrice + shippingCost + tax

  // PAYMENT INFO
  @Prop({
    required: true,
    enum: ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned'],
    default: 'pending',
  })
  status: OrderStatus;

  @Prop({
    required: true,
    enum: ['pending', 'processing', 'confirmed', 'failed', 'cancelled', 'expired', 'refunding', 'refunded'],
    default: 'pending',
  })
  paymentStatus: PaymentStatus;

  @Prop({
    required: true,
    enum: ['SafePay', 'JazzCash', 'easyPaisa', 'CashOnDelivery'],
  })
  paymentMethod: string;

  // SAFEPAY SPECIFIC
  @Prop()
  safepayRequestId?: string; // SPR_20260616_00123456

  @Prop()
  safepayTransactionId?: string; // From SafePay

  // WALLET PAYMENT SPECIFIC
  @Prop()
  walletPhone?: string; // For JazzCash/easyPaisa

  @Prop()
  walletTransactionId?: string; // From JazzCash/easyPaisa

  // PAYMENT PROCESSING
  @Prop()
  paymentInitiatedAt?: Date;

  @Prop()
  paymentCompletedAt?: Date; // When SafePay webhook received

  @Prop()
  webhookReceivedAt?: Date; // Exact webhook timestamp

  @Prop()
  webhookProcessedAt?: Date; // When we processed it

  @Prop()
  paymentConfirmedAt?: Date; // When we verified with API

  // PAYMENT VERIFICATION
  @Prop({ default: false })
  webhookSignatureVerified: boolean;

  @Prop()
  webhookSignature?: string; // SafePay's X-Signature header

  @Prop()
  idempotencyKey?: string; // For preventing duplicates

  @Prop({ default: false })
  paymentAmountVerified: boolean; // Amount matches SafePay

  @Prop({ default: false })
  safepayAPIVerified: boolean; // Confirmed with SafePay API

  // SHIPPING ADDRESS
  @Prop({
    type: {
      fullName: String,
      email: String,
      phoneNumber: String,
      street: String,
      city: String,
      zipCode: String,
    },
    required: true,
  })
  shippingAddress: ShippingAddress;

  // SHIPPING
  @Prop()
  trackingNumber?: string; // Courier tracking number

  @Prop()
  shipmentStatus?: 'pending' | 'picked' | 'packed' | 'shipped' | 'delivered' | 'failed';

  @Prop()
  estimatedDeliveryDate?: Date;

  @Prop()
  actualDeliveryDate?: Date;

  // REFUNDS
  @Prop()
  refundStatus?: 'none' | 'pending' | 'processing' | 'completed' | 'failed';

  @Prop()
  refundAmount?: number;

  @Prop()
  refundInitiatedAt?: Date;

  @Prop()
  refundCompletedAt?: Date;

  @Prop()
  refundReason?: string; // Why was refund initiated

  // SECURITY & AUDIT
  @Prop()
  ipAddress?: string; // Customer's IP at checkout

  @Prop()
  userAgent?: string; // Customer's browser info

  @Prop()
  failureReason?: string; // Why payment failed (e.g., 'INS_BALANCE')

  @Prop()
  notes?: string; // Admin notes

  @Prop({ default: 0 })
  retryCount: number; // Payment retry attempts

  @Prop()
  lastRetryAt?: Date;

  @Prop()
  expiresAt?: Date; // Payment window expires

  // TIMESTAMPS (automatic)
  @Prop()
  createdAt: Date;

  @Prop()
  updatedAt: Date;
}

export const OrderSchema = SchemaFactory.createForClass(Order);

// INDEXES for better query performance
OrderSchema.index({ userId: 1, createdAt: -1 }); // User's orders
OrderSchema.index({ status: 1, paymentStatus: 1 }); // Dashboard queries
OrderSchema.index({ safepayRequestId: 1 }, { sparse: true }); // Webhook lookup
OrderSchema.index({ paymentStatus: 1, expiresAt: 1 }); // Expired orders cleanup
OrderSchema.index({ idempotencyKey: 1 }, { sparse: true }); // Duplicate detection
```

### Payment Transaction Log Schema

```typescript
// PaymentLog Schema - AUDIT TRAIL
@Schema({ timestamps: true })
export class PaymentLog {
  @Prop({ type: Types.ObjectId, ref: 'Order', required: true })
  orderId: Types.ObjectId;

  @Prop({
    required: true,
    enum: [
      'ORDER_CREATED',
      'PAYMENT_INITIATED',
      'WEBHOOK_RECEIVED',
      'SIGNATURE_VERIFIED',
      'AMOUNT_VERIFIED',
      'SAFEPAY_CONFIRMED',
      'ORDER_CONFIRMED',
      'PAYMENT_FAILED',
      'DUPLICATE_DETECTED',
      'REFUND_INITIATED',
      'REFUND_COMPLETED'
    ]
  })
  eventType: string;

  @Prop({ required: true })
  description: string; // Human readable description

  @Prop()
  amount?: number; // Transaction amount

  @Prop()
  safepayRequestId?: string;

  @Prop()
  transactionId?: string;

  @Prop()
  status?: string; // 'pending', 'captured', 'failed', etc.

  @Prop()
  failureReason?: string; // Why it failed (if applicable)

  @Prop()
  webhookPayload?: object; // Raw webhook JSON (for audit)

  @Prop()
  apiResponse?: object; // API response JSON (for audit)

  @Prop()
  metadata?: object; // Any additional info

  @Prop()
  createdAt: Date;
}

export const PaymentLogSchema = SchemaFactory.createForClass(PaymentLog);
```

### Webhook Receipt Schema

```typescript
// WebhookReceipt Schema - DUPLICATE DETECTION
@Schema({ timestamps: true })
export class WebhookReceipt {
  @Prop({ required: true, unique: true })
  idempotencyKey: string; // From webhook payload or generated

  @Prop({ required: true })
  safepayRequestId: string; // Which payment this is for

  @Prop({ required: true, enum: ['pending', 'processed', 'failed'] })
  status: string;

  @Prop({ required: true })
  rawPayload: object; // Store raw webhook body

  @Prop()
  signature: string; // X-Signature header

  @Prop()
  sourceIP: string; // Where webhook came from

  @Prop()
  processedAt?: Date; // When we processed it

  @Prop()
  errorMessage?: string; // If processing failed

  @Prop()
  retryCount: number; // How many times we retried

  @Prop()
  createdAt: Date;

  @Prop()
  expiresAt: Date; // TTL: 90 days for audit
}

export const WebhookReceiptSchema = SchemaFactory.createForClass(WebhookReceipt);

// TTL Index: Auto-delete after 90 days
WebhookReceiptSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```

### Database Relationships

```
User
  │
  └─→ orders[] (One-to-Many)
        │
        ├─→ items[] (array of OrderItem)
        │
        ├─→ paymentLogs[] (One-to-Many via orderId)
        │
        └─→ webhookReceipts[] (One-to-Many via safepayRequestId)

Order Document contains:
  - userId (link to User)
  - safepayRequestId (link to WebhookReceipt)
  - items (embedded array)
  - shippingAddress (embedded object)
  - all payment metadata

PaymentLog References:
  - orderId (link to Order)
  - Tracks every event for this order

WebhookReceipt References:
  - safepayRequestId (used to match orders)
  - Stores raw webhook for audit/replay
```

---

## 🔄 Order Lifecycle

### Complete State Machine Diagram

```
┌──────────────────────────────────────────────────────────┐
│           COMPLETE ORDER STATE MACHINE                    │
└──────────────────────────────────────────────────────────┘

                         START
                          │
                          ▼
                    [Create Order]
                   status: pending
              paymentStatus: pending
                          │
                          ▼
              ┌─────────────────────────┐
              │  USER ON CHECKOUT PAGE  │
              │                         │
              │  [Cancel] ──────┐       │ [Complete Payment]
              │                 │       │
              │          [Timeout ~30min]
              │                 │       │
              └──────────────────┼───────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
            [Payment Failed]         [Payment Confirmed]
       paymentStatus: failed        paymentStatus: processing
                    │                         │
                    │                         ▼
                    │              [Verify & Confirm]
                    │                         │
                    │                         ├─→ Signature ✓
                    │                         ├─→ Amount ✓
                    │                         ├─→ SafePay API ✓
                    │                         │
                    │                         ▼
                    │              paymentStatus: confirmed
                    │              status: processing
                    │                         │
              ┌─────┴───────────────────────┐ │
              │                             │ │
        [Retry Payment]       [Order Processing]
        paymentStatus: pending              │
              │                             │
    [Attempt Again]         ┌───────────────┴────────────┐
              │             │                            │
              └─→ Payment   ▼                            ▼
                 Loop    [Pick Items]        [Out of Stock]
                        [Pack Items]              │
                             │                    ▼
                             ▼           [Initiate Refund]
                        [Shipment]      refundStatus: pending
                             │                    │
                             ▼                    ▼
                      status: shipped     [Process Refund]
                             │                    │
                             ▼                    ▼
                   [In Transit to Customer]  [Refund Completed]
                             │          paymentStatus: refunded
                             │                    │
                             ▼                    ▼
                      [Delivery Attempt]        [END]
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
          [Delivered] [Delivery Failed]  [Return Initiated]
          status:         │                   │
          delivered   [Retry Delivery]        ▼
              │           │          [Return Processing]
              │           │                   │
              └───────────┴───────────────────┴──→ [END]

[Cancelled] Path (from any state):
              │
              ├─→ paymentStatus: pending → Release order
              ├─→ paymentStatus: processing → Void payment
              ├─→ paymentStatus: confirmed → Issue refund
              │
              └─→ status: cancelled → END

[Timeout] Path (if no payment for 30 mins):
              │
              ├─→ status: cancelled
              ├─→ paymentStatus: expired
              ├─→ Release stock
              ├─→ Send recovery email
              │
              └─→ Allow retry within 24 hours
```

### Detailed Status Transitions

```
PAYMENT FLOW DETAILS
════════════════════

┌─────────────────────────────────────────────────────┐
│ STATE 1: ORDER_PENDING                              │
├─────────────────────────────────────────────────────┤
│ Timeline: T=0 to T=30min                            │
│ What happens:                                       │
│  - Order created in database                        │
│  - Stock reserved (soft lock)                       │
│  - Payment link generated                           │
│  - SMS/Email sent to customer with link             │
│                                                     │
│ Customer sees:                                      │
│  - "Please complete payment within 30 minutes"      │
│  - Payment link on checkout page                    │
│  - SMS reminder                                     │
│                                                     │
│ Transitions to:                                     │
│  → PAYMENT_PENDING (if customer clicks pay)         │
│  → CANCELLED (if timeout or cancellation)           │
│                                                     │
│ Database state:                                     │
│  status = "pending"                                 │
│  paymentStatus = "pending"                          │
│  expiresAt = T+30min                                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 2: PAYMENT_PENDING                            │
├─────────────────────────────────────────────────────┤
│ Timeline: Customer in payment gateway               │
│ What happens:                                       │
│  - Customer redirected to SafePay                   │
│  - SafePay communicates with JazzCash/easyPaisa    │
│  - Customer enters credentials                      │
│  - OTP sent to wallet                               │
│  - Customer verifies OTP                            │
│                                                     │
│ Customer sees:                                      │
│  - SafePay secure payment page                      │
│  - Transaction details                             │
│  - OTP verification screen                         │
│                                                     │
│ Timeout: 10 minutes                                 │
│ (If no response, webhook will be 'failed')          │
│                                                     │
│ Transitions to:                                     │
│  → PAYMENT_PROCESSING (if payment submitted)        │
│  → PAYMENT_FAILED (if user cancels/OTP fails)      │
│                                                     │
│ Database state:                                     │
│  status = "pending"                                 │
│  paymentStatus = "pending"                          │
│  paymentInitiatedAt = now                          │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 3: PAYMENT_PROCESSING                         │
├─────────────────────────────────────────────────────┤
│ Timeline: T=payment_submitted to T+30sec            │
│ What happens:                                       │
│  - SafePay processes payment with wallet provider   │
│  - Wallet deducts money                             │
│  - Transaction status determined                    │
│  - SafePay prepares webhook                         │
│  - Webhook sent to your backend                     │
│                                                     │
│ Customer sees:                                      │
│  - "Processing..." spinner                          │
│  - "Please wait, don't close this window"          │
│  - Estimated time: <30 seconds                      │
│                                                     │
│ Timeout: 30 seconds                                 │
│ (If no webhook, backend queries SafePay API)        │
│                                                     │
│ Backend during this state:                          │
│  - Listening for webhook                           │
│  - Has contingency query ready                      │
│  - Logging all events                              │
│                                                     │
│ Transitions to:                                     │
│  → PAYMENT_CONFIRMED (if webhook: success)          │
│  → PAYMENT_FAILED (if webhook: failed)             │
│                                                     │
│ Database state:                                     │
│  status = "pending"                                 │
│  paymentStatus = "processing"                       │
│  webhookReceivedAt = when webhook arrives          │
│  safepayTransactionId = from webhook                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 4: PAYMENT_CONFIRMED                          │
├─────────────────────────────────────────────────────┤
│ Timeline: Webhook verified + API confirmed          │
│ What happens:                                       │
│  - Webhook signature verified                       │
│  - Amount matches order total                       │
│  - SafePay API confirms status                      │
│  - Stock moved from "reserved" to "sold"            │
│  - Shipment process initiated                       │
│  - Confirmation email sent                          │
│  - SMS sent to customer                             │
│  - Order released to warehouse                      │
│                                                     │
│ Customer sees:                                      │
│  - ✅ "Payment Successful"                          │
│  - Order confirmation                              │
│  - Tracking link (once shipped)                     │
│  - "Thank you for your purchase"                    │
│                                                     │
│ Admin sees:                                         │
│  - New order ready to fulfill                       │
│  - Notification in dashboard                        │
│  - All verification checks: ✓ PASSED               │
│                                                     │
│ Transitions to:                                     │
│  → ORDER_PROCESSING (warehouse picks items)         │
│  → REFUNDING (if customer initiates refund)        │
│                                                     │
│ Database state:                                     │
│  status = "processing"                              │
│  paymentStatus = "confirmed"                        │
│  paymentConfirmedAt = now                          │
│  paymentCompletedAt = webhook timestamp            │
│  transactionId = JAZZ_xxxxx                        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 5: ORDER_PROCESSING                           │
├─────────────────────────────────────────────────────┤
│ Timeline: Order confirmed to shipment prepared      │
│ What happens:                                       │
│  - Warehouse receives order notification            │
│  - Staff picks items from shelves                   │
│  - Items verified against order                     │
│  - Items packed                                     │
│  - Shipping label printed                           │
│  - Handed to courier                                │
│                                                     │
│ Customer sees:                                      │
│  - "Order Processing"                               │
│  - Estimated delivery: 2-3 business days           │
│  - "We're preparing your order"                     │
│                                                     │
│ Notifications:                                      │
│  - "Your order is being prepared"                   │
│  - "Your items have been packed"                    │
│  - "Your order is on the way"                       │
│                                                     │
│ Timeline: Typically 1-2 hours                       │
│                                                     │
│ Transitions to:                                     │
│  → SHIPPED (once in transit)                        │
│  → CANCELLED (if requested before shipping)         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 6: SHIPPED                                    │
├─────────────────────────────────────────────────────┤
│ Timeline: Item in transit                           │
│ What happens:                                       │
│  - Tracking number generated                        │
│  - Customer notified with tracking link             │
│  - Courier updates status                           │
│  - Package in transit                               │
│                                                     │
│ Customer sees:                                      │
│  - Tracking number: TRK-12345678                    │
│  - "Out for delivery"                               │
│  - Estimated delivery date                          │
│  - Real-time tracking map                           │
│                                                     │
│ Timeline: Typically 2-3 business days              │
│                                                     │
│ Transitions to:                                     │
│  → DELIVERED (when delivered)                       │
│  → DELIVERY_FAILED (if attempt fails)              │
│  → RETURN_INITIATED (if customer starts return)     │
│                                                     │
│ Database state:                                     │
│  status = "shipped"                                 │
│  trackingNumber = TRK-xxxxx                        │
│  estimatedDeliveryDate = calculated                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 7: DELIVERED / END STATE                      │
├─────────────────────────────────────────────────────┤
│ What happens:                                       │
│  - Courier confirms delivery                        │
│  - Customer receives order                          │
│  - Delivery photo taken (optional)                  │
│  - Order marked complete                            │
│                                                     │
│ Customer sees:                                      │
│  - ✅ "Order Delivered"                             │
│  - Delivery date/time                               │
│  - Option to rate/review                            │
│  - Request return/exchange                          │
│                                                     │
│ Post-delivery actions available:                    │
│  - Return request (7-30 days based on policy)      │
│  - Exchange request                                 │
│  - Dispute/complaint                                │
│                                                     │
│ Database state:                                     │
│  status = "delivered"                               │
│  actualDeliveryDate = now                          │
│  completed = true                                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 8: PAYMENT_FAILED                             │
├─────────────────────────────────────────────────────┤
│ Causes:                                             │
│  - Insufficient balance                             │
│  - OTP failed                                       │
│  - Transaction declined                             │
│  - User cancelled                                   │
│  - Network error                                    │
│                                                     │
│ What happens:                                       │
│  - Stock reserved lock released                     │
│  - Items returned to available inventory            │
│  - Failure reason logged                            │
│  - Customer notified with reason                    │
│  - Retry option provided                            │
│                                                     │
│ Customer sees:                                      │
│  - Specific failure reason                          │
│  - [Retry Payment] button                           │
│  - [Use Different Method] option                    │
│  - Contact support link                             │
│                                                     │
│ Retry behavior:                                     │
│  - First 3 attempts: immediate retry allowed        │
│  - After 3 attempts: 5-minute cooldown             │
│  - After 5 attempts: contact support                │
│  - Auto-timeout: 30 minutes                         │
│                                                     │
│ Database state:                                     │
│  status = "pending" or "cancelled"                  │
│  paymentStatus = "failed"                           │
│  failureReason = specific reason code               │
│  retryCount = incremented                           │
│  lastRetryAt = now                                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ STATE 9: REFUNDING / REFUNDED                       │
├─────────────────────────────────────────────────────┤
│ Triggers:                                           │
│  - Customer requests cancellation                   │
│  - Delivery failed/unable to reach customer         │
│  - Out of stock discovered after payment            │
│  - Admin initiates refund                           │
│                                                     │
│ Process:                                            │
│  - Verify payment was indeed captured               │
│  - Initiate refund with SafePay/JazzCash           │
│  - Wait for refund confirmation webhook             │
│  - Update order status                              │
│  - Return stock to inventory                        │
│  - Send refund confirmation to customer             │
│                                                     │
│ Timeline:                                           │
│  - Refund initiated: Immediate                      │
│  - Refund processing: 2-3 business days             │
│  - Money appears in wallet: 2-3 days                │
│                                                     │
│ Customer sees:                                      │
│  - "Refund in Progress" (pending)                   │
│  - "Refunded" (completed)                           │
│  - Refund amount and timeline                       │
│  - Reference number                                 │
│                                                     │
│ Database state:                                     │
│  status = "cancelled"                               │
│  paymentStatus = "refunding" → "refunded"          │
│  refundStatus = "pending" → "completed"            │
│  refundAmount = order total                         │
│  refundInitiatedAt = now                           │
│  refundCompletedAt = confirmation date              │
└─────────────────────────────────────────────────────┘
```

---

## 🔌 SafePay Integration Details

### SafePay API Reference

```
BASE URL: https://gateway.safepay.com.pk/api/v3
TEST MODE: https://sandbox.api.getsafepay.com/api/v3

AUTHENTICATION:
  Header: Authorization: Bearer {SAFEPAY_API_KEY}
  Signature: X-Signature: {HMAC_SHA256}

REQUEST SIGNING:
  signature = HMAC-SHA256(request_body, SAFEPAY_SECRET_KEY)
  Encode as Base64
  Include in X-Signature header
```

### 1. Payment Initiation Endpoint

```
ENDPOINT: POST /payment/initiate
Purpose: Create payment session

REQUEST:
{
  "merchantId": "your_merchant_id",
  "amount": 55000,                    // In paisa (PKR * 100)
  "orderRefNum": "507f1f77...",       // Your order ID
  "orderDesc": "Order #507f1f77 - Prestige Collection",
  "currency": "PKR",
  "timestamp": 1687255800,            // Unix timestamp
  "customer": {
    "id": "customer@email.com",
    "email": "customer@email.com",
    "mobileNumber": "+923009999999",  // E.164 format
    "name": "Ahmad Khan"
  },
  "redirectUrl": "https://prestigecollection.com/payment-callback"
}

RESPONSE (Success):
{
  "success": true,
  "payload": {
    "requestId": "SPR_20260616_00123456",
    "redirectUrl": "https://gateway.safepay.com.pk/checkout/SPR_20260616_00123456"
  }
}

RESPONSE (Failure):
{
  "success": false,
  "error": "Invalid merchant credentials"
}

ACTION: Redirect user to redirectUrl
```

### 2. Payment Query Endpoint

```
ENDPOINT: GET /payment/query
Purpose: Check payment status

REQUEST:
{
  "requestId": "SPR_20260616_00123456",
  "merchantId": "your_merchant_id",
  "timestamp": 1687255800
}

RESPONSE:
{
  "success": true,
  "payload": {
    "requestId": "SPR_20260616_00123456",
    "transactionId": "JAZZ_123456",
    "amount": 55000,
    "currency": "PKR",
    "status": "captured",              // or: pending, failed
    "paymentMethod": "JazzCash",
    "completedAt": 1687255843
  }
}

Status Values:
  "captured"    → Payment successful
  "pending"     → Still processing
  "failed"      → Payment declined
  "cancelled"   → User cancelled
  "timeout"     → Request timed out
```

### 3. Refund Endpoint

```
ENDPOINT: POST /refund/initiate
Purpose: Issue refund

REQUEST:
{
  "transactionId": "JAZZ_123456",
  "merchantId": "your_merchant_id",
  "amount": 55000,                    // Refund amount
  "reason": "Customer Requested",
  "timestamp": 1687255800
}

RESPONSE:
{
  "success": true,
  "payload": {
    "refundId": "REF_20260616_00001",
    "transactionId": "JAZZ_123456",
    "amount": 55000,
    "status": "initiated"
  }
}

Refund Timeline:
  Initiated: Immediate
  Processing: 1-3 business days
  Completed: Money returns to wallet
  Status Check: Query with refundId
```

---

## 🎯 Webhook Handling

### Webhook Structure

```
INCOMING WEBHOOK REQUEST
═════════════════════════

URL: POST https://your-domain.com/api/webhooks/safepay

HEADERS:
  X-Signature: {hmac_sha256_signature}
  Content-Type: application/json
  User-Agent: SafePay/1.0

BODY:
{
  "requestId": "SPR_20260616_00123456",
  "orderRefNum": "507f1f77bcf86cd799439011",
  "transactionId": "JAZZ_20260616_00123456",
  "status": "captured",
  "amount": 55000,
  "currency": "PKR",
  "paymentMethod": "JazzCash",
  "timestamp": 1687255843,
  "failureReason": null                // Only if failed
}
```

### Webhook Processing Flowchart

```
[WEBHOOK RECEIVED]
        │
        ▼
[1. VALIDATE SOURCE]
  ├─→ Check X-Signature header exists
  ├─→ Verify signature using SECRET_KEY
  ├─→ Signature valid?
  │   ├─→ YES: Continue
  │   └─→ NO: Log & Return 401 (Don't process)
  └─→ Check source IP (optional but recommended)
      SafePay IPs:
      - 203.192.xxx.xxx
      - 203.193.xxx.xxx
        
        ▼
[2. CHECK IDEMPOTENCY]
  ├─→ Create idempotency key from request
  ├─→ Key format: "{requestId}_{timestamp}"
  ├─→ Check WebhookReceipt collection
  │   ├─→ Already processed?
  │   │   ├─→ YES: Return 200 OK (don't re-process)
  │   │   └─→ NO: Continue
  │   └─→ Save WebhookReceipt with status: 'processing'
  │
        ▼
[3. FIND MATCHING ORDER]
  ├─→ Query Order by orderRefNum (safepayRequestId)
  ├─→ Order found?
  │   ├─→ NO: Log error & Return 200 OK
  │   │        (Acknowledge, but can't process)
  │   └─→ YES: Continue
  │
        ▼
[4. VERIFY AMOUNT]
  ├─→ Compare webhook amount with order total
  ├─→ 55000 paisa == 55000 paisa?
  │   ├─→ YES: Continue
  │   └─→ NO: Log discrepancy & Return 401
  │           (Possible fraud)
  │
        ▼
[5. QUERY SAFEPAY API]
  ├─→ Call SafePay /payment/query endpoint
  ├─→ Request: { requestId, merchantId, timestamp }
  ├─→ Verify API response:
  │   ├─→ Status matches webhook?
  │   ├─→ Amount matches webhook?
  │   ├─→ Transaction ID valid?
  │   └─→ All verified?
  │       ├─→ YES: Continue
  │       └─→ NO: Return 500 (retry later)
  │
        ▼
[6. UPDATE DATABASE]
  ├─→ If status == "captured":
  │   ├─→ Set paymentStatus = "confirmed"
  │   ├─→ Set status = "processing"
  │   ├─→ Set paymentConfirmedAt = now
  │   ├─→ Set transactionId = from webhook
  │   ├─→ Reduce stock (final deduction)
  │   └─→ Set paymentConfirmedAt = now
  │
  ├─→ If status == "failed":
  │   ├─→ Set paymentStatus = "failed"
  │   ├─→ Set failureReason = from webhook
  │   ├─→ Release stock reservation
  │   └─→ Keep status = "pending" (allow retry)
  │
        ▼
[7. TRIGGER PROCESSES]
  ├─→ If payment confirmed:
  │   ├─→ Send confirmation email to customer
  │   ├─→ Send SMS with order details
  │   ├─→ Notify warehouse (create shipment)
  │   ├─→ Add to fulfillment queue
  │   └─→ Create PaymentLog entry
  │
  └─→ If payment failed:
      ├─→ Send failure notification
      ├─→ Offer retry option
      └─→ Create PaymentLog entry
  │
        ▼
[8. UPDATE WEBHOOK RECEIPT]
  ├─→ Update WebhookReceipt status = 'processed'
  ├─→ Log processedAt = now
  ├─→ Save any errors (if applicable)
  │
        ▼
[9. RETURN RESPONSE]
  ├─→ Return 200 OK
  ├─→ Body: { "success": true, "message": "Webhook processed" }
  └─→ SafePay stops retrying
```

### Webhook Handler Implementation

```typescript
@Post('webhooks/safepay')
async handleSafePayWebhook(
  @Body() payload: any,
  @Headers('x-signature') signature: string,
  @Req() req: Request,
) {
  this.logger.log('SafePay webhook received');

  // Step 1: Validate source
  if (!signature) {
    this.logger.warn('Missing X-Signature header');
    return { success: false };
  }

  const expectedSignature = this.generateSignature(JSON.stringify(payload));
  if (!this.verifySignature(signature, expectedSignature)) {
    this.logger.warn('Invalid signature');
    return { success: false };
  }

  // Step 2: Check idempotency
  const idempotencyKey = `${payload.requestId}_${payload.timestamp}`;
  const existing = await this.webhookReceiptModel.findOne({ idempotencyKey });
  
  if (existing) {
    this.logger.log(`Duplicate webhook detected: ${idempotencyKey}`);
    return { success: true }; // Return OK, don't reprocess
  }

  // Create receipt
  await this.webhookReceiptModel.create({
    idempotencyKey,
    safepayRequestId: payload.requestId,
    status: 'processing',
    rawPayload: payload,
    signature,
    sourceIP: req.ip,
  });

  // Step 3: Find order
  const order = await this.orderModel.findOne({
    safepayRequestId: payload.requestId
  });

  if (!order) {
    this.logger.warn(`Order not found for: ${payload.requestId}`);
    return { success: true }; // Acknowledge but can't process
  }

  // Step 4: Verify amount
  if (payload.amount !== order.grandTotal * 100) {
    this.logger.error(`Amount mismatch: ${payload.amount} vs ${order.grandTotal * 100}`);
    return { success: false };
  }

  // Step 5: Query SafePay API
  try {
    const apiResult = await this.safepayService.queryPaymentStatus(
      payload.requestId
    );

    if (apiResult.status !== payload.status) {
      throw new Error('Status mismatch with SafePay API');
    }

    // Step 6: Update database
    if (payload.status === 'captured') {
      order.paymentStatus = 'confirmed';
      order.status = 'processing';
      order.paymentConfirmedAt = new Date();
      order.safepayTransactionId = payload.transactionId;
      order.webhookReceivedAt = new Date(payload.timestamp * 1000);
      
      // Reduce stock (final deduction)
      for (const item of order.items) {
        await this.productService.updateStock(
          item.productId,
          -item.quantity
        );
      }
    } else if (payload.status === 'failed') {
      order.paymentStatus = 'failed';
      order.failureReason = payload.failureReason;
      
      // Release stock
      for (const item of order.items) {
        await this.releaseStockReservation(item.productId, item.quantity);
      }
    }

    await order.save();

    // Step 7: Trigger processes
    if (payload.status === 'captured') {
      // Send email
      await this.emailService.sendOrderConfirmation(order);
      
      // Send SMS
      await this.smsService.sendConfirmation(order.shippingAddress.phoneNumber);
      
      // Notify warehouse
      await this.warehouseService.createShipment(order._id);
      
      // Add to fulfillment queue
      await this.fulfillmentService.enqueue(order._id);
    }

    // Create payment log
    await this.paymentLogModel.create({
      orderId: order._id,
      eventType: payload.status === 'captured' ? 'PAYMENT_CONFIRMED' : 'PAYMENT_FAILED',
      amount: payload.amount / 100,
      transactionId: payload.transactionId,
      status: payload.status,
      failureReason: payload.failureReason,
      metadata: { webhook: true }
    });

    // Step 8: Update receipt
    await this.webhookReceiptModel.updateOne(
      { idempotencyKey },
      { status: 'processed', processedAt: new Date() }
    );

    // Step 9: Return success
    return { success: true };

  } catch (error) {
    this.logger.error(`Webhook processing failed: ${error.message}`);
    
    // Update receipt with error
    await this.webhookReceiptModel.updateOne(
      { idempotencyKey },
      { 
        status: 'failed',
        errorMessage: error.message,
        retryCount: 1
      }
    );

    // Return 500 so SafePay retries
    throw new InternalServerErrorException('Webhook processing failed');
  }
}
```

---

## 🔄 Reconciliation & Edge Cases

### Payment Reconciliation Strategy

```
DAILY RECONCILIATION PROCESS
════════════════════════════

Timeline: Run at 2:00 AM daily (off-peak)

Process:
───────

1. FETCH UNCONFIRMED ORDERS
   SELECT orders WHERE
     paymentStatus IN ('pending', 'processing')
     AND createdAt > NOW() - 24 hours
   
   For each order:

2. QUERY SAFEPAY API
   GET /payment/query
     requestId: order.safepayRequestId
   
   Possible responses:
   ├─→ Status = "captured"
   │   └─→ Order shows failed but SafePay says paid
   │       └─→ UPDATE: paymentStatus = "confirmed"
   │       └─→ ALERT: Webhook was missed
   │
   ├─→ Status = "failed"
   │   └─→ Matches our records
   │       └─→ NO ACTION
   │
   ├─→ Status = "pending"
   │   └─→ Still processing after 24 hours
   │       └─→ ALERT: Investigate
   │       └─→ Mark for manual review
   │
   └─→ Status = Not found
       └─→ Invalid requestId
           └─→ ALERT: Manual investigation needed

3. CROSS-CHECK SAFEPAY VS DATABASE
   For each captured payment:
     - Amount matches? ✓
     - TransactionID matches? ✓
     - Timestamp reasonable? ✓ (within 5 min of webhook)
     - Stock correctly deducted? ✓
     - Fulfillment queued? ✓
   
   If any mismatch:
     → Alert admin
     → Create reconciliation ticket
     → Don't auto-fix (manual review required)

4. GENERATE RECONCILIATION REPORT
   Summary:
     - Total orders checked: 847
     - Confirmed: 840
     - Mismatch found: 3 (requires review)
     - Webhooks missed: 2 (recovered)
     - Unresolved: 2 (requires investigation)
   
   Email to admin with details
```

### Edge Case Handling

```
EDGE CASE 1: WEBHOOK ARRIVES BEFORE DATABASE READY
════════════════════════════════════════════════════

Scenario:
  - Order created in database
  - Payment initiated
  - Webhook arrives ~100ms after initiation
  - Order record might still be syncing

Solution:
  1. Webhook handler queries for order
  2. Order not found
  3. Handler creates BackgroundTask
  4. Task retries finding order every 100ms
  5. After 10 seconds, if not found, log and skip
  6. Reconciliation job finds it later

Implementation:
  await this.taskQueue.enqueue({
    type: 'RETRY_WEBHOOK',
    orderId: payload.orderRefNum,
    payload: payload,
    retryCount: 0,
    maxRetries: 100 // 10 seconds
  });


EDGE CASE 2: DUPLICATE WEBHOOK
════════════════════════════════

Scenario:
  - Webhook received and processed
  - SafePay receives ACK timeout (never got 200 OK)
  - SafePay retries webhook (exact same request)

Solution:
  1. WebhookReceipt checked by idempotencyKey
  2. Duplicate detected
  3. Handler returns 200 OK immediately
  4. No re-processing occurs

Implementation:
  const key = `${request.requestId}_${request.timestamp}`;
  const existing = await webhookReceipt.findOne({ idempotencyKey: key });
  
  if (existing) {
    return { success: true }; // Don't reprocess
  }


EDGE CASE 3: PAYMENT CONFIRMED BUT STOCK OUT
═════════════════════════════════════════════

Scenario:
  - Payment received and confirmed
  - Stock for item is now zero
  - Can't fulfill order

Solution:
  1. Detection happens during stock deduction
  2. Transaction rolled back
  3. Refund initiated automatically
  4. Customer notified
  5. Admin alerted

Implementation:
  try {
    for (const item of order.items) {
      const product = await Product.findById(item.productId);
      
      if (product.stock < item.quantity) {
        // Stock insufficient
        throw new OutOfStockException(item.name);
      }
      
      product.stock -= item.quantity;
      await product.save();
    }
  } catch (error) {
    // Rollback all updates
    for (const item of order.items) {
      await Product.updateOne(
        { _id: item.productId },
        { $inc: { stock: item.quantity } }
      );
    }
    
    // Initiate refund
    await this.safepayService.initiateRefund({
      transactionId: order.safepayTransactionId,
      amount: order.grandTotal,
      reason: 'Out of stock'
    });
    
    // Notify customer
    await this.emailService.sendOutOfStockNotification(order);
  }


EDGE CASE 4: NETWORK TIMEOUT DURING WEBHOOK PROCESSING
═══════════════════════════════════════════════════════

Scenario:
  - Webhook received
  - Signature verified
  - During database update, connection lost
  - Can't determine if order was updated

Solution:
  1. Use database transactions
  2. Either all succeed or all fail
  3. If connection lost, transaction automatically rolled back
  4. SafePay retries webhook
  5. Second attempt completes

Implementation:
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    await Order.updateOne(
      { _id: order._id },
      { paymentStatus: 'confirmed', ... },
      { session }
    );
    
    await PaymentLog.create([{ ... }], { session });
    
    await session.commitTransaction();
  } catch (error) {
    await session.abortTransaction();
    throw error; // Webhook will retry
  } finally {
    session.endSession();
  }


EDGE CASE 5: CUSTOMER DOUBLE-CLICKS PAY BUTTON
═══════════════════════════════════════════════

Scenario:
  - Customer clicks "Place Order" twice rapidly
  - Two payment sessions created
  - Same customer pays twice by accident

Prevention:
  1. Disable button after first click
  2. Show loading state
  3. Debounce submit handler

Implementation (Frontend):
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const handlePlaceOrder = async () => {
    if (isSubmitting) return; // Prevent double-click
    
    setIsSubmitting(true);
    try {
      await submitOrder();
    } finally {
      setIsSubmitting(false);
    }
  };
  
  <button disabled={isSubmitting}>
    {isSubmitting ? 'Processing...' : 'Place Order'}
  </button>

Recovery (Backend):
  If customer somehow created 2 orders within 1 minute:
  1. Mark later order as duplicate
  2. Initiate refund for second payment
  3. Merge orders if both paid
  4. Notify customer with compensation


EDGE CASE 6: SAFEPAY API TIMEOUT
═════════════════════════════════

Scenario:
  - Webhook received
  - Try to verify with SafePay API
  - SafePay API not responding (timeout)
  - Unknown if payment is real

Solution:
  1. On timeout, defer verification
  2. Store webhook in queue
  3. Retry verification after 30 seconds
  4. Use exponential backoff

Implementation:
  try {
    const result = await safepayService.queryPaymentStatus(
      payload.requestId,
      { timeout: 5000 } // 5 second timeout
    );
  } catch (error) {
    if (error.code === 'TIMEOUT') {
      // Defer verification
      await this.verificationQueue.enqueue({
        orderId: order._id,
        requestId: payload.requestId,
        retryCount: 0,
        nextRetryAt: Date.now() + 30000
      });
      
      return { success: true }; // Acknowledge webhook
    }
  }


EDGE CASE 7: PAYMENT SUCCEEDED BUT ORDER CREATION FAILED
════════════════════════════════════════════════════════

Scenario:
  - SafePay processes payment (money deducted)
  - Webhook sent to your server
  - Your database INSERT fails
  - No order record created
  - Customer confused

Solution:
  1. Use database transactions for order creation
  2. If order creation fails, rollback
  3. Webhook goes to error queue
  4. Refund initiated automatically

Implementation:
  @Post('orders')
  async createOrder(userId, orderData) {
    const session = await mongoose.startSession();
    session.startTransaction();
    
    try {
      // Create order
      const order = await Order.create([orderData], { session });
      
      // Reserve stock
      for (const item of order.items) {
        await Product.updateOne(
          { _id: item.productId },
          { $inc: { stockReserved: item.quantity } },
          { session }
        );
      }
      
      await session.commitTransaction();
      return order;
      
    } catch (error) {
      await session.abortTransaction();
      throw error; // Frontend shows error, no payment yet
    }
  }


EDGE CASE 8: CUSTOMER ABANDONS PAYMENT MID-PROCESS
───────────────────────────────────────────────────

Scenario:
  - Order created
  - Payment session started
  - Customer closes browser
  - Payment might or might not complete
  - Unknown status

Solution:
  1. Backend checks payment status periodically
  2. If no webhook after 30 seconds, query SafePay API
  3. If payment detected, create webhook manually
  4. If not, mark order as expired

Implementation:
  @Cron('*/10 * * * *') // Every 10 minutes
  async checkAbandonedPayments() {
    const pendingOrders = await Order.find({
      paymentStatus: 'pending',
      createdAt: { $gt: Date.now() - 2 * 60 * 1000 } // Last 2 mins
    });
    
    for (const order of pendingOrders) {
      try {
        const status = await this.safepayService.queryPaymentStatus(
          order.safepayRequestId
        );
        
        if (status.status === 'captured' && !order.webhookReceivedAt) {
          // Payment succeeded but webhook didn't arrive
          // Process it manually
          await this.handlePaymentConfirmation(order, {
            requestId: order.safepayRequestId,
            transactionId: status.transactionId,
            status: 'captured',
            timestamp: Math.floor(Date.now() / 1000)
          });
        }
      } catch (error) {
        this.logger.error(`Failed to check order: ${order._id}`);
      }
    }
  }
```

---

## 🎯 Best Practices

### 1. Security Best Practices

```
SAFEPAY INTEGRATION SECURITY
════════════════════════════

✓ ALWAYS verify webhook signature
  - Never process unsigned webhooks
  - Use HMAC-SHA256 for verification
  - Use constant-time comparison (timingSafeEqual)
  
✓ NEVER log sensitive data
  - No card numbers in logs
  - No full phone numbers
  - No API keys in logs
  - Mask sensitive fields: "XXXXXX9999"
  
✓ ALWAYS use HTTPS
  - Webhook URL must be HTTPS
  - API calls must be HTTPS
  - Enforce TLS 1.2+
  
✓ ALWAYS validate user input
  - Sanitize amount before sending
  - Validate phone format
  - Validate email format
  - Rate limit payment attempts
  
✓ STORE credentials securely
  - Use environment variables
  - Never hardcode API keys
  - Rotate keys periodically
  - Use secrets management service (e.g., HashiCorp Vault)
  
✓ IMPLEMENT rate limiting
  - Limit payment initiation: 5 per minute per user
  - Limit webhook processing: 100 per second per IP
  - Limit API queries: 10 per minute per order
  
✓ USE database transactions
  - All-or-nothing updates
  - Prevent partial data corruption
  - Automatic rollback on errors
  
✓ IMPLEMENT audit logging
  - Log all payment events
  - Log all webhook receipts
  - Log all API calls
  - Keep logs for 1+ year
  - Immutable log storage
```

### 2. Reliability Best Practices

```
PAYMENT RELIABILITY
═══════════════════

✓ IMPLEMENT idempotency
  - Every request has unique ID
  - Duplicate requests return same result
  - Store processed request IDs
  - Prevents duplicate charges
  
✓ USE exponential backoff
  Retry strategy:
    Attempt 1: Immediate
    Attempt 2: After 1 second
    Attempt 3: After 2 seconds
    Attempt 4: After 4 seconds
    Attempt 5: After 8 seconds
    Max: 5 minutes total
  
✓ IMPLEMENT circuit breaker
  If SafePay is down:
    - Track failure count
    - After 5 consecutive failures, open circuit
    - Return error to user
    - Retry in background
    - Close circuit when success
  
✓ USE webhook verification with fallback
  Webhook failed to arrive?
    - Wait 30 seconds
    - Query SafePay API directly
    - If payment confirmed, process it
    - If not, keep waiting (up to 5 minutes)
  
✓ IMPLEMENT monitoring & alerts
  Alert if:
    - Payment success rate < 95%
    - Average payment time > 60 seconds
    - Webhook delivery rate < 99%
    - API response time > 5 seconds
    - More than 5 timeouts in 1 hour
```

### 3. Data Integrity Best Practices

```
DATA CONSISTENCY
════════════════

✓ STORE complete webhook payload
  - For audit trail
  - For debugging
  - For replay if needed
  - Keep for 90 days
  
✓ CREATE immutable transaction logs
  - Never update PaymentLog (only insert)
  - Contains complete history
  - Useful for disputes
  
✓ USE database transactions
  - Atomic updates (all or nothing)
  - No partial updates
  - Automatic rollback on error
  
✓ VALIDATE data consistency
  Daily reconciliation:
    - Total orders in DB = Total in SafePay
    - Total amounts in DB = Total revenue
    - Stock count correct
    - No duplicate transactions
  
✓ IMPLEMENT idempotency keys
  Format: {method}_{timestamp}_{hash}
  Example: PAYMENT_1687255800_a1b2c3d4
  Prevents duplicate processing
```

### 4. User Experience Best Practices

```
CUSTOMER EXPERIENCE
═══════════════════

✓ Clear payment status display
  ├─→ Pending: "Awaiting Payment"
  ├─→ Processing: "Verifying..."
  ├─→ Confirmed: "Payment Received ✓"
  └─→ Failed: "Payment Failed - [Reason]"
  
✓ Provide specific failure reasons
  ❌ DON'T: "Payment failed, please try again"
  ✅ DO: "Insufficient balance in wallet (need PKR 350 more)"
  
✓ Make retries easy
  - Show [Retry] button on failure
  - Remember payment method
  - Pre-fill customer info
  - Offer alternative payment methods
  
✓ Set clear timeouts
  - 30-minute payment window
  - Warn after 10 minutes: "5 minutes remaining"
  - Warn after 25 minutes: "Order expires soon"
  - Cancel after 30 minutes
  
✓ Send timely notifications
  - SMS/Email when payment initiated
  - Confirmation immediately after payment
  - Reminder if abandoned after 5 minutes
  - Tracking when shipped
  
✓ Make refunds transparent
  - Show refund status clearly
  - Expected timeline: "2-3 business days"
  - Reference number for tracking
  - Link to support if issues
  
✓ Provide excellent support
  - Easy access to support chat
  - Help center articles
  - FAQ section
  - Phone support for large orders
```

### 5. Operational Best Practices

```
OPERATIONS & MONITORING
═══════════════════════

✓ DASHBOARD METRICS
  Track:
    - Payment success rate (target: >98%)
    - Average payment time
    - Failure rate by payment method
    - Refund rate
    - Customer satisfaction
  
✓ ALERTS & ESCALATION
  Critical:
    - Success rate drops below 95%
    - SafePay API unreachable
    - Webhook delivery fails
    - Database connection lost
  
  Warning:
    - Success rate 95-98%
    - High timeout rate
    - Unusual refund pattern
    - Fraud detection triggered
  
✓ INCIDENT RESPONSE
  Payment outage procedure:
    1. Acknowledge incident
    2. Notify affected customers
    3. Provide status updates
    4. Investigate root cause
    5. Fix and test
    6. Deploy and verify
    7. Post-mortem analysis
  
✓ PERFORMANCE OPTIMIZATION
  - Cache customer info
  - Use async webhooks
  - Batch database updates
  - CDN for static files
  - Database indexing
  
✓ TESTING
  - Unit tests for payment logic
  - Integration tests with SafePay sandbox
  - End-to-end payment flow tests
  - Load testing (500+ concurrent payments)
  - Chaos testing (simulate failures)
  
✓ DOCUMENTATION
  - API documentation
  - Webhook event types
  - Error codes & meanings
  - Runbook for common issues
  - Disaster recovery plan
```

---

## 📊 Sample Dashboard Queries

```javascript
// MongoDB queries for admin dashboard

// 1. Payment success rate today
db.orders.aggregate([
  {
    $match: {
      createdAt: {
        $gte: new Date(new Date().setHours(0, 0, 0, 0))
      }
    }
  },
  {
    $group: {
      _id: null,
      total: { $sum: 1 },
      confirmed: {
        $sum: { $cond: [{ $eq: ["$paymentStatus", "confirmed"] }, 1, 0] }
      }
    }
  },
  {
    $project: {
      successRate: {
        $multiply: [
          { $divide: ["$confirmed", "$total"] },
          100
        ]
      }
    }
  }
]);

// 2. Revenue by payment method (last 30 days)
db.orders.aggregate([
  {
    $match: {
      createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
      paymentStatus: "confirmed"
    }
  },
  {
    $group: {
      _id: "$paymentMethod",
      total: { $sum: "$grandTotal" },
      count: { $sum: 1 },
      avgAmount: { $avg: "$grandTotal" }
    }
  },
  { $sort: { total: -1 } }
]);

// 3. Failed payments analysis
db.orders.aggregate([
  {
    $match: { paymentStatus: "failed" }
  },
  {
    $group: {
      _id: "$failureReason",
      count: { $sum: 1 },
      totalAmount: { $sum: "$grandTotal" }
    }
  },
  { $sort: { count: -1 } }
]);

// 4. Payment time analysis (how long from order to confirmation)
db.orders.aggregate([
  {
    $match: { paymentStatus: "confirmed" },
    $project: {
      processingTime: {
        $subtract: ["$paymentConfirmedAt", "$createdAt"]
      }
    }
  },
  {
    $group: {
      _id: null,
      avgTime: { $avg: "$processingTime" },
      minTime: { $min: "$processingTime" },
      maxTime: { $max: "$processingTime" },
      p99Time: {
        $percentile: ["$processingTime", 0.99]
      }
    }
  }
]);

// 5. Pending payments (need manual attention)
db.orders.aggregate([
  {
    $match: {
      paymentStatus: "pending",
      createdAt: { $lte: new Date(Date.now() - 15 * 60 * 1000) }
    }
  },
  { $sort: { createdAt: 1 } },
  {
    $project: {
      orderId: 1,
      customer: 1,
      amount: "$grandTotal",
      createdAt: 1,
      minutesWaiting: {
        $divide: [{ $subtract: [new Date(), "$createdAt"] }, 60000]
      }
    }
  }
]);
```

---

## 🎓 Summary & Implementation Checklist

```
PRODUCTION IMPLEMENTATION CHECKLIST
═══════════════════════════════════

PHASE 1: DATABASE & DATA MODEL (Week 1)
  ☐ Create Order schema with all payment fields
  ☐ Create PaymentLog schema for audit
  ☐ Create WebhookReceipt schema for idempotency
  ☐ Add database indexes for performance
  ☐ Test database transactions

PHASE 2: BACKEND PAYMENT PROCESSING (Week 2-3)
  ☐ Implement order creation endpoint
  ☐ Implement SafePay API integration
  ☐ Implement webhook handling
  ☐ Implement webhook signature verification
  ☐ Implement idempotency checking
  ☐ Implement payment verification queries
  ☐ Implement refund handling
  ☐ Add comprehensive logging

PHASE 3: ERROR HANDLING & RECOVERY (Week 3-4)
  ☐ Implement retry logic with exponential backoff
  ☐ Implement circuit breaker for API failures
  ☐ Implement timeout handling
  ☐ Implement abandoned order recovery
  ☐ Implement payment reconciliation job
  ☐ Implement alert system

PHASE 4: FRONTEND CUSTOMER EXPERIENCE (Week 4)
  ☐ Implement payment status display
  ☐ Implement failure notification
  ☐ Implement retry mechanism
  ☐ Implement timeout warning
  ☐ Implement confirmation screen
  ☐ Implement loading states
  ☐ Prevent double-click payment

PHASE 5: ADMIN FEATURES (Week 5)
  ☐ Build admin dashboard
  ☐ Implement payment status view
  ☐ Implement manual verification endpoint
  ☐ Implement refund interface
  ☐ Implement payment history view
  ☐ Implement reconciliation reports
  ☐ Implement alerts & notifications

PHASE 6: TESTING & QA (Week 6)
  ☐ Unit tests for payment logic
  ☐ Integration tests with sandbox
  ☐ End-to-end payment flow tests
  ☐ Load testing
  ☐ Security testing
  ☐ Edge case testing
  ☐ UAT with team

PHASE 7: MONITORING & SUPPORT (Week 7)
  ☐ Setup payment monitoring
  ☐ Setup alerts
  ☐ Setup logging
  ☐ Create runbooks
  ☐ Train support team
  ☐ Document API
  ☐ Setup on-call rotation

PHASE 8: PRODUCTION LAUNCH (Week 8)
  ☐ Production credential setup
  ☐ SSL certificate validation
  ☐ Webhook URL update
  ☐ Final testing in production
  ☐ Gradual rollout (5% → 25% → 100%)
  ☐ Monitor metrics continuously
  ☐ Have rollback plan ready
```

---

**Created:** June 16, 2026  
**Version:** 1.0 - Production Ready  
**Status:** Complete Implementation Guide
