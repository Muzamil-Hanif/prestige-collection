import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../pages/about_page.dart';
import '../pages/admin_orders_page.dart';
import '../pages/admin_products_page.dart';
import '../pages/contact_page.dart';
import '../pages/my_orders_page.dart';
import '../pages/settings_page.dart';
import 'api_service.dart';
import 'session_manager.dart';

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
    if (isAdmin)
      MenuItemConfig(
        id: 'manage_orders',
        label: 'Manage Orders',
        icon: Icons.assignment_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminOrdersPage()),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyOrdersPage()),
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
            onPressed: () {
              // Close the dialog first — its context becomes invalid right
              // after this, so nothing below may rely on it.
              Navigator.pop(context);
              // Notify backend and clear local credentials, then redirect
              // via the root navigator (SessionManager doesn't depend on
              // any screen/dialog context, so it can't end up stuck on a
              // blank screen).
              ApiService.logout().whenComplete(
                () => SessionManager.forceLogout(message: 'Logged out successfully'),
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
