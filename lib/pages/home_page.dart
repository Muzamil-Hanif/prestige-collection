import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'my_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<int> _homeCategoryCodes = [1, 2, 3, 4];
  static const Map<int, String> _homeCategoryApiValues = {
    1: 'perfumes',
    2: 'watches',
    3: 'wallets',
    4: 'shirts',
  };

  final Set<String> _favoriteProductIds = <String>{};
  final PageController _bannerController = PageController(viewportFraction: 0.94);

  Timer? _bannerTimer;
  int _bannerIndex = 0;
  bool _showGridCards = false;
  bool _isLoading = true;
  bool _isProfileLoading = true;
  String? _errorMessage;
  UserModel? _profile;

  final Map<int, ProductModel?> _featuredByCategory = {};
  final List<Map<String, dynamic>> _promoBanners = const [
    {
      'title': 'Luxury Picks This Week',
      'subtitle': 'Discover premium collections for every style.',
      'icon': Icons.auto_awesome_rounded,
      'start': Color(0xFF1F2A44),
      'end': Color(0xFF2A3D66),
    },
    {
      'title': 'Fresh Drops in Perfumes',
      'subtitle': 'Signature fragrances curated for Prestige Collection.',
      'icon': Icons.spa_rounded,
      'start': Color(0xFF23395B),
      'end': Color(0xFF3A5A8F),
    },
    {
      'title': 'Style Upgrade Essentials',
      'subtitle': 'Watches, wallets, shirts and more in one place.',
      'icon': Icons.shopping_bag_rounded,
      'start': Color(0xFF0F2A43),
      'end': Color(0xFF1A4669),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFeaturedProducts();
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isProfileLoading = true);
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait(
        _homeCategoryCodes.map(
          (code) => ApiService.getProducts(category: _homeCategoryApiValues[code], limit: 1),
        ),
      );

      final mapped = <int, ProductModel?>{};
      for (var i = 0; i < _homeCategoryCodes.length; i++) {
        mapped[_homeCategoryCodes[i]] = responses[i].isNotEmpty ? responses[i].first : null;
      }

      if (!mounted) return;
      setState(() {
        _featuredByCategory
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextIndex = (_bannerIndex + 1) % _promoBanners.length;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });
  }

  IconData _iconForCategory(int code) {
    switch (code) {
      case 1:
        return Icons.spa;
      case 2:
        return Icons.watch;
      case 3:
        return Icons.account_balance_wallet;
      case 4:
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  Widget _buildProductImage(ProductModel product, IconData fallbackIcon, {BoxFit fit = BoxFit.cover}) {
    if (product.imageUrl.isEmpty) {
      return Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500));
    }

    if (product.hasNetworkImage) {
      return Image.network(
        product.displayImageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500)),
      );
    }

    return Image.asset(
      product.imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) =>
          Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500)),
    );
  }

  Widget _buildPromoSlider() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _promoBanners.length,
            onPageChanged: (index) => setState(() => _bannerIndex = index),
            itemBuilder: (context, index) {
              final banner = _promoBanners[index];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use bottom navigation -> Products')),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [banner['start'] as Color, banner['end'] as Color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['subtitle'] as String,
                              style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          banner['icon'] as IconData,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: _bannerIndex == index ? 24 : 7,
              decoration: BoxDecoration(
                color: _bannerIndex == index ? const Color(0xFF1F2A44) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedListCard(int code) {
    final product = _featuredByCategory[code];
    final label = ProductModel.categoryLabels[code] ?? 'Category';
    final icon = _iconForCategory(code);
    final isFavorite = product != null && _favoriteProductIds.contains(product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: product == null
                ? Icon(icon, color: const Color(0xFF1F2A44), size: 30)
                : ClipOval(child: _buildProductImage(product, icon)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '$label products coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product == null ? '' : product.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFF9B62D) : Colors.white,
                ),
                onPressed: product == null ? null : () => _toggleFavorite(product.id),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGridCard(int code) {
    final product = _featuredByCategory[code];
    final label = ProductModel.categoryLabels[code] ?? 'Category';
    final icon = _iconForCategory(code);
    final isFavorite = product != null && _favoriteProductIds.contains(product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: product == null
                        ? Center(child: Icon(icon, size: 56, color: Colors.grey.shade500))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _buildProductImage(product, icon, fit: BoxFit.contain),
                          ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: product == null ? null : () => _toggleFavorite(product.id),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.red : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '$label products coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product == null ? 'No active item' : product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeaturedProducts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello, Welcome',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.fullName ?? (_isProfileLoading ? 'Loading...' : 'Guest'),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyProfilePage()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF1F2937),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPromoSlider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured by category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                _showGridCards ? const Color(0xFF1F2A44) : Colors.transparent,
                          ),
                          onPressed: () => setState(() => _showGridCards = true),
                          icon: Icon(
                            Icons.grid_view_rounded,
                            color: _showGridCards ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                !_showGridCards ? const Color(0xFF1F2A44) : Colors.transparent,
                          ),
                          onPressed: () => setState(() => _showGridCards = false),
                          icon: Icon(
                            Icons.view_list_rounded,
                            color: !_showGridCards ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadFeaturedProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                _showGridCards
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _homeCategoryCodes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.58,
                        ),
                        itemBuilder: (context, index) =>
                            _buildFeaturedGridCard(_homeCategoryCodes[index]),
                      )
                    : Column(
                        children: _homeCategoryCodes
                            .map((code) => _buildFeaturedListCard(code))
                            .toList(),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'my_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<int> _homeCategoryCodes = [1, 2, 3, 4];
  static const Map<int, String> _homeCategoryApiValues = {
    1: 'perfumes',
    2: 'watches',
    3: 'wallets',
    4: 'shirts',
  };

  final Set<String> _favoriteProductIds = <String>{};
  final PageController _bannerController = PageController(viewportFraction: 0.94);

  Timer? _bannerTimer;
  int _bannerIndex = 0;
  bool _showGridCards = false;
  bool _isLoading = true;
  bool _isProfileLoading = true;
  String? _errorMessage;
  UserModel? _profile;

  final Map<int, ProductModel?> _featuredByCategory = {};
  final List<Map<String, dynamic>> _promoBanners = const [
    {
      'title': 'Luxury Picks This Week',
      'subtitle': 'Discover premium collections for every style.',
      'icon': Icons.auto_awesome_rounded,
      'start': Color(0xFF1F2A44),
      'end': Color(0xFF2A3D66),
    },
    {
      'title': 'Fresh Drops in Perfumes',
      'subtitle': 'Signature fragrances curated for Prestige Collection.',
      'icon': Icons.spa_rounded,
      'start': Color(0xFF23395B),
      'end': Color(0xFF3A5A8F),
    },
    {
      'title': 'Style Upgrade Essentials',
      'subtitle': 'Watches, wallets, shirts and more in one place.',
      'icon': Icons.shopping_bag_rounded,
      'start': Color(0xFF0F2A43),
      'end': Color(0xFF1A4669),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFeaturedProducts();
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isProfileLoading = true);
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait(
        _homeCategoryCodes.map(
          (code) => ApiService.getProducts(category: _homeCategoryApiValues[code], limit: 1),
        ),
      );

      final mapped = <int, ProductModel?>{};
      for (var i = 0; i < _homeCategoryCodes.length; i++) {
        mapped[_homeCategoryCodes[i]] = responses[i].isNotEmpty ? responses[i].first : null;
      }

      if (!mounted) return;
      setState(() {
        _featuredByCategory
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextIndex = (_bannerIndex + 1) % _promoBanners.length;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });
  }

  IconData _iconForCategory(int code) {
    switch (code) {
      case 1:
        return Icons.spa;
      case 2:
        return Icons.watch;
      case 3:
        return Icons.account_balance_wallet;
      case 4:
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  Widget _buildProductImage(ProductModel product, IconData fallbackIcon, {BoxFit fit = BoxFit.cover}) {
    if (product.imageUrl.isEmpty) {
      return Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500));
    }

    if (product.hasNetworkImage) {
      return Image.network(
        product.displayImageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500)),
      );
    }

    return Image.asset(
      product.imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) =>
          Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500)),
    );
  }

  Widget _buildPromoSlider() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _promoBanners.length,
            onPageChanged: (index) => setState(() => _bannerIndex = index),
            itemBuilder: (context, index) {
              final banner = _promoBanners[index];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use bottom navigation -> Products')),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [banner['start'] as Color, banner['end'] as Color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['subtitle'] as String,
                              style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          banner['icon'] as IconData,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: _bannerIndex == index ? 24 : 7,
              decoration: BoxDecoration(
                color: _bannerIndex == index ? const Color(0xFF1F2A44) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedListCard(int code) {
    final product = _featuredByCategory[code];
    final label = ProductModel.categoryLabels[code] ?? 'Category';
    final icon = _iconForCategory(code);
    final isFavorite = product != null && _favoriteProductIds.contains(product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: product == null
                ? Icon(icon, color: const Color(0xFF1F2A44), size: 30)
                : ClipOval(child: _buildProductImage(product, icon)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '$label products coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product == null ? '' : product.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFF9B62D) : Colors.white,
                ),
                onPressed: product == null ? null : () => _toggleFavorite(product.id),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGridCard(int code) {
    final product = _featuredByCategory[code];
    final label = ProductModel.categoryLabels[code] ?? 'Category';
    final icon = _iconForCategory(code);
    final isFavorite = product != null && _favoriteProductIds.contains(product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: product == null
                        ? Center(child: Icon(icon, size: 56, color: Colors.grey.shade500))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _buildProductImage(product, icon, fit: BoxFit.contain),
                          ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: product == null ? null : () => _toggleFavorite(product.id),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.red : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '$label products coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product == null ? 'No active item' : product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeaturedProducts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello, Welcome',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.fullName ?? (_isProfileLoading ? 'Loading...' : 'Guest'),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyProfilePage()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF1F2937),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPromoSlider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured by category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                _showGridCards ? const Color(0xFF1F2A44) : Colors.transparent,
                          ),
                          onPressed: () => setState(() => _showGridCards = true),
                          icon: Icon(
                            Icons.grid_view_rounded,
                            color: _showGridCards ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                !_showGridCards ? const Color(0xFF1F2A44) : Colors.transparent,
                          ),
                          onPressed: () => setState(() => _showGridCards = false),
                          icon: Icon(
                            Icons.view_list_rounded,
                            color: !_showGridCards ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadFeaturedProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                _showGridCards
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _homeCategoryCodes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.58,
                        ),
                        itemBuilder: (context, index) =>
                            _buildFeaturedGridCard(_homeCategoryCodes[index]),
                      )
                    : Column(
                        children: _homeCategoryCodes
                            .map((code) => _buildFeaturedListCard(code))
                            .toList(),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'my_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<int> _homeCategoryCodes = [1, 2, 3, 4];
  static const Map<int, String> _homeCategoryApiValues = {
    1: 'perfumes',
    2: 'watches',
    3: 'wallets',
    4: 'shirts',
  };

  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, ProductModel?> _featuredByCategory = {};
  final Set<String> _favoriteProductIds = <String>{};
  bool _showGridCards = true;

  bool _isProfileLoading = true;
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFeaturedProducts();
  }

  Future<void> _loadProfile() async {
    setState(() => _isProfileLoading = true);
    try {
      final profile = await ApiService.getProfile();
      setState(() {
        _profile = profile;
        _isProfileLoading = false;
      });
    } catch (_) {
      setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait(
        _homeCategoryCodes.map(
          (code) => ApiService.getProducts(category: _homeCategoryApiValues[code], limit: 1),
        ),
      );

      final mapped = <int, ProductModel?>{};
      for (var i = 0; i < _homeCategoryCodes.length; i++) {
        mapped[_homeCategoryCodes[i]] = responses[i].isNotEmpty ? responses[i].first : null;
      }

      setState(() {
        _featuredByCategory
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  IconData _iconForCategory(int code) {
    switch (code) {
      case 1:
        return Icons.spa;
      case 2:
        return Icons.watch;
      case 3:
        return Icons.account_balance_wallet;
      case 4:
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  Widget _buildProductImage(ProductModel product, IconData fallbackIcon) {
    if (product.imageUrl.isEmpty) {
      return Icon(fallbackIcon, size: 44, color: Colors.grey.shade500);
    }

    if (product.hasNetworkImage) {
      return Image.network(
        product.displayImageUrl,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: 44, color: Colors.grey.shade500),
      );
    }

    return Image.asset(
      product.imageUrl,
      width: 68,
      height: 68,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: 44, color: Colors.grey.shade500),
    );
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });
  }

  Widget _buildGridProductImage(ProductModel product, IconData fallbackIcon) {
    if (product.imageUrl.isEmpty) {
      return Center(child: Icon(fallbackIcon, size: 56, color: Colors.grey.shade500));
    }
    if (product.hasNetworkImage) {
      return Image.network(
        product.displayImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            Center(child: Icon(fallbackIcon, size: 56, color: Colors.grey.shade500)),
      );
    }
    return Image.asset(
      product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          Center(child: Icon(fallbackIcon, size: 56, color: Colors.grey.shade500)),
    );
  }

  Widget _buildFeaturedListCard(int code) {
    final product = _featuredByCategory[code];
    final label = ProductModel.categoryLabels[code] ?? 'Category';
    final icon = _iconForCategory(code);
    final isFavorite = product != null && _favoriteProductIds.contains(product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: product == null
                ? Icon(icon, color: const Color(0xFF1F2A44), size: 30)
                : ClipOval(child: _buildProductImage(product, icon)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '$label products coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product == null ? '' : product.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFF9B62D) : Colors.white,
                ),
                onPressed: product == null ? null : () => _toggleFavorite(product.id),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGridCard(int code) {
    final product = _featuredByCategory[code];
    final label = ProductModel.categoryLabels[code] ?? 'Category';
    final icon = _iconForCategory(code);
    final isFavorite = product != null && _favoriteProductIds.contains(product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: product == null
                      ? Center(child: Icon(icon, size: 56, color: Colors.grey.shade500))
                      : ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          child: _buildGridProductImage(product, icon),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: product == null ? null : () => _toggleFavorite(product.id),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.red : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? '$label products coming soon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product == null ? 'No active item' : product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeaturedProducts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello, Welcome',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.fullName ?? (_isProfileLoading ? 'Loading...' : 'Guest'),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyProfilePage()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF1F2937),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: const Text('Browse all products',                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6B7280),),
)
                subtitle: const Text('Open full catalog in Products tab',                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6B7280),),
),

                 


                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use bottom navigation -> Products')),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured by category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6B7280),),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: _showGridCards
                                ? const Color(0xFF1F2A44)
                                : Colors.transparent,
                          ),
                          onPressed: () => setState(() => _showGridCards = true),
                          icon: Icon(
                            Icons.grid_view_rounded,
                            color: _showGridCards ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: !_showGridCards
                                ? const Color(0xFF1F2A44)
                                : Colors.transparent,
                          ),
                          onPressed: () => setState(() => _showGridCards = false),
                          icon: Icon(
                            Icons.view_list_rounded,
                            color: !_showGridCards ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadFeaturedProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                _showGridCards
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _homeCategoryCodes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, index) =>
                            _buildFeaturedGridCard(_homeCategoryCodes[index]),
                      )
                    : Column(
                        children: _homeCategoryCodes
                            .map((code) => _buildFeaturedListCard(code))
                            .toList(),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
