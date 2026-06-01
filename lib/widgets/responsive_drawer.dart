import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/menu_item_model.dart';
import '../utils/responsive.dart';

class ResponsiveDrawer extends StatelessWidget {
  final List<MenuItemConfig> items;
  final VoidCallback? onProfileTap;

  const ResponsiveDrawer({
    super.key,
    required this.items,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isDesktop(context);
    final cs = Theme.of(context).colorScheme;

    if (isWeb) {
      return Container(
        width: 280,
        color: cs.surface,
        child: Column(
          children: [
            _buildHeader(context, cs),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.isDivider) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white24),
                    );
                  }
                  return _buildMenuItem(context, item, isWeb);
                },
              ),
            ),
          ],
        ),
      );
    }

    return Drawer(
      backgroundColor: cs.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context, cs),
          ..._buildMenuItems(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return DrawerHeader(
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
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    return items.map((item) {
      if (item.isDivider) {
        return const Divider(color: Colors.white24);
      }
      return _buildMenuItem(context, item, false);
    }).toList();
  }

  Widget _buildMenuItem(BuildContext context, MenuItemConfig item, bool isWeb) {
    final textColor = item.isDestructive ? Colors.red : Colors.white;
    final hoverColor = item.isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.1);

    return ListTile(
      leading: Icon(item.icon, color: item.isDestructive ? Colors.red : Colors.white70),
      title: Text(
        item.label,
        style: TextStyle(
          color: textColor,
          fontWeight: item.isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: item.onTap,
      hoverColor: hoverColor,
      shape: isWeb ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)) : null,
      contentPadding: isWeb
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
