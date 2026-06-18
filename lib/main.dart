import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'pages/splash_screen.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page_clean.dart';
import 'pages/products_page.dart';
import 'pages/my_cart.dart';
import 'pages/about_page.dart';
import 'pages/settings_page.dart';
import 'pages/contact_page.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/api_config.dart';
import 'services/session_manager.dart';
import 'services/deep_link_service.dart';
import 'models/menu_item_model.dart';
import 'services/navigation_service.dart';
import 'utils/responsive.dart';
import 'widgets/responsive_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setProduction(ApiConfig.isProduction);
  DeepLinkService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF111827),
      onPrimary: Colors.white,
      secondary: Color(0xFFF2C94C),
      onSecondary: Colors.black,
      surface: Color(0xFF1F2937),
      onSurface: Colors.white,
      background: Color(0xFFF5F5F5),
      onBackground: Colors.black,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      primaryContainer: Color(0xFF111111),
      onPrimaryContainer: Colors.white70,
      secondaryContainer: Color(0xFF2D2D2D),
      onSecondaryContainer: Colors.white,
      surfaceVariant: Color(0xFF111827),
      onSurfaceVariant: Colors.white70,
      outline: Colors.white24,
      shadow: Colors.black,
      inverseSurface: Color(0xFFE5E7EB),
      onInverseSurface: Colors.black87,
      tertiary: Color(0xFF6B7280),
      onTertiary: Colors.white,
    );

    return MaterialApp(
      navigatorKey: SessionManager.navigatorKey,
      title: 'Prestige Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (BuildContext context) {
            final color = IconTheme.of(context).color ?? Colors.black;
            return Icon(Icons.arrow_back, color: color);
          },
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        cardColor: colorScheme.surface,
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.secondary,
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
        ),
      ),
      home: !kIsWeb ? const SplashScreen() : const _WebHomeGate(),
    );
  }
}

class _WebHomeGate extends StatefulWidget {
  const _WebHomeGate();

  @override
  State<_WebHomeGate> createState() => _WebHomeGateState();
}

