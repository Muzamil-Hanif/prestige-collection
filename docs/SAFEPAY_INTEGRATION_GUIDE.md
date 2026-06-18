# SafePay Payment Gateway Integration Guide

This guide walks you through setting up SafePay as the payment gateway for Prestige Men e-commerce platform. The integration uses the **Hosted Page** approach, which is the safest method for accepting payments.

## What We've Integrated

### ✅ Backend (NestJS)
- **SafePay Service** (`src/payments/safepay.service.ts`) - Handles API communication with SafePay
- **Payment Controller** (`src/payments/payments.controller.ts`) - Exposes payment endpoints
- **Payment Module** - Integrated into main app module
- **Order Schema Updates** - Added `paymentTransactionId` and improved `paymentStatus` field

### ✅ Frontend (Flutter)
- **SafePay Service** (`lib/services/safepay_service.dart`) - Client-side payment handling
- **Checkout Flow** - Updated to trigger SafePay payment for card payments
- **Dependencies** - Added `webview_flutter` and `url_launcher` packages
- **UI Updates** - Shows SafePay branding in payment methods

---

## Setup Steps

### Step 1: Obtain SafePay Merchant Account

1. Visit [SafePay](https://safepay.com.pk)
2. Register as a merchant
3. Complete KYC verification
4. Get your merchant credentials:
   - **API Key**
   - **Secret Key**
   - **Merchant ID**

⚠️ **Important**: Keep these credentials secure and never commit them to git.

### Step 2: Configure Backend Environment

1. Copy environment variables:
   ```bash
   cd prestige-men-backend
   cp .env.example .env
   ```

2. Update `.env` with SafePay credentials:
   ```env
   # SafePay Configuration
   SAFEPAY_API_KEY=your-actual-api-key
   SAFEPAY_SECRET_KEY=your-actual-secret-key
   SAFEPAY_MERCHANT_ID=your-actual-merchant-id
   SAFEPAY_REDIRECT_URL=http://localhost:3000
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

### Step 3: Configure Frontend

1. Update `.env` or build configuration:
   ```bash
   cd PrestigeMen
   flutter pub get
   ```

2. For local testing, the app will connect to:
   ```
   http://localhost:3000/api
   ```

### Step 4: Run the Stack

**Terminal 1 - Backend:**
```bash
cd prestige-men-backend
npm run start:dev
```

**Terminal 2 - Frontend (Web):**
```bash
cd PrestigeMen
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

**Terminal 2 - Frontend (Mobile):**
```bash
cd PrestigeMen
# First get your local IP
ipconfig getifaddr en0  # macOS
# Then run with your IP
flutter run -d ios --dart-define=API_BASE_URL=http://192.168.x.x:3000
```

---

## How It Works

### Payment Flow

1. **User Clicks "Place Order"**
   - Address validation ✓
   - Order summary review ✓
   - Payment method selection (Credit/Debit Card or Cash on Delivery)

2. **Order Creation** (Backend)
   - Order saved with `status: 'pending'` and `paymentStatus: 'pending'`
   - Stock is deducted from products

3. **Payment Initiation** (Card Payments Only)
   - App calls `POST /api/payments/initiate/{orderId}`
   - Backend generates SafePay session with HMAC signature
   - SafePay returns `requestId` and `redirectUrl`

4. **Hosted Payment Page** (SafePay)
   - User launched to SafePay secure page
   - User enters card details
   - SafePay processes payment
   - SafePay redirects back to app

5. **Payment Verification** (Backend)
   - App calls `GET /api/payments/verify/{orderId}/{requestId}`
   - Backend queries SafePay for payment status
   - Order status updated: `status: 'processing'` & `paymentStatus: 'captured'`
   - Order status updated: `status: 'cancelled'` & `paymentStatus: 'failed'` (if failed)

6. **Success/Failure Feedback**
   - Success: Shows order confirmation dialog
   - Failure: Shows error message, order remains pending (can retry)

---

## API Endpoints

### Initiate Payment
```
POST /api/payments/initiate/:orderId
Authorization: Bearer {jwt-token}

Response:
{
  "success": true,
  "requestId": "SP123456789",
  "redirectUrl": "https://gateway.safepay.com.pk/payment/..."
}
```

### Verify Payment Status
```
GET /api/payments/verify/:orderId/:requestId
Authorization: Bearer {jwt-token}

Response:
{
  "success": true,
  "paymentStatus": "captured",
  "transactionId": "TXN123456",
  "amount": 1250.00
}
```

### SafePay Webhook (Optional)
```
POST /api/payments/webhook

Payload:
{
  "requestId": "SP123456789",
  "orderRefNum": "order-id",
  "transactionId": "TXN123456",
  "status": "captured"
}
```

---

## Security Considerations

### ✅ What We've Implemented

1. **HMAC-SHA256 Signatures**
   - All requests to SafePay are signed
   - Webhook signatures are validated (can be improved)

2. **JWT Authentication**
   - Payment endpoints require valid JWT token
   - Users can only access their own orders

3. **Server-Side Verification**
   - Payment status always verified on backend
   - Frontend cannot manipulate payment status

4. **Environment Secrets**
   - API keys stored in `.env` (never in code)
   - `.env` added to `.gitignore`

5. **HTTPS Enforcement**
   - Production builds enforce HTTPS
   - API validation prevents HTTP in production

### 🔐 Additional Recommendations

1. **Webhook Signature Validation**
   - Implement full signature validation if using webhooks
   - Current code checks payload format but needs signature validation

2. **Rate Limiting**
   - Add rate limiting on payment endpoints
   - Prevent brute force verification attempts

3. **Audit Logging**
   - Log all payment attempts
   - Track failed payment attempts for fraud detection

4. **PCI Compliance**
   - Hosted page approach reduces PCI burden
   - Never log full card details
   - Only store transaction IDs, not card data

---

## Payment Methods

The checkout page now supports:

| Method | Implementation | Processing |
|--------|---|---|
| **Credit Card** | SafePay Hosted Page | Automatic |
| **Debit Card** | SafePay Hosted Page | Automatic |
| **PayPal** | Manual (Not Integrated) | N/A |
| **Cash on Delivery** | Manual | Order confirmed immediately |

### To Add PayPal (Future)
1. Integrate PayPal SDK in `safepay_service.dart`
2. Create separate PayPal payment initiation flow
3. Add PayPal webhook handler

---

## Testing

### Test Cards (SafePay Sandbox)

Once you have test credentials from SafePay:

```
Card Number: 4111111111111111
Expiry: 12/25
CVV: 123
OTP: Any value (in test mode)
```

### Testing Flow

1. **Create Order:**
   - Select "Credit Card" payment method
   - Fill address details
   - Click "Place Order"

2. **SafePay Page:**
   - Should open SafePay payment page
   - Enter test card details
   - Complete payment

3. **Verification:**
   - App automatically verifies payment
   - Success: Shows order confirmation
   - Failure: Shows error message

### Testing with cURL (Backend Only)

```bash
# Get JWT token first
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Initiate payment
curl -X POST http://localhost:3000/api/payments/initiate/ORDER_ID \
  -H "Authorization: Bearer JWT_TOKEN"

# Verify payment
curl -X GET http://localhost:3000/api/payments/verify/ORDER_ID/REQUEST_ID \
  -H "Authorization: Bearer JWT_TOKEN"
```

---

## Troubleshooting

### Issue: SafePay payment page doesn't open
**Solution:**
- Check `SAFEPAY_REDIRECT_URL` is correct in `.env`
- Ensure backend is running on correct port
- Check browser console for errors

### Issue: Payment verification fails
**Solution:**
- Verify credentials are correct in `.env`
- Check SafePay API key is active in merchant dashboard
- Ensure request signature is being generated correctly

### Issue: Order not found when verifying payment
**Solution:**
- Check order was created successfully (check MongoDB)
- Verify user JWT token is valid
- Check order ID is correct

### Issue: HMAC signature mismatch
**Solution:**
- Verify `SAFEPAY_SECRET_KEY` is exactly correct
- Check request data format matches SafePay spec
- Ensure timestamp is accurate

---

## Production Deployment Checklist

- [ ] Obtain live SafePay credentials
- [ ] Update `SAFEPAY_API_KEY`, `SAFEPAY_SECRET_KEY`, `SAFEPAY_MERCHANT_ID` with live keys
- [ ] Update `SAFEPAY_REDIRECT_URL` to production domain
- [ ] Set `NODE_ENV=production`
- [ ] Enforce HTTPS on backend
- [ ] Update Flutter `IS_PRODUCTION=true` build flag
- [ ] Test with live credentials (small amount)
- [ ] Set up payment webhook handler
- [ ] Configure monitoring/alerts for failed payments
- [ ] Document refund process (add to admin panel)

---

## Files Modified/Created

### Backend
- ✅ `src/payments/safepay.service.ts` - NEW
- ✅ `src/payments/payments.controller.ts` - NEW
- ✅ `src/payments/payments.module.ts` - NEW
- ✅ `src/app.module.ts` - UPDATED (added PaymentsModule)
- ✅ `src/orders/orders.service.ts` - UPDATED (added updatePaymentInfo)
- ✅ `src/orders/schemas/order.schema.ts` - UPDATED (added paymentTransactionId)
- ✅ `.env.example` - UPDATED (added SafePay config)

### Frontend
- ✅ `lib/services/safepay_service.dart` - NEW
- ✅ `lib/pages/checkout_page.dart` - UPDATED (payment flow integration)
- ✅ `pubspec.yaml` - UPDATED (added webview_flutter, url_launcher)

---

## Next Steps

1. **Get SafePay Account** → Get merchant credentials
2. **Configure .env** → Add credentials to backend
3. **Run Backend** → `npm run start:dev`
4. **Run Frontend** → `flutter run -d chrome`
5. **Test Payment** → Place order and verify payment flow
6. **Monitor Logs** → Check console for any errors

---

## Support Resources

- **SafePay Documentation:** https://safepay.com.pk/documentation
- **SafePay Dashboard:** https://merchant.safepay.com.pk
- **Flutter WebView:** https://pub.dev/packages/webview_flutter
- **URL Launcher:** https://pub.dev/packages/url_launcher

---

## Important Notes

⚠️ **Do NOT**:
- Commit `.env` file to git
- Store API keys in code
- Log sensitive payment information
- Skip webhook signature validation in production

✅ **DO**:
- Keep `.env` in `.gitignore`
- Use environment variables for secrets
- Test thoroughly before production
- Monitor payment failures and retry logic
- Document all payment-related code changes

---

Last Updated: 2026-06-15
Integration Status: ✅ Complete (Ready for SafePay Account Setup)
