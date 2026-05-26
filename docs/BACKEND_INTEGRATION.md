# Backend Integration Guide

## ✅ Integration Complete!

Your Flutter app is now fully integrated with the NestJS backend API.

## 📋 What's Been Integrated

1. **Authentication**
   - ✅ Sign In (Login)
   - ✅ Sign Up (Registration)
   - ✅ JWT Token Storage
   - ✅ Auto-logout on token expiration

2. **Products**
   - ✅ Fetch products from API
   - ✅ Category filtering
   - ✅ Search functionality
   - ✅ Add to cart

3. **Orders**
   - ✅ Create orders via API
   - ✅ Order validation
   - ✅ Stock management

## 🔧 Configuration

### API Base URL

The API base URL is configured in `lib/services/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### For Real Device Testing

When testing on a real device (like your iPhone 14 Pro), you need to:

1. **Find your computer's IP address:**
   ```bash
   # On macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Or use
   ipconfig getifaddr en0
   ```

2. **Update the API base URL** in `lib/services/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP_ADDRESS:3000/api';
   // Example: 'http://192.168.1.100:3000/api'
   ```

3. **Make sure your backend is running:**
   ```bash
   cd prestige-men-backend
   npm run start:dev
   ```

4. **Ensure both devices are on the same network**

## 🚀 Running the Backend

1. Navigate to backend directory:
   ```bash
   cd prestige-men-backend
   ```

2. Create `.env` file (copy from `.env.example`):
   ```bash
   cp .env.example .env
   ```

3. Update `.env` with your MongoDB connection:
   ```env
   MONGODB_URI=mongodb://localhost:27017/prestige-men
   JWT_SECRET=your-secret-key-here
   ```

4. Start MongoDB (if local):
   ```bash
   mongod
   ```

5. Start the backend:
   ```bash
   npm run start:dev
   ```

The API will be available at `http://localhost:3000/api`

## 📱 Testing the Integration

### 1. Test Authentication
- Open the app
- Try to sign up with a new account
- Try to sign in with existing credentials

### 2. Test Products
- Navigate to Products page
- Products should load from the backend
- If no products, you need to add some via the backend API

### 3. Test Orders
- Add items to cart
- Go to checkout
- Fill in shipping details
- Place order

## 🗄️ Adding Products to Database

You can add products via:

1. **API Request** (using Postman or curl):
   ```bash
   curl -X POST http://localhost:3000/api/products \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -d '{
       "name": "Rolex Watch",
       "description": "Elegant timepiece",
       "price": 299.99,
       "category": "watches",
       "stock": 10,
       "images": ["assets/images/watch-rolex.webp"]
     }'
   ```

2. **Or create a seed script** in the backend to populate initial data

## 🔍 Troubleshooting

### "Connection refused" error
- Make sure backend is running
- Check if the IP address is correct
- Verify both devices are on the same network

### "401 Unauthorized" error
- User needs to login first
- Token might be expired - try logging in again

### Products not loading
- Check if backend has products in database
- Verify API endpoint is accessible
- Check network connectivity

### Order creation fails
- Make sure user is logged in
- Verify product IDs exist in cart items
- Check stock availability

## 📝 Next Steps

1. **Add product images** - Update product images to use URLs or implement image upload
2. **Add product seeding** - Create initial products in database
3. **Add order history** - Display user's past orders
4. **Add product details page** - Show full product information
5. **Add search functionality** - Implement search in products page

## 🎉 You're All Set!

Your Flutter app is now connected to the backend. Happy coding!

