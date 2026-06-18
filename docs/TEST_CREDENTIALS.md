# Test Credentials & Payment Methods

This file contains test credentials for all payment methods used in Prestige Men. **DO NOT use in production.**

---

## 🛡️ SafePay (Credit/Debit Cards)

**Environment:** Sandbox (Test Mode)
**Dashboard:** https://sandbox.api.getsafepay.com/dashboard

### Test Card Numbers

| Card Type | Number | Expiry | CVV | Status |
|-----------|--------|--------|-----|--------|
| **Visa** | `4111111111111111` | Any future date | Any 3 digits | ✅ Success |
| **Mastercard** | `5555555555554444` | Any future date | Any 3 digits | ✅ Success |
| **Amex** | `378282246310005` | Any future date | Any 4 digits | ✅ Success |

### SafePay Merchant Credentials

```env
SAFEPAY_API_KEY=pub_xxxxx...          # Get from Developer > API
SAFEPAY_SECRET_KEY=sec_xxxxx...       # Get from Developer > API  
SAFEPAY_MERCHANT_ID=Prestige Collections
SAFEPAY_REDIRECT_URL=http://localhost:3000
```

**Test Flow:**
1. Enter any test card number above
2. Enter any future expiry date
3. Enter any 3-digit CVV (4 for Amex)
4. Payment succeeds instantly in test mode

---

## 💳 JazzCash (Pakistan Mobile Wallet)

### Test Merchant Account

```
Merchant ID: SANDBOX_MERCHANT_ID
Password: test_password_123
PP_MERCHANT_KEY: test_key_xyz
```

**Sandbox URL:** https://sandbox.jazzcash.com.pk

### Test Phone Numbers for JazzCash

| Phone Number | Balance | Status |
|--------------|---------|--------|
| `03001234567` | PKR 100,000 | ✅ Active (Sandbox) |
| `03009876543` | PKR 50,000 | ✅ Active (Sandbox) |
| `03005555555` | PKR 0 | ❌ Insufficient Balance (Test Failure) |

### Test Credentials (If API Integration Needed)

```env
JAZZCASH_MERCHANT_ID=your_merchant_id
JAZZCASH_PASSWORD=your_password
JAZZCASH_PP_MERCHANT_KEY=your_merchant_key
JAZZCASH_API_URL=https://sandbox.jazzcash.com.pk/api/v3
```

**Test Flow (Manual - Current):**
1. User enters phone: `03001234567`
2. Order created with status: `"pending"`
3. User completes payment on JazzCash app
4. Admin verifies in JazzCash merchant dashboard
5. Order marked as paid

---

## 📱 easyPaisa (Pakistan Mobile Wallet)

### Test Merchant Account

```
Merchant ID: TEST_EASYPAISA_MID
API Key: test_api_key_123
Store ID: test_store_id
```

**Sandbox URL:** https://sandbox.easypaisa.com.pk (or dev portal)

### Test Phone Numbers for easyPaisa

| Phone Number | Balance | Status |
|--------------|---------|--------|
| `03009999999` | PKR 100,000 | ✅ Active (Sandbox) |
| `03004444444` | PKR 75,000 | ✅ Active (Sandbox) |
| `03007777777` | PKR 0 | ❌ Insufficient Balance (Test Failure) |

### Test Credentials (If API Integration Needed)

```env
EASYPAISA_MERCHANT_ID=your_merchant_id
EASYPAISA_API_KEY=your_api_key
EASYPAISA_STORE_ID=your_store_id
EASYPAISA_API_URL=https://sandbox.easypaisa.com.pk/api/v3
```

**Test Flow (Manual - Current):**
1. User enters phone: `03009999999`
2. Order created with status: `"pending"`
3. User completes payment on easyPaisa app
4. Admin verifies in easyPaisa merchant dashboard
5. Order marked as paid

---

## 💰 Cash on Delivery (COD)

**No credentials needed.**

**Test Flow:**
1. Select "Cash on Delivery"
2. Complete checkout
3. ✅ Order confirmed immediately
4. Payment collected at delivery

---

## 🧪 Testing Guide

### Quick Test Checklist

- [ ] **SafePay (Card):** Test with `4111111111111111`
- [ ] **JazzCash:** Test with phone `03001234567`
- [ ] **easyPaisa:** Test with phone `03009999999`
- [ ] **COD:** Complete order without payment
- [ ] **Insufficient Balance:** Test with `03005555555` (JazzCash) or `03007777777` (easyPaisa)

### Testing Each Payment Method

#### 1. SafePay Card Payment
```bash
1. Add items to cart
2. Go to checkout
3. Select "Credit Card"
4. Complete address form
5. Use test card: 4111111111111111
6. Payment succeeds → Order confirmed ✅
```

#### 2. JazzCash Payment (Pending Status)
```bash
1. Add items to cart
2. Go to checkout
3. Select "JazzCash"
4. Enter phone: 03001234567
5. Complete order → Status: "pending" ⏳
6. Admin verifies in JazzCash dashboard
7. Order marked as paid ✅
```

#### 3. easyPaisa Payment (Pending Status)
```bash
1. Add items to cart
2. Go to checkout
3. Select "easyPaisa"
4. Enter phone: 03009999999
5. Complete order → Status: "pending" ⏳
6. Admin verifies in easyPaisa dashboard
7. Order marked as paid ✅
```

#### 4. Cash on Delivery
```bash
1. Add items to cart
2. Go to checkout
3. Select "Cash on Delivery"
4. Complete address form
5. Place order → Order confirmed ✅
```

---

## 📋 Order Status Tracking

### Order Payment Statuses

```
"pending"   → Awaiting payment verification (JazzCash/easyPaisa)
"captured"  → Payment received (SafePay/Verified wallet)
"failed"    → Payment failed
"cancelled" → Order cancelled
```

### Order Statuses

```
"pending"      → Order created, awaiting payment
"processing"   → Payment received, preparing shipment
"shipped"      → Order shipped
"delivered"    → Delivered to customer
"cancelled"    → Order cancelled
"returned"     → Return initiated/completed
```

---

## 🔐 Security Notes

- ⚠️ **Never commit real credentials to git**
- ⚠️ **Use environment variables** for sensitive data
- ⚠️ **Test credentials only in development**
- ⚠️ **Production:** Use real merchant IDs from actual accounts
- ⚠️ **Never hardcode credentials** in Flutter code

---

## 📞 Support Links

| Service | Documentation | Sandbox |
|---------|---|---|
| **SafePay** | https://safepay.com.pk/docs | https://sandbox.api.getsafepay.com |
| **JazzCash** | https://jazzcash.com.pk/developers | https://sandbox.jazzcash.com.pk |
| **easyPaisa** | https://easypaisa.com.pk/developers | Check portal |

---

## 🚀 Next Steps

1. ✅ Update backend to support `paymentStatus: "pending"` for wallet orders
2. ✅ Update Flutter checkout UI to show pending verification screen
3. ⏳ Implement JazzCash API integration (future)
4. ⏳ Implement easyPaisa API integration (future)
5. ⏳ Add admin panel to verify/mark wallet payments as paid

---

**Last Updated:** June 16, 2026
**Status:** Active (Safe Mode - Manual Verification)
