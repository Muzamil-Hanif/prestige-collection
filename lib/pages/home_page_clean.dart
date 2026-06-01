import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
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
      'subtitle': 'Signature fragrances curated for Prestige Men.',
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

  Timer? _bannerTimer;
  int _bannerIndex = 0;
  bool _showGridCards = false;
  bool _isLoading = true;
  bool _isProfileLoading = true;
  String? _errorMessage;
  UserModel? _profile;

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
          (code) => ApiService.getProducts(category: _homeCategoryApiValues[code], limit: 12),
        ),
      );

      final mapped = <int, ProductModel?>{};
      final missingCategoryCodes = <int>[];
      for (var i = 0; i < _homeCategoryCodes.length; i++) {
        final categoryCode = _homeCategoryCodes[i];
        final matched = _firstProductForCategory(responses[i], categoryCode);
        mapped[categoryCode] = matched;
        if (matched == null) {
          missingCategoryCodes.add(categoryCode);
        }
      }

      // Fallback: if backend category filter returns mixed data, enforce category client-side.
      if (missingCategoryCodes.isNotEmpty) {
        final allProducts = await ApiService.getProducts(limit: 100);
        for (final code in missingCategoryCodes) {
          mapped[code] = _firstProductForCategory(allProducts, code);
        }
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

  ProductModel? _firstProductForCategory(List<ProductModel> products, int categoryCode) {
    for (final product in products) {
      if (product.category == categoryCode) {
        return product;
      }
    }
    return null;
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
        product.imageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500)),
      );
    }
    return Image.asset(
      product.imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          Center(child: Icon(fallbackIcon, size: 44, color: Colors.grey.shade500)),
    );
  }

  Widget _buildHeaderAvatar() {
    final photoUrl = _profile?.profilePhoto?.trim() ?? '';
    final hasPhoto = photoUrl.isNotEmpty;

    if (!hasPhoto) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFF1F2937),
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    String normalized = photoUrl;
    if (normalized.startsWith('//')) {
      normalized = 'https:$normalized';
    } else if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final encodedUrl = Uri.encodeFull(normalized);

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF1F2937),
      child: ClipOval(
        child: photoUrl.startsWith('data:image')
            ? _buildHeaderDataUriImage(photoUrl)
            : Image.network(
                encodedUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildHeaderDataUriImage(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= value.length - 1) {
      return const Icon(Icons.person, color: Colors.white);
    }
    try {
      final bytes = base64Decode(value.substring(commaIndex + 1));
      return Image.memory(
        bytes,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, color: Colors.white),
      );
    } catch (_) {
      return const Icon(Icons.person, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isDesktop(context);
    final padding = isWeb ? 32.0 : 16.0;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeaturedProducts,
          child: ListView(
            padding: EdgeInsets.all(padding),
            children: [
              if (isWeb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hello, Welcome', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            _profile?.fullName ?? (_isProfileLoading ? 'Loading...' : 'Guest'),
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
                          if (!mounted) return;
                          _loadProfile();
                        },
                        child: _buildHeaderAvatar(),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hello, Welcome', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
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
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));
                          if (!mounted) return;
                          _loadProfile();
                        },
                        child: _buildHeaderAvatar(),
                      ),
                    ],
                  ),
                ),
              _buildPromoSlider(context),
              SizedBox(height: isWeb ? 32 : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured by category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                  ),
                  if (!isWeb) _buildViewSwitcher(),
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
                      ElevatedButton(onPressed: _loadFeaturedProducts, child: const Text('Retry')),
                    ],
                  ),
                )
              else if (isWeb)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _homeCategoryCodes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) => _buildFeaturedGridCard(_homeCategoryCodes[index]),
                )
              else if (_showGridCards)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _homeCategoryCodes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.gridColumns(context),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemBuilder: (context, index) => _buildFeaturedGridCard(_homeCategoryCodes[index]),
                )
              else
                Column(
                  children: _homeCategoryCodes.map((code) => _buildFeaturedListCard(code)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoSlider(BuildContext ctx) {
    return Column(
      children: [
        SizedBox(
          height: Responsive.bannerHeight(ctx),
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _promoBanners.length,
            onPageChanged: (index) => setState(() => _bannerIndex = index),
            itemBuilder: (context, index) {
              final banner = _promoBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [banner['start'] as Color, banner['end'] as Color],
                  ),
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
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['subtitle'] as String,
                            style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(banner['icon'] as IconData, color: Colors.white, size: 30),
                    ),
                  ],
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

  Widget _buildViewSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: _showGridCards ? const Color(0xFF1F2A44) : Colors.transparent,
            ),
            onPressed: () => setState(() => _showGridCards = true),
            icon: Icon(Icons.grid_view_rounded, color: _showGridCards ? Colors.white : const Color(0xFF6B7280)),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: !_showGridCards ? const Color(0xFF1F2A44) : Colors.transparent,
            ),
            onPressed: () => setState(() => _showGridCards = false),
            icon: Icon(Icons.view_list_rounded, color: !_showGridCards ? Colors.white : const Color(0xFF6B7280)),
          ),
        ],
      ),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  product == null ? 'N/A' : product.formattedPrice,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFF9B62D) : Colors.white,
                ),
                onPressed: product == null ? null : () => _toggleFavorite(product.id),
              ),
              Text(label, style: const TextStyle(color: Color(0xFFD1D5DB), fontWeight: FontWeight.w600)),
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
    final hasProduct = product != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: product == null
                        ? Center(child: Icon(icon, size: 58, color: Colors.grey.shade500))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _buildProductImage(product, icon, fit: BoxFit.contain),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: hasProduct ? () => _toggleFavorite(product.id) : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 19,
                        color: isFavorite ? Colors.red : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasProduct ? product.name : '$label products coming soon',
                  maxLines: hasProduct ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                if (hasProduct)
                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  )
                else
                  const Text(
                    'No active item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
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
}