class _WebHomeGateState extends State<_WebHomeGate> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => isLoggedIn ? const MainScreen() : const SignInPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Shared cart items state
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isAdmin = false;

  int get _cartItemCount {
    return _cartItems.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() => _isAdmin = profile.role == 'admin');
      await StorageService.saveUserRole(profile.role);
    } catch (_) {
      final cachedRole = await StorageService.getUserRole();
      if (!mounted) return;
      setState(() => _isAdmin = cachedRole == 'admin');
    }
  }

  Future<void> _loadCart() async {
    // 1) local persisted state for instant UI
    final persisted = await StorageService.getCartItems();
    if (persisted != null && persisted.isNotEmpty) {
      try {
        final decoded = json.decode(persisted) as List<dynamic>;
        setState(() {
          _cartItems
            ..clear()
            ..addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
        });
      } catch (_) {
        // Ignore invalid cache.
      }
    }

    // 2) backend cart sync — only replace local rows when the server returns items.
    // (An empty server cart must not wipe a valid offline cart.)
    try {
      final serverCart = await ApiService.getCartItems();
      if (serverCart.isNotEmpty) {
        setState(() {
          _cartItems
            ..clear()
            ..addAll(_normalizeCartItems(serverCart));
        });
        await _persistCart();
      }
    } catch (_) {
      // Backend cart endpoint may not exist yet; keep local cart.
    }
  }

  /// Normalize cart items from backend: flatten nested product structures and ensure required fields.
  List<Map<String, dynamic>> _normalizeCartItems(List<Map<String, dynamic>> items) {
    return items.map((item) {
      final normalized = Map<String, dynamic>.from(item);
      final product = normalized['product'] is Map<String, dynamic>
          ? normalized['product'] as Map<String, dynamic>
          : null;

      final productId = ApiService.mongoIdToString(
        normalized['productId'] ?? normalized['id'] ?? product?['_id'] ?? product?['id'],
      );
      if (productId.isNotEmpty) {
        normalized['id'] = productId;
        normalized['productId'] = productId;
      }

      if (product != null) {
        if (normalized['name'] == null && product['name'] != null) {
          normalized['name'] = product['name'];
        }
        if (normalized['image'] == null) {
          if (product['image'] != null) {
            normalized['image'] = product['image'];
          } else if (product['images'] is List && (product['images'] as List).isNotEmpty) {
            normalized['image'] = product['images'].first;
          }
        }
        if (normalized['price'] == null || normalized['price'] is! num) {
          normalized['price'] = _parsePrice(product['price']);
        }
      }

      // Ensure price is a double
      if (normalized['price'] != null && normalized['price'] is! double) {
        normalized['price'] = _parsePrice(normalized['price']);
      }

      // Default price to 0 if still missing
      if (normalized['price'] == null) {
        normalized['price'] = 0.0;
      }

      normalized.remove('product');
      normalized.remove('lineTotal');

      return normalized;
    }).toList();
  }

  /// Parse price from various formats (num, String, etc.)
  double _parsePrice(dynamic price) {
    if (price is num) {
      return price.toDouble();
    } else if (price is String) {
      return double.tryParse(price.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  /// Cart rows may include non-JSON `IconData`; strip before persisting.
  List<Map<String, dynamic>> _cartItemsJsonSafe() {
    return _cartItems.map((item) {
      final copy = Map<String, dynamic>.from(item);
      copy.remove('icon');
      return copy;
    }).toList();
  }

  Future<void> _persistCart() async {
    await StorageService.saveCartItems(json.encode(_cartItemsJsonSafe()));
  }

  void _syncAddToBackend(String productId, int quantity) {
    if (productId.isEmpty) return;
    ApiService.addToCart(
      productId: productId,
      quantity: quantity,
    ).catchError((_) {});
  }

  void _syncUpdateToBackend(String productId, int quantity) {
    if (productId.isEmpty) return;
    ApiService.updateCartItem(
      productId: productId,
      quantity: quantity,
    ).catchError((_) {});
  }

  void _syncRemoveFromBackend(String productId) {
    if (productId.isEmpty) return;
    ApiService.removeFromCart(productId).catchError((_) {});
  }

  // Add item to cart
  void _addToCart(Map<String, dynamic> product) {
    String productId = '';
    int quantityForSync = 1;

    setState(() {
      productId = product['id']?.toString() ?? '';
      final productName = product['name']?.toString() ?? '';
      final productImage = product['image'];

      // Check if item already exists in cart.
      // Prefer matching by backend product id when available.
      final existingIndex = _cartItems.indexWhere((item) {
        final itemId = item['id']?.toString() ?? '';
        if (productId.isNotEmpty && itemId.isNotEmpty) {
          return itemId == productId;
        }
        return item['name'] == productName && item['image'] == productImage;
      });

      if (existingIndex >= 0) {
        // If exists, increase quantity
        _cartItems[existingIndex]['quantity'] =
            (_cartItems[existingIndex]['quantity'] as int) + 1;
        quantityForSync = _cartItems[existingIndex]['quantity'] as int;
      } else {
        // If new, add to cart
        // `price` can come as a String (e.g. "$89.99") or a num (from API).
        final priceRaw = product['price'];
        final double price = switch (priceRaw) {
          final num n => n.toDouble(),
          final String s =>
            double.tryParse(s.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0,
          _ => 0.0,
        };

        // Determine icon based on category
        IconData icon = Icons.shopping_bag;
        final nameLower = productName.toLowerCase();
        if (nameLower.contains('perfume') ||
            nameLower.contains('fragrance') ||
            nameLower.contains('cologne')) {
          icon = Icons.spa;
        } else if (nameLower.contains('watch')) {
          icon = Icons.watch;
        } else if (nameLower.contains('wallet')) {
          icon = Icons.account_balance_wallet;
        }

        _cartItems.add({
          'id': productId,
          'productId': productId, // compatibility with checkout parsing
          'name': product['name'],
          'price': price,
          'quantity': 1,
          'icon': icon,
          'image': productImage,
        });
        quantityForSync = 1;
      }
    });

    _persistCart();
    _syncAddToBackend(productId, quantityForSync);
  }

  // Remove item from cart
  void _removeFromCart(int index) {
    String productId = '';
    setState(() {
      productId = _cartItems[index]['id']?.toString() ?? '';
      _cartItems.removeAt(index);
    });
    _persistCart();
    _syncRemoveFromBackend(productId);
  }

  // Update item quantity
  void _updateCartItemQuantity(int index, int quantity) {
    String productId = '';
    setState(() {
      productId = _cartItems[index]['id']?.toString() ?? '';
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['quantity'] = quantity;
      }
    });
    _persistCart();
    if (quantity <= 0) {
      _syncRemoveFromBackend(productId);
    } else {
      _syncUpdateToBackend(productId, quantity);
    }
  }

  // List of pages for bottom navigation
  List<Widget> get _pages => [
    const HomePage(),
    ProductsPage(
      onAddToCart: _addToCart,
      onNavigateToCart: () {
        // Dismiss all active SnackBars before navigating
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() {
          _currentIndex = 2; // Navigate to My Cart page
        });
      },
    ),
    MyCart(
      cartItems: _cartItems,
      onRemoveFromCart: _removeFromCart,
      onUpdateQuantity: _updateCartItemQuantity,
      onNavigateToProducts: () {
        // Dismiss all active SnackBars before navigating
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() {
          _currentIndex = 1; // Navigate to Products page
        });
      },
    ),
  ];

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubicEmphasized,
            offset: isSelected ? const Offset(0, -0.05) : Offset.zero,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              scale: isSelected ? 1.06 : 0.96,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOutCubic,
                        padding: EdgeInsets.all(isSelected ? 8 : 7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.transparent,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                          child: Icon(
                            icon,
                            key: ValueKey<bool>(isSelected),
                            color: isSelected
                                ? const Color(0xFFF2C94C)
                                : Colors.white.withValues(alpha: 0.75),
                            size: isSelected ? 22 : 20,
                          ),
                        ),
                      ),
                      if (showBadge && _cartItemCount > 0)
                        Positioned(
                          right: -7,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 16),
                            child: Text(
                              _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFF2C94C)
                          : Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        height: 84,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F2A44),
                    Color(0xFF23395B),
                    Color(0xFF2A3D66),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () async {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      if (_currentIndex == 0) return;
                      await Future.delayed(const Duration(milliseconds: 90));
                      if (!mounted) return;
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Products',
                    onTap: () async {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      if (_currentIndex == 1) return;
                      await Future.delayed(const Duration(milliseconds: 90));
                      if (!mounted) return;
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.shopping_cart_rounded,
                    label: 'My Cart',
                    showBadge: true,
                    onTap: () async {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      if (_currentIndex == 2) return;
                      await Future.delayed(const Duration(milliseconds: 90));
                      if (!mounted) return;
                      setState(() => _currentIndex = 2);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get dynamic AppBar title based on current page
  Widget? _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: // Home
        return SvgPicture.asset(
          'assets/images/prestige-collections-final.svg',
          height: 100,
          width: 100,
          fit: BoxFit.contain,
        );
      case 1: // Products
        return const Text('Products', style: TextStyle(color: Colors.black87));

      case 2: // My Cart
        return const Text('My Cart', style: TextStyle(color: Colors.black87));
      default:
        return null;
    }
  }

  // Build AppBar with conditional TabBar for wide screens
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isWideScreen = Responsive.isTablet(context) || Responsive.isDesktop(context);

    if (!isWideScreen) {
      // Mobile: Gray AppBar matching background with subtle divider
      return PreferredSize(
        preferredSize: const Size.fromHeight(141),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            
          ),
          child: AppBar(
            backgroundColor: const Color(0xFFF5F5F5),
            elevation: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFFF5F5F5),
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: _getAppBarTitle(),
            toolbarHeight: 140,
            centerTitle: true,
          ),
        ),
      );
    }

    // Tablet/Desktop: Elegant AppBar with logo, hamburger, tabs, and cart
    return PreferredSize(
      preferredSize: const Size.fromHeight(281),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
        
        ),
        child: AppBar(
          backgroundColor: const Color(0xFFF5F5F5),
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFF5F5F5),
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        leadingWidth: 280,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              final menuItems = NavigationService.getMainMenuItems(context, isAdmin: _isAdmin);
              _showLeftSidePanel(context, menuItems);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
              child: SvgPicture.asset(
              
                'assets/images/prestige-collections-final.svg',
                height: 250,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabBarItem(0, Icons.home_rounded, 'Home'),
            const SizedBox(width: 48),
            _buildTabBarItem(1, Icons.shopping_bag_rounded, 'Products'),
            const SizedBox(width: 48),
            _buildTabBarItem(2, Icons.shopping_cart_rounded, 'My Cart'),
          ],
        ),
        actions: [
          // Cart icon with badge (top right)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                  onPressed: () {
                    setState(() => _currentIndex = 2);
                  },
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Hamburger menu icon for side panel (top right)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 28),
            tooltip: 'Menu',
            onPressed: () {
              // Show sidebar sliding from left
              final menuItems = NavigationService.getMainMenuItems(context, isAdmin: _isAdmin);
              _showLeftSidePanel(context, menuItems);
            },
          ),
        ),
      ],
      toolbarHeight: 120,
    ),
      ),
    );
  }

  // Show left side panel with slide animation
  void _showLeftSidePanel(BuildContext context, List<MenuItemConfig> menuItems) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.expand();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            // Backdrop that closes the menu when tapped
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5 * animation.value),
              ),
            ),
            // Side panel sliding from left
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
              ),
              child: _buildWebSidePanelModal(context, menuItems),
            ),
          ],
        );
      },
    );
  }

  // Build web side panel modal (hamburger menu modal)
  Widget _buildWebSidePanelModal(BuildContext context, List<MenuItemConfig> menuItems) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: cs.surface,
        child: Container(
          width: 320,
          height: MediaQuery.sizeOf(context).height,
          color: cs.surface,
          child: Column(
            children: [
              // Header with logo and close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary,
                  // border: Border(
                  //   bottom: BorderSide(color: Colors.white24),
                  // ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SvgPicture.asset(
                      'assets/images/prestige-collections-white-nobg.svg',
                      height: 120,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              // const Divider(color: Colors.white24),
              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    if (item.isDivider) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.white24),
                      );
                    }
                    return _buildWebModalMenuItem(context, item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build individual menu item for web modal
  Widget _buildWebModalMenuItem(BuildContext context, MenuItemConfig item) {
    final textColor = item.isDestructive ? Colors.red : Colors.white;
    final iconColor = item.isDestructive ? Colors.red : Colors.white70;

    return ListTile(
      leading: Icon(item.icon, color: iconColor),
      title: Text(
        item.label,
        style: TextStyle(
          color: textColor,
          fontWeight: item.isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close modal first
        item.onTap?.call();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      hoverColor: Colors.white.withValues(alpha: 0.1),
    );
  }

  // Build individual tab bar item
  Widget _buildTabBarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () async {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (_currentIndex == index) return;
        await Future.delayed(const Duration(milliseconds: 90));
        if (!mounted) return;
        setState(() => _currentIndex = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF2C94C).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: TextStyle(
                color: isSelected ? const Color(0xFFF2C94C) : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    scale: isSelected ? 1.15 : 1.0,
                    child: Icon(
                      icon,
                      color: isSelected
                          ? const Color(0xFFF2C94C)
                          : Colors.black87,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = Responsive.isTablet(context) || Responsive.isDesktop(context);
    final menuItems = NavigationService.getMainMenuItems(context, isAdmin: _isAdmin);

    if (isWideScreen) {
      // Web: Hamburger menu only (no permanent sidebar)
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: _buildAppBar(context),
        extendBodyBehindAppBar: false,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile: Drawer + Bottom Nav
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      extendBodyBehindAppBar: false,
      drawer: ResponsiveDrawer(items: menuItems),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildGradientBottomBar(context),
    );
  }

}
