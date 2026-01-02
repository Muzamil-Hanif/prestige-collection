import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;
  final Function() onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.totalPrice,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  
  String _selectedPaymentMethod = 'Credit Card';
  final double _shippingCost = 10.00;
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  double get _grandTotal => widget.totalPrice + _shippingCost;

  void _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isPlacingOrder = true;
      });

      try {
        // Prepare order items for API
        final orderItems = widget.cartItems.map((item) {
          // Ensure productId exists - if not, we'll need to handle this
          final productId = item['id'] ?? item['productId'] ?? '';
          if (productId.isEmpty) {
            throw Exception('Product ID missing for item: ${item['name']}');
          }
          return {
            'productId': productId,
            'name': item['name'] as String,
            'price': item['price'] as double,
            'quantity': item['quantity'] as int,
            'image': item['image'] ?? '',
          };
        }).toList();

        // Prepare shipping address
        final shippingAddress = {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'street': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'zipCode': _zipController.text.trim(),
        };

        // Call API to create order
        await ApiService.createOrder(
          items: orderItems,
          totalPrice: widget.totalPrice,
          shippingCost: _shippingCost,
          grandTotal: _grandTotal,
          shippingAddress: shippingAddress,
          paymentMethod: _selectedPaymentMethod,
        );

        if (mounted) {
          setState(() {
            _isPlacingOrder = false;
          });

          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text(
                'Order Placed!',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Thank you for your purchase. Your order has been placed successfully.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    widget.onOrderPlaced(); // Clear cart
                    Navigator.pop(context); // Go back to cart
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isPlacingOrder = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to place order: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping Address Section
              _buildSectionHeader('Shipping Address', Icons.location_on),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Street Address',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'City',
                                prefixIcon: const Icon(Icons.location_city),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter city';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _zipController,
                              decoration: InputDecoration(
                                labelText: 'ZIP Code',
                                prefixIcon: const Icon(Icons.pin),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter ZIP';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method Section
              _buildSectionHeader('Payment Method', Icons.payment),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Credit Card'),
                      subtitle: const Text('Visa, Mastercard, Amex'),
                      value: 'Credit Card',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      activeColor: cs.secondary,
                    ),
                    RadioListTile<String>(
                      title: const Text('Debit Card'),
                      subtitle: const Text('Visa, Mastercard'),
                      value: 'Debit Card',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      activeColor: cs.secondary,
                    ),
                    RadioListTile<String>(
                      title: const Text('PayPal'),
                      subtitle: const Text('Pay with PayPal account'),
                      value: 'PayPal',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      activeColor: cs.secondary,
                    ),
                    RadioListTile<String>(
                      title: const Text('Cash on Delivery'),
                      subtitle: const Text('Pay when you receive'),
                      value: 'Cash on Delivery',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      activeColor: cs.secondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order Summary Section
              _buildSectionHeader('Order Summary', Icons.receipt),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${item['quantity']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.secondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      _buildSummaryRow('Subtotal', '\$${widget.totalPrice.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Shipping', '\$${_shippingCost.toStringAsFixed(2)}'),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_grandTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

