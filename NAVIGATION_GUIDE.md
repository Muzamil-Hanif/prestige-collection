# Navigation System Guide

This document explains how to manage the side panel (drawer/sidebar) menu items for the Prestige Men app.

## Overview

The navigation system is now centralized and managed through a **NavigationService** that provides menu configurations for both mobile and web platforms.

### File Structure

```
lib/
├── models/
│   └── menu_item_model.dart          # MenuItemConfig data class
├── services/
│   └── navigation_service.dart        # Central menu configuration
├── widgets/
│   └── responsive_drawer.dart         # Responsive drawer/sidebar widget
└── main.dart                          # Uses the navigation system
```

---

## How It Works

### 1. **Menu Item Configuration** (`menu_item_model.dart`)

Each menu item is defined using the `MenuItemConfig` class:

```dart
MenuItemConfig(
  id: 'unique_id',
  label: 'Display Name',
  icon: Icons.icon_name,
  onTap: () {
    // Action when tapped
  },
  requiresAuth: true,      // Optional: require authentication
  isDestructive: false,    // Optional: show in red (e.g., logout)
)
```

**Special Cases:**
- **Divider:** `MenuItemConfig.divider()` - Creates a visual separator

### 2. **Central Configuration** (`navigation_service.dart`)

All menu items are defined in `NavigationService.getMainMenuItems(BuildContext context)`:

```dart
static List<MenuItemConfig> getMainMenuItems(BuildContext context) => [
  MenuItemConfig(...),
  MenuItemConfig(...),
  MenuItemConfig.divider(),
  MenuItemConfig(...),
];
```

### 3. **Responsive Drawer** (`responsive_drawer.dart`)

The `ResponsiveDrawer` widget automatically handles:
- **Mobile:** Traditional drawer accessible via hamburger menu
- **Web:** Permanent sidebar (280px wide) next to content

---

## How to Add/Edit Menu Items

### Adding a New Menu Item

Edit `lib/services/navigation_service.dart` in the `getMainMenuItems` method:

```dart
MenuItemConfig(
  id: 'my_feature',
  label: 'My Feature',
  icon: Icons.star,
  onTap: () {
    Navigator.pop(context);  // Close drawer
    // Your navigation logic here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyFeaturePage()),
    );
  },
),
```

### Navigation Best Practices

1. **Always close the drawer first:**
   ```dart
   Navigator.pop(context);  // Closes drawer on mobile
   ```

2. **Handle non-existent features gracefully:**
   ```dart
   onTap: () {
     Navigator.pop(context);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Feature coming soon')),
     );
   },
   ```

3. **For destructive actions (logout, delete):**
   ```dart
   MenuItemConfig(
     id: 'logout',
     label: 'Logout',
     icon: Icons.logout,
     isDestructive: true,  // Shows in red
     onTap: () {
       // Show confirmation dialog
     },
   ),
   ```

---

## Platform Behavior

### Mobile (< 1024px width)
- Drawer slides in from left on hamburger menu tap
- Menu items are full-width ListTile format
- Bottom navigation shows home/products/cart tabs

### Web (≥ 1024px width)
- Permanent sidebar (280px) on the left
- Menu items have hover effects and rounded corners
- Top navigation bar with logo and tabs
- No drawer overlay; content adjusts width

---

## Market-Standard Features Ready to Implement

These features are built into the architecture and ready to enable:

### 1. **Role-Based Menu Items**
Currently all items are shown. To implement role-based filtering:

```dart
static List<MenuItemConfig> getMainMenuItems(BuildContext context) => [
  // Admin-only items
  if (userRole == 'admin') ...[
    MenuItemConfig(id: 'admin_panel', ...),
  ],
  // Customer items
  MenuItemConfig(id: 'my_orders', ...),
];
```

### 2. **Backend-Driven Menu**
To fetch menu configuration from your backend:

```dart
static Future<List<MenuItemConfig>> getMainMenuItems(BuildContext context) async {
  try {
    final response = await ApiService.getMenuConfig();
    return response.items.map((item) => 
      MenuItemConfig.fromJson(item)
    ).toList();
  } catch (e) {
    return getDefaultMenuItems(context);
  }
}
```

### 3. **Feature Flags**
Enable/disable menu items based on feature flags:

```dart
if (FeatureFlags.ordersEnabled) ...[
  MenuItemConfig(id: 'my_orders', ...),
],
```

---

## Styling & Customization

### Menu Item Colors

- **Normal items:** White text, `Colors.white70` icon
- **Destructive items (logout):** Red text and icon
- **Hover state:** `Colors.white.withValues(alpha: 0.1)` background

### Sidebar Width (Web)

Edit `responsive_drawer.dart`:
```dart
width: 280,  // Change this value
```

### Icon Size & Spacing

Adjust in `responsive_drawer.dart` ListTile:
```dart
contentPadding: isWeb
    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
    : const EdgeInsets.symmetric(horizontal: 16),
```

---

## Future Enhancements

The system is designed to support:

1. ✅ **Dynamic menu loading** from backend
2. ✅ **Role-based visibility** per menu item
3. ✅ **Menu item badges** (e.g., "3" next to Orders)
4. ✅ **Nested menu items** (submenus)
5. ✅ **Menu item animations** and transitions
6. ✅ **Localization** (i18n support)
7. ✅ **Analytics tracking** per menu tap

---

## Troubleshooting

**Issue:** Drawer doesn't close on mobile after tapping an item

**Solution:** Make sure to call `Navigator.pop(context)` before any navigation:
```dart
onTap: () {
  Navigator.pop(context);  // This is required!
  Navigator.push(...);
},
```

**Issue:** Menu items not appearing on web

**Solution:** Check that `Responsive.isDesktop(context)` returns true. Verify viewport width is >= 1024px.

---

## Summary

The new navigation system provides:

- ✅ **Centralized menu management** - All items in one place
- ✅ **Responsive by default** - Works on mobile and web
- ✅ **Clean separation of concerns** - Easy to maintain
- ✅ **Market-standard patterns** - Ready for enterprise features
- ✅ **Easy to extend** - Add roles, flags, and dynamic loading

To add menu items, edit `lib/services/navigation_service.dart`.
