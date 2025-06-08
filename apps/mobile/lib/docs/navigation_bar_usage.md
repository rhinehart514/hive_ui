# HiveNavigationBar Usage Guide

## Overview

The `HiveNavigationBar` is a standardized navigation component that provides consistent navigation across the HIVE app. It supports multiple visual styles, animations, and configurations to meet various UI requirements while maintaining design consistency.

## Features

- Multiple visual styles (standard, iOS-inspired, minimal, glassmorphic)
- Badge notifications support
- Consistent animations and haptic feedback
- Support for different positions (bottom, side)
- Customizable colors and appearance
- Standardized navigation destination API

## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:hive_ui/components/navigation_bar.dart';

// In your widget
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
  destinations: [
    HiveNavigationDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    HiveNavigationDestination(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Search',
    ),
    HiveNavigationDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
      badgeCount: 2, // Optional badge count
    ),
    HiveNavigationDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      hasNotification: true, // Optional notification indicator
    ),
  ],
)
```

## Style Variations

### Standard Style (Default)

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  // Default style is already HiveNavigationBarStyle.standard
)
```

### iOS-Inspired Style

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  style: HiveNavigationBarStyle.ios,
)
```

### Minimal Style

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  style: HiveNavigationBarStyle.minimal,
  showLabels: false, // Often minimal bars don't show labels
)
```

### Glassmorphic Style

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  style: HiveNavigationBarStyle.glass,
)
```

## Customization

### Custom Colors

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  backgroundColor: Colors.black.withOpacity(0.8),
  selectedItemColor: Colors.amber,
  unselectedItemColor: Colors.grey,
)
```

### Without Labels

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  showLabels: false,
)
```

### Without Haptic Feedback

```dart
HiveNavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: destinations,
  useHapticFeedback: false,
)
```

## Badges and Notifications

### Adding a Badge Count

```dart
HiveNavigationDestination(
  icon: Icons.chat_bubble_outline,
  selectedIcon: Icons.chat_bubble,
  label: 'Messages',
  badgeCount: 5, // Shows "5" in a badge
)
```

### Adding a Notification Indicator (Dot)

```dart
HiveNavigationDestination(
  icon: Icons.notifications_outlined,
  selectedIcon: Icons.notifications,
  label: 'Notifications',
  hasNotification: true, // Shows a dot notification
)
```

## Integration with Router

For best practices when integrating with the router, consider this pattern:

```dart
class AppShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const AppShell({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _currentIndex = widget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: HiveNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Navigate based on index
          switch (index) {
            case 0:
              context.router.replace(const HomeRoute());
              break;
            case 1:
              context.router.replace(const SearchRoute());
              break;
            case 2:
              context.router.replace(const ProfileRoute());
              break;
            case 3:
              context.router.replace(const SettingsRoute());
              break;
          }
        },
        destinations: [
          HiveNavigationDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          HiveNavigationDestination(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Search',
          ),
          HiveNavigationDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
          HiveNavigationDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Consistency**: Use the same style throughout your app for a consistent user experience
2. **Limited Destinations**: Keep navigation items to 3-5 to avoid overcrowding
3. **Clear Labels**: Use concise, clear labels that describe the destination
4. **Icon Selection**: Use distinct icons that clearly represent their destinations
5. **Badge Usage**: Use badges sparingly and only for important notifications

## Migration Guide

If you're migrating from the old navigation components, follow these steps:

1. Replace imports:
   ```dart
   // Old
   import 'package:hive_ui/widgets/bottom_nav_bar.dart';
   import 'package:hive_ui/widgets/hive_navigation_bar.dart';
   import 'package:hive_ui/widgets/apple_navigation_bar.dart';
   
   // New
   import 'package:hive_ui/components/navigation_bar.dart';
   ```

2. Replace component usage:
   ```dart
   // Old
   BottomNavBar(
     currentIndex: _currentIndex,
     onTap: (index) => setState(() => _currentIndex = index),
   )
   
   // New
   HiveNavigationBar(
     selectedIndex: _currentIndex,
     onDestinationSelected: (index) => setState(() => _currentIndex = index),
     destinations: [/* your destinations */],
   )
   ```

3. For AppleNavigationBar users:
   ```dart
   // Old
   AppleNavigationBar(
     selectedIndex: _selectedIndex,
     onItemSelected: (index) => setState(() => _selectedIndex = index),
     destinations: destinations,
     showPillIndicator: true,
   )
   
   // New
   HiveNavigationBar(
     selectedIndex: _selectedIndex,
     onDestinationSelected: (index) => setState(() => _selectedIndex = index),
     destinations: destinations,
     style: HiveNavigationBarStyle.ios, // Uses pill indicator
   )
   ```

## Conclusion

The `HiveNavigationBar` provides a flexible, consistent navigation experience while maintaining the premium aesthetic of the HIVE design system. By standardizing the navigation component, we ensure a cohesive experience throughout the app while reducing code duplication and making future updates easier to implement. 