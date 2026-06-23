import 'package:flutter/material.dart';

class MenuItemConfig {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final String? route;
  final bool requiresAuth;
  final bool isDivider;
  final bool isDestructive;

  MenuItemConfig({
    required this.id,
    required this.label,
    required this.icon,
    this.onTap,
    this.route,
    this.requiresAuth = false,
    this.isDivider = false,
    this.isDestructive = false,
  });

  factory MenuItemConfig.divider() => MenuItemConfig(
    id: 'divider_${DateTime.now().millisecondsSinceEpoch}',
    label: '',
    icon: Icons.remove,
    isDivider: true,
  );
}
