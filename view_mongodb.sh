#!/bin/bash

# Quick script to view MongoDB records
# Usage: ./view_mongodb.sh

echo "🔍 Connecting to MongoDB..."
echo ""

mongosh mongodb://localhost:27017/prestige-men --eval "
  print('📊 DATABASE STATISTICS');
  print('====================');
  print('');
  
  print('👥 USERS:');
  print('Total users: ' + db.users.countDocuments());
  db.users.find({}, {email: 1, fullName: 1, role: 1, _id: 0}).forEach(printjson);
  print('');
  
  print('🛍️  PRODUCTS:');
  print('Total products: ' + db.products.countDocuments());
  db.products.find({}, {name: 1, price: 1, category: 1, stock: 1, _id: 0}).forEach(printjson);
  print('');
  
  print('📦 ORDERS:');
  print('Total orders: ' + db.orders.countDocuments());
  db.orders.find({}, {status: 1, totalPrice: 1, grandTotal: 1, createdAt: 1, _id: 0}).limit(5).forEach(printjson);
  print('');
  
  print('✅ Done!');
"

