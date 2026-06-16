import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../utils/responsive.dart';

class ProductsPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback? onNavigateToCart;

  const ProductsPage({
    super.key,
    required this.onAddToCart,
    this.onNavigateToCart,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with SingleTickerProviderStateMixin {
  static const Map<int, String> _tabs = {
    0: 'All Items',
    1: 'Perfumes',
    2: 'Watches',
    3: 'Wallets',
    4: 'Shirts',
  };
  static const Map<int, String?> _categoryApiValues = {
    0: null,
    1: 'perfumes',
    2: 'watches',
    3: 'wallets',
    4: 'shirts',
  };

  late TabController _tabController;
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _search = '';
  bool _inStockOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  List<ProductModel> _searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      // Rebuild to reflect selected chip state.
      setState(() => _searchSuggestions = []);
      if (_tabController.indexIsChanging) return;
      _loadProductsForCurrentTab();
    });
    _loadProductsForCurrentTab();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  int get _selectedCategoryCode => _tabs.keys.elementAt(_tabController.index);
  String get _selectedTabLabel => _tabs[_selectedCategoryCode] ?? 'Items';
  List<ProductModel> get _visibleProducts {
    final query = _search.trim().toLowerCase();
    return _products.where((product) {
      if (_selectedCategoryCode != 0 && product.category != _selectedCategoryCode) {
        return false;
      }
      if (_inStockOnly && product.stock <= 0) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final name = product.name.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      final categoryLabel = product.categoryLabel.toLowerCase();
      return name.contains(query) || description.contains(query) || categoryLabel.contains(query);
    }).toList();
  }

  Future<void> _fetchTypeaheadSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() => _searchSuggestions = []);
      return;
    }

    try {
      final matches = await ApiService.getProducts(
        search: trimmed,
        limit: 8,
      );
      if (!mounted) return;
      setState(() => _searchSuggestions = matches);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchSuggestions = []);
    }
  }

  void _onSearchChanged(String value) {
    final normalized = value.trim();
    setState(() => _search = normalized);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => _fetchTypeaheadSuggestions(normalized),
    );
  }

  Future<void> _loadProductsForCurrentTab() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoryCode = _selectedCategoryCode;
      final categoryValue = _categoryApiValues[categoryCode];
      final products = await ApiService.getProducts(
        category: categoryValue,
      );

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  IconData _iconForCategoryCode(int code) {
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
        return Icons.grid_view;
    }
  }

  Widget _buildProductImage(ProductModel product, IconData fallbackIcon) {
    if (product.imageUrl.isEmpty) {
      return Icon(fallbackIcon, size: 40, color: Theme.of(context).colorScheme.secondary);
    }

    if (product.hasNetworkImage) {
      return Image.network(
        product.displayImageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: 40, color: Theme.of(context).colorScheme.secondary),
      );
    }

    return Image.asset(
      product.imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: 40, color: Theme.of(context).colorScheme.secondary),
    );
  }

  Widget _buildImageByPath(String imagePath, IconData fallbackIcon, {BoxFit fit = BoxFit.cover}) {
    if (imagePath.isEmpty) {
      return Icon(fallbackIcon, size: 40, color: Theme.of(context).colorScheme.secondary);
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        ProductModel.toDisplayImageUrl(imagePath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: 40, color: Theme.of(context).colorScheme.secondary),
      );
    }
    return Image.asset(
      imagePath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: 40, color: Theme.of(context).colorScheme.secondary),
    );
  }

  void _openImageViewer(List<String> images, int initialIndex, IconData fallbackIcon) {
    if (images.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        final pageController = PageController(initialPage: initialIndex);
        var currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text('${currentIndex + 1}/${images.length}'),
              ),
              body: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: pageController,
                    onPageChanged: (index) => setModalState(() => currentIndex = index),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: _buildImageByPath(images[index], fallbackIcon, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: currentIndex == index ? 18 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentIndex == index ? Colors.white : Colors.white38,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _productDetailsContent({
    required ProductModel product,
    required ColorScheme cs,
    required List<String> images,
    required IconData fallbackIcon,
    required PageController pageController,
    required int activeImage,
    required void Function(void Function()) setModalState,
    required bool showDragHandle,
  }) {
    return [
      if (showDragHandle) ...[
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      Text(
        product.name,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        product.description ?? 'No description available',
        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
      ),
      const SizedBox(height: 16),
      AspectRatio(
        aspectRatio: 1.2,
        child: Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: images.isEmpty
              ? Center(child: Icon(fallbackIcon, color: cs.secondary, size: 50))
              : Stack(
                  children: [
                    PageView.builder(
                      controller: pageController,
                      itemCount: images.length,
                      onPageChanged: (index) => setModalState(() => activeImage = index),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openImageViewer(images, index, fallbackIcon),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageByPath(
                                images[index],
                                fallbackIcon,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: activeImage == index ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: activeImage == index ? cs.secondary : Colors.white38,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildMetaChip('Price', product.formattedPrice, cs),
          _buildMetaChip(
            'Stock',
            product.stock > 0 ? '${product.stock} available' : 'Out of stock',
            cs,
          ),
          _buildMetaChip('Category', product.categoryLabel, cs),
        ],
      ),
      const SizedBox(height: 18),
      Text(
        'Specifications',
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      if (product.specifications == null || product.specifications!.isEmpty)
        Text(
          'No specifications available.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
        )
      else
        ...product.specifications!.entries.where((e) => e.key.toLowerCase() != 'category').map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _toTitleCase(e.key),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${e.value}',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ];
  }

  void _openProductDetails(ProductModel product) {
    final cs = Theme.of(context).colorScheme;
    final fallbackIcon = _iconForCategoryCode(product.category);
    final images = product.images.isNotEmpty
        ? product.images.where((e) => e.trim().isNotEmpty).toList()
        : (product.imageUrl.isNotEmpty ? <String>[product.imageUrl] : <String>[]);

    if (kIsWeb) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          final pageController = PageController();
          var activeImage = 0;
          return Dialog(
            backgroundColor: cs.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.close, color: cs.onSurface),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                      Flexible(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: _productDetailsContent(
                            product: product,
                            cs: cs,
                            images: images,
                            fallbackIcon: fallbackIcon,
                            pageController: pageController,
                            activeImage: activeImage,
                            setModalState: setModalState,
                            showDragHandle: false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final pageController = PageController();
        var activeImage = 0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.82,
              minChildSize: 0.5,
              maxChildSize: 0.94,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: _productDetailsContent(
                      product: product,
                      cs: cs,
                      images: images,
                      fallbackIcon: fallbackIcon,
                      pageController: pageController,
                      activeImage: activeImage,
                      setModalState: setModalState,
                      showDragHandle: true,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetaChip(String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
            color: cs.onPrimaryContainer.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toTitleCase(String key) {
    final cleaned = key.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  void _showAddedToCartToast(ProductModel product) {
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          elevation: 4,
          duration: const Duration(seconds: 2),
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: cs.secondary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${product.name} added to cart',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          action: widget.onNavigateToCart == null
              ? null
              : SnackBarAction(
                  label: 'VIEW',
                  textColor: cs.secondary,
                  onPressed: widget.onNavigateToCart!,
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tabEntries = _tabs.entries.toList(growable: false);
    final visibleProducts = _visibleProducts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onSubmitted: (_) => _loadProductsForCurrentTab(),
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {
                          _search = '';
                          _searchSuggestions = [];
                        });
                        _loadProductsForCurrentTab();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () {
                      setState(() => _inStockOnly = !_inStockOnly);
                      _loadProductsForCurrentTab();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_searchSuggestions.isNotEmpty && _searchFocusNode.hasFocus)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _searchSuggestions
                    .map(
                      (p) => ListTile(
                        dense: true,
                        leading: Icon(
                          _iconForCategoryCode(p.category),
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        title: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          p.categoryLabel,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        onTap: () {
                          _searchController.text = p.name;
                          _searchController.selection = TextSelection.collapsed(
                            offset: _searchController.text.length,
                          );
                          _searchFocusNode.unfocus();
                          _searchDebounce?.cancel();
                          setState(() {
                            _search = p.name;
                            _searchSuggestions = [];
                          });
                          if (p.category >= 1 && p.category <= 4 && _tabController.index != p.category) {
                            _tabController.animateTo(p.category);
                            return;
                          }
                          _loadProductsForCurrentTab();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   child: Align(
        //     alignment: Alignment.centerLeft,
        //     child: FilterChip(
        //       label: const Text('In stock only'),
        //       selected: _inStockOnly,
        //       onSelected: (selected) {
        //         setState(() => _inStockOnly = selected);
        //         _loadProductsForCurrentTab();
        //       },
        //     ),
        //   ),
        // ),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tabEntries.length,
            itemBuilder: (context, index) {
              final entry = tabEntries[index];
              final isSelected = _tabController.index == index;
              return GestureDetector(
                onTap: () => _tabController.animateTo(index),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForCategoryCode(entry.key),
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error loading products', style: TextStyle(color: Colors.red[700])),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProductsForCurrentTab,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : visibleProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 42,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _search.isNotEmpty
                                      ? 'No matching products found'
                                      : _selectedCategoryCode == 0
                                          ? 'No products available right now'
                                          : 'No ${_selectedTabLabel.toLowerCase()} available',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_search.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try another keyword or choose a different tab',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProductsForCurrentTab,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleProducts.length,
                            itemBuilder: (context, index) {
                              final product = visibleProducts[index];
                              final categoryIcon = _iconForCategoryCode(product.category);
                              final productMap = {
                                'id': product.id,
                                'name': product.name,
                                'description': product.description ?? '',
                                'price': product.price,
                                'image': product.imageUrl.isNotEmpty ? product.imageUrl : null,
                              };

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openProductDetails(product),
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
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: _buildProductImage(product, categoryIcon),
                                          ),
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
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        product.formattedPrice,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.secondary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        product.stock > 0
                                                            ? 'Stock: ${product.stock}'
                                                            : 'Out of stock',
                                                        style: TextStyle(
                                                          color: product.stock > 0
                                                              ? Colors.white70
                                                              : Colors.red.shade300,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: product.isAvailable && product.stock > 0
                                                        ? () {
                                                            widget.onAddToCart(productMap);
                                                            _showAddedToCartToast(product);
                                                          }
                                                        : null,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      foregroundColor: Colors.black,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      minimumSize: const Size(0, 30),
                                                      textStyle: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      product.isAvailable && product.stock > 0
                                                          ? 'Add to Cart'
                                                          : 'Out of Stock',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
