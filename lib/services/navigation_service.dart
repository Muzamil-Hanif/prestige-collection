import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../pages/about_page.dart';
import '../pages/admin_products_page.dart';
import '../pages/contact_page.dart';
import '../pages/settings_page.dart';
import '../pages/sign_in_page.dart';
import 'storage_service.dart';

class NavigationService {
  static List<MenuItemConfig> getMainMenuItems(
    BuildContext context, {
    bool isAdmin = false,
  }) => [
    if (isAdmin)
      MenuItemConfig(
        id: 'manage_products',
        label: 'Manage Products',
        icon: Icons.inventory_2_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminProductsPage()),
          );
        },
        requiresAuth: true,
      ),
    MenuItemConfig(
      id: 'my_orders',
      label: 'My Orders',
      icon: Icons.receipt_long,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orders page coming soon'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      requiresAuth: true,
    ),
    MenuItemConfig(
      id: 'about',
      label: 'About Us',
      icon: Icons.info_outline,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        );
      },
    ),
    MenuItemConfig(
      id: 'contact',
      label: 'Contact Us',
      icon: Icons.contact_mail,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactPage()),
        );
      },
    ),
    MenuItemConfig(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
      requiresAuth: true,
    ),
    MenuItemConfig.divider(),
    MenuItemConfig(
      id: 'privacy',
      label: 'Privacy Policy',
      icon: Icons.policy,
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
    MenuItemConfig(
      id: 'terms',
      label: 'Terms & Conditions',
      icon: Icons.description,
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
    MenuItemConfig.divider(),
    MenuItemConfig(
      id: 'logout',
      label: 'Logout',
      icon: Icons.logout,
      isDestructive: true,
      requiresAuth: true,
      onTap: () {
        Navigator.pop(context);
        _showLogoutDialog(context);
      },
    ),
  ];

  static void _showLogoutDialog(BuildContext context) {
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
              // Show logout message before navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
              // Navigate back to sign in page
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const SignInPage(),
                ),
                (route) => false,
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
  }
}
