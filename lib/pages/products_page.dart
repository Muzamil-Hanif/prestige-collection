import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

class ProductsPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback? onNavigateToCart;
  
  const ProductsPage({super.key, required this.onAddToCart, this.onNavigateToCart});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: const Duration(milliseconds: 200),
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ApiService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            labelColor: cs.secondary,
            unselectedLabelColor: cs.primary,
            indicatorColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Perfumes', icon: Icon(Icons.spa)),
              Tab(text: 'Watches', icon: Icon(Icons.watch)),
              Tab(text: 'Wallets', icon: Icon(Icons.account_balance_wallet)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(context, 'Perfumes', Icons.spa, Colors.purple),
              _buildProductList(context, 'Watches', Icons.watch, Colors.blue),
              _buildProductList(context, 'Wallets', Icons.account_balance_wallet, Colors.brown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(
    BuildContext context,
    String category,
    IconData icon,
    Color color,
  ) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading products',
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter products by category
    final categoryMap = {
      'Perfumes': 'perfumes',
      'Watches': 'watches',
      'Wallets': 'wallets',
    };
    
    final categoryLower = categoryMap[category] ?? category.toLowerCase();
    final products = _allProducts.where((p) {
      return p.category.toLowerCase() == categoryLower || 
             p.name.toLowerCase().contains(categoryLower);
    }).toList();

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          // Convert ProductModel to Map for cart
          final productMap = {
            'id': product.id,
            'name': product.name,
            'description': product.description ?? '',
            'price': product.price,
            'image': product.imageUrl.isNotEmpty ? product.imageUrl : null,
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Try asset image if network fails
                                if (product.imageUrl.startsWith('assets/')) {
                                  return Image.asset(
                                    product.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(icon, size: 40, color: Theme.of(context).colorScheme.secondary);
                                    },
                                  );
                                }
                                return Icon(icon, size: 40, color: Theme.of(context).colorScheme.secondary);
                              },
                            ),
                          )
                        : Icon(icon, size: 40, color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description ?? 'No description',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.formattedPrice,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: product.isAvailable && product.stock > 0
                                  ? () {
                                      widget.onAddToCart(productMap);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Expanded(
                                                child: Text('Added ${product.name} to cart'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  if (widget.onNavigateToCart != null) {
                                                    widget.onNavigateToCart!();
                                                  }
                                                },
                                                child: const Text(
                                                  'View Cart',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 30),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              child: Text(product.isAvailable && product.stock > 0 ? 'Add to Cart' : 'Out of Stock'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}

