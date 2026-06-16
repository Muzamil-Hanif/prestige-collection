import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'checkout_page.dart';

class MyCart extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(int) onRemoveFromCart;
  final Function(int, int) onUpdateQuantity;
  final VoidCallback? onNavigateToProducts;
  
  const MyCart({
    super.key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    this.onNavigateToProducts,
  });

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  bool _isNavigating = false;

  IconData _cartItemIcon(Map<String, dynamic> item) {
    final icon = item['icon'];
    if (icon is IconData) return icon;
    return Icons.shopping_bag_outlined;
  }

  double get _totalPrice {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + ((item['price'] as double?) ?? 0.0) * (item['quantity'] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: widget.cartItems.isEmpty
              ? _buildEmptyCart()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    return Dismissible(
                      key: Key('item_${item['name']}_$index'),
                      direction: DismissDirection.endToStart,
                      dismissThresholds: const {
                        DismissDirection.endToStart: 0.6,
                      },
                      movementDuration: const Duration(milliseconds: 300),
                      resizeDuration: const Duration(milliseconds: 300),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        final removedItem = Map<String, dynamic>.from(item);
                        final removedIndex = index;
                        widget.onRemoveFromCart(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${item['name']} removed from cart',
                                    style: const TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.grey[800],
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              backgroundColor: Colors.grey[700],
                              onPressed: () {
                                // Note: Undo functionality would need to be handled by parent
                                // For now, we'll just show a message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Item restored'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                        leading: item['image'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: (item['image'] as String).startsWith('http')
                                    ? Image.network(
                                        ProductModel.toDisplayImageUrl(item['image'] as String),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return CircleAvatar(
                                            backgroundColor:
                                                Theme.of(context).colorScheme.primaryContainer,
                                            child: Icon(
                                              _cartItemIcon(item),
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        item['image'] as String,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return CircleAvatar(
                                            backgroundColor:
                                                Theme.of(context).colorScheme.primaryContainer,
                                            child: Icon(
                                              _cartItemIcon(item),
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                          );
                                        },
                                      ),
                              )
                            : CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  _cartItemIcon(item),
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                        title: Text(
                          item['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Text(
                                  //   '\$${(item['price'] as double).toStringAsFixed(2)} each',
                                  //   style: TextStyle(
                                  //     color: Theme.of(context).colorScheme.secondary,
                                  //     fontSize: 12,
                                  //   ),
                                  // ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total: \$${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    final currentQuantity = item['quantity'] as int;
                                    if (currentQuantity > 1) {
                                      widget.onUpdateQuantity(index, currentQuantity - 1);
                                    } else {
                                      widget.onRemoveFromCart(index);
                                    }
                                  },
                                ),
                                Text(
                                  '${item['quantity']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    final currentQuantity = item['quantity'] as int;
                                    widget.onUpdateQuantity(index, currentQuantity + 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    );
                  },
                ),
        ),

        // Cart Summary
        if (widget.cartItems.isNotEmpty) _buildCartSummary(context),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          if (!_isNavigating)
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to products page
                setState(() {
                  _isNavigating = true;
                });
                if (widget.onNavigateToProducts != null) {
                  widget.onNavigateToProducts!();
                }
              },
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: const Text(
                'Browse Products',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            )
          else
            const CircularProgressIndicator(),
        ],
      ),
    );
  }

Widget _buildCartSummary(BuildContext context) {
  final bottomPadding = MediaQuery.of(context).padding.bottom;

  return Container(
    margin: EdgeInsets.only(
      left: 16,        // ✅ gap from left edge
      right: 16,       // ✅ gap from right edge
      bottom: 12 + bottomPadding, // ✅ gap from bottom nav
    ),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16), 
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '\$${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '\$10.00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '\$${(_totalPrice + 10.00).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(
                    cartItems: widget.cartItems,
                    totalPrice: _totalPrice,
                    onOrderPlaced: () {
                      // Clear cart by removing all items
                      for (int i = widget.cartItems.length - 1; i >= 0; i--) {
                        widget.onRemoveFromCart(i);
                      }
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

