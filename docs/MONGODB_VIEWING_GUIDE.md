# How to View MongoDB Records

There are several ways to view and manage your MongoDB data. Here are the most common methods:

## Method 1: MongoDB Compass (Recommended - GUI Tool)

MongoDB Compass is the official GUI tool for MongoDB. It's the easiest way to view and manage your data.

### Installation:
1. Download MongoDB Compass from: https://www.mongodb.com/try/download/compass
2. Install it on your Mac

### Connection:
1. Open MongoDB Compass
2. Use the connection string: `mongodb://localhost:27017`
3. Click "Connect"
4. You'll see your databases on the left sidebar
5. Click on `prestige-men` database
6. You'll see collections: `users`, `products`, `orders`
7. Click on any collection to view the records

### Features:
- View all documents in a collection
- Filter and search documents
- Edit documents directly
- Add/Delete documents
- View indexes

---

## Method 2: MongoDB Shell (mongosh) - Command Line

If you prefer command line, use `mongosh` (MongoDB Shell).

### Installation:
```bash
# Install via Homebrew (if not already installed)
brew install mongosh
```

### Connect and View Data:

```bash
# Connect to MongoDB
mongosh

# Or connect directly to your database
mongosh mongodb://localhost:27017/prestige-men
```

### Useful Commands:

```javascript
// Show all databases
show dbs

// Use your database
use prestige-men

// Show all collections
show collections

// View all users
db.users.find().pretty()

// View all products
db.products.find().pretty()

// View all orders
db.orders.find().pretty()

// Count documents
db.users.countDocuments()
db.products.countDocuments()
db.orders.countDocuments()

// Find specific user by email
db.users.find({ email: "user@example.com" }).pretty()

// Find products by category
db.products.find({ category: "watches" }).pretty()

// Find orders by status
db.orders.find({ status: "pending" }).pretty()

// View with limit
db.products.find().limit(5).pretty()

// Sort by price (ascending)
db.products.find().sort({ price: 1 }).pretty()

// Sort by price (descending)
db.products.find().sort({ price: -1 }).pretty()
```

---

## Method 3: VS Code Extension

If you use VS Code, you can install the MongoDB extension.

### Installation:
1. Open VS Code
2. Go to Extensions (Cmd+Shift+X)
3. Search for "MongoDB for VS Code"
4. Install it

### Usage:
1. Click on the MongoDB icon in the sidebar
2. Add connection: `mongodb://localhost:27017`
3. Browse databases and collections
4. View and edit documents

---

## Method 4: Create a Simple Admin Route in Backend

You can create a simple admin endpoint to view data via API.

### Add to your backend:

Create `src/admin/admin.controller.ts`:
```typescript
import { Controller, Get, UseGuards } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../users/schemas/user.schema';
import { Product } from '../products/schemas/product.schema';
import { Order } from '../orders/schemas/order.schema';

@Controller('admin')
export class AdminController {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(Product.name) private productModel: Model<Product>,
    @InjectModel(Order.name) private orderModel: Model<Order>,
  ) {}

  @Get('stats')
  async getStats() {
    const [usersCount, productsCount, ordersCount] = await Promise.all([
      this.userModel.countDocuments(),
      this.productModel.countDocuments(),
      this.orderModel.countDocuments(),
    ]);

    return {
      users: usersCount,
      products: productsCount,
      orders: ordersCount,
    };
  }

  @Get('users')
  async getUsers() {
    return this.userModel.find().select('-password').exec();
  }

  @Get('products')
  async getProducts() {
    return this.productModel.find().exec();
  }

  @Get('orders')
  async getOrders() {
    return this.orderModel.find().populate('userId', 'email fullName').exec();
  }
}
```

Then access via: `http://localhost:3000/api/admin/stats`

---

## Quick Start Commands

### Using mongosh (Quickest for command line):

```bash
# Connect
mongosh mongodb://localhost:27017/prestige-men

# Then run these commands:
db.users.find().pretty()
db.products.find().pretty()
db.orders.find().pretty()
```

### Using MongoDB Compass:
1. Open Compass
2. Connect to `mongodb://localhost:27017`
3. Click on `prestige-men` database
4. Click on any collection to view records

---

## Troubleshooting

### "Connection refused" error:
- Make sure MongoDB is running: `mongod`
- Check if MongoDB is on port 27017: `lsof -i :27017`

### "Database not found":
- The database will be created automatically when you insert the first document
- If empty, create it manually or add a document via your app

### View specific fields only:
```javascript
// Only show name and email
db.users.find({}, { name: 1, email: 1, _id: 0 }).pretty()
```

---

## Recommended: MongoDB Compass

For beginners, **MongoDB Compass** is the best option because:
- ✅ Visual interface
- ✅ Easy to navigate
- ✅ Can edit data directly
- ✅ No command line needed
- ✅ Free and official tool

Download: https://www.mongodb.com/try/download/compass

