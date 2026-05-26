import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'utils/responsive.dart';

void main() {
  ApiService.setProduction(ApiConfig.isProduction);
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
      title: 'Prestige Men',
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
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
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
      home: const SplashScreen(),
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

      // If price is missing but product is nested, extract from there
      if ((normalized['price'] == null || normalized['price'] is! num) &&
          normalized['product'] is Map<String, dynamic>) {
        final product = normalized['product'] as Map<String, dynamic>;
        normalized['price'] = _parsePrice(product['price']);

        // Also flatten other product fields if not already present
        if (normalized['name'] == null && product['name'] != null) {
          normalized['name'] = product['name'];
        }
        if (normalized['image'] == null && product['image'] != null) {
          normalized['image'] = product['image'];
        }
        if (normalized['id'] == null && product['id'] != null) {
          normalized['id'] = product['id'];
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
          'assets/images/prestige-men-logo-V4.svg',
          height: 66,
          width: 66,
          fit: BoxFit.contain,
        );
      case 1: // Products
        return const Text('Products');

      case 2: // My Cart
        return const Text('My Cart');
      default:
        return null;
    }
  }

  // Build AppBar with conditional TabBar for wide screens
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isWideScreen = Responsive.isTablet(context) || Responsive.isDesktop(context);

    if (!isWideScreen) {
      // Mobile: standard AppBar with menu button and title
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
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
      );
    }

    // Tablet/Desktop: AppBar with TabBar
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: SvgPicture.asset(
        'assets/images/prestige-men-logo-V4.svg',
        height: 50,
        width: 50,
        fit: BoxFit.contain,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabBarItem(0, Icons.home_rounded, 'Home'),
              const SizedBox(width: 32),
              _buildTabBarItem(1, Icons.shopping_bag_rounded, 'Products'),
              const SizedBox(width: 32),
              _buildTabBarItem(2, Icons.shopping_cart_rounded, 'My Cart'),
            ],
          ),
        ),
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFF2C94C) : Colors.black87,
            size: isSelected ? 24 : 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFF2C94C) : Colors.black87,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (isSelected)
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF2C94C),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = Responsive.isTablet(context) || Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
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
                  position:
                      Tween<Offset>(
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
      bottomNavigationBar: !isWideScreen ? _buildGradientBottomBar(context) : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: cs.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: cs.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/prestige-men-logo-V5.svg',
                  height: 90,
                  width: 90,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.white70),
            title: const Text(
              'My Orders',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orders page coming soon'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: const Text(
              'About Us',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.contact_mail, color: Colors.white70),
            title: const Text(
              'Contact Us',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.policy, color: Colors.white70),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy page coming soon'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.white70),
            title: const Text(
              'Terms & Conditions',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms & Conditions page coming soon'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          const Divider(color: Colors.white24),
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Clear stored authentication data
                        await StorageService.clearAll();
                        // Navigate back to sign in page
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const SignInPage(),
                          ),
                          (route) => false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
