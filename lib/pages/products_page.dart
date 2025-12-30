import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
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
              children: [
                _buildProductList(context, 'Perfumes', Icons.spa, Colors.purple),
                _buildProductList(context, 'Watches', Icons.watch, Colors.blue),
                _buildProductList(context, 'Wallets', Icons.account_balance_wallet, Colors.brown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(
    BuildContext context,
    String category,
    IconData icon,
    Color color,
  ) {
    final products = _getProductsForCategory(category);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
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
                  child: product['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            product['image'] as String,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
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
                        product['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['description'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product['price'] as String,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${product['name']} to cart'),
                                  action: SnackBarAction(
                                    label: 'View Cart',
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 30),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Add to Cart'),
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
    );
  }

  List<Map<String, dynamic>> _getProductsForCategory(String category) {
    switch (category) {
      case 'Perfumes':
        return [
           {
            'name': 'Dolce & Gabbana Fragrance',
            'description': 'Refreshing citrus scent',
            'price': '\$69.99',
            'image': 'assets/images/perfume-d&g2.jpeg',
          },
          {
            'name': 'Dolce & Gabbana Fragrance',
            'description': 'Luxury fragrance with woody notes',
            'price': '\$89.99',
            'image': 'assets/images/perfume-d&g1.jpeg',
          },
        
          {
            'name': 'Dolce & Gabbana Fragrance',
            'description': 'The One',
            'price': '\$129.99',
            'image': 'assets/images/perfume-d&g3.jpeg',
          },
          {
            'name': 'Dolce & Gabbana Fragrance',
            'description': 'Energetic and dynamic',
            'price': '\$59.99',
            'image': 'assets/images/perfume-d&g4.jpeg',
          },
        ];
      case 'Watches':
        return [
          {
            'name': 'Rolex Watch',
            'description': 'Elegant timepiece silver chain strap',
            'price': '\$299.99',
            'image': 'assets/images/watch-rolex.webp',
          },
          {
            'name': 'Rado Watch',
            'description': 'Modern digital display with green dial',
            'price': '\$199.99',
            'image': 'assets/images/watch-rado2.jpeg',
          },
          {
            'name': 'Luxury Gold Watch',
            'description': 'Premium gold-plated watch',
            'price': '\$599.99',
            'image': 'assets/images/watch-rado1.jpeg',
          },
          {
            'name': 'Minimalist Watch',
            'description': 'Sleek and simple design',
            'price': '\$149.99',
             'image': 'assets/images/watch-rado3.jpeg',

          },
         
        ];
      case 'Wallets':
        return [
          {
            'name': 'larentou Wallet',
            'description': 'Classic design',
            'price': '\$169.99',
            'image': 'assets/images/wallet-laorentou.jpg',
          },
          {
            'name': 'Leather Bifold Wallet',
            'description': 'Premium genuine leather',
            'price': '\$79.99',
            'image': 'assets/images/wallet-leather-bifold.jpeg',
          },
           {
            'name': 'Travel Wallet',
            'description': 'Multi-pocket travel wallet',
            'price': '\$99.99',
            'image': 'assets/images/wallet-travel.jpeg',
          },
          {
            'name': 'Slim Card Holder',
            'description': 'Minimalist card wallet',
            'price': '\$49.99',
            'image': 'assets/images/wallet-card-holder.jpeg',
          },
         
          {
            'name': 'Money Clip Wallet',
            'description': 'Classic money clip design',
            'price': '\$69.99',
            'image': 'assets/images/wallet-money-clip.jpeg',
          },
          
        ];
      default:
        return [];
    }
  }
}

