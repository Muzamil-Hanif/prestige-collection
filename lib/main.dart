import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pages/splash_screen.dart';
import 'pages/sign_in_page.dart';
import 'pages/home_page.dart';
import 'pages/products_page.dart';
import 'pages/my_cart.dart';
import 'pages/about_page.dart';
import 'pages/settings_page.dart';
import 'pages/contact_page.dart';
import 'services/storage_service.dart';

void main() {
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

  // Add item to cart
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      // Check if item already exists in cart (match by both name AND image)
      final existingIndex = _cartItems.indexWhere(
        (item) => item['name'] == product['name'] && 
                  item['image'] == product['image'],
      );
      
      if (existingIndex >= 0) {
        // If exists, increase quantity
        _cartItems[existingIndex]['quantity'] = 
            (_cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        // If new, add to cart
        // Extract price from string like "$89.99" to double
        String priceStr = product['price'] as String;
        double price = double.parse(priceStr.replaceAll('\$', '').replaceAll(',', ''));
        
        // Determine icon based on category
        IconData icon = Icons.shopping_bag;
        if (product['name'].toString().toLowerCase().contains('perfume') ||
            product['name'].toString().toLowerCase().contains('fragrance') ||
            product['name'].toString().toLowerCase().contains('cologne')) {
          icon = Icons.spa;
        } else if (product['name'].toString().toLowerCase().contains('watch')) {
          icon = Icons.watch;
        } else if (product['name'].toString().toLowerCase().contains('wallet')) {
          icon = Icons.account_balance_wallet;
        }
        
        _cartItems.add({
          'name': product['name'],
          'price': price,
          'quantity': 1,
          'icon': icon,
          'image': product['image'],
        });
      }
    });
  }

  // Remove item from cart
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  // Update item quantity
  void _updateCartItemQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['quantity'] = quantity;
      }
    });
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
        return const Text(
          'Products',
        );
    
      case 2: // My Cart
        return const Text(
          'My Cart',

        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
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
      ),
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
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
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Dismiss all active SnackBars before navigating
          ScaffoldMessenger.of(context).clearSnackBars();
          // Add a small delay for smoother transition
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _currentIndex = index;
              });
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'My Cart',
          ),
        ],
      ),
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
            decoration: BoxDecoration(
              color: cs.primary,
            ),
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
            title: const Text('My Orders', style: TextStyle(color: Colors.white)),
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
            title: const Text('About Us', style: TextStyle(color: Colors.white)),
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
            title: const Text('Contact Us', style: TextStyle(color: Colors.white)),
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
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
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
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
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
            title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white)),
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
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
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
                          MaterialPageRoute(builder: (context) => const SignInPage()),
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
