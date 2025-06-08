import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/components/navigation_bar.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// Example implementation of the AppContainer with the standardized HiveNavigationBar
///
/// This example shows how to integrate the HiveNavigationBar with GoRouter
/// for navigation between main app sections.
class AppContainerExample extends StatefulWidget {
  /// The child widget to display (usually the current route)
  final Widget child;

  /// The current navigation index
  final int initialIndex;

  /// Constructor
  const AppContainerExample({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  State<AppContainerExample> createState() => _AppContainerExampleState();
}

class _AppContainerExampleState extends State<AppContainerExample> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(AppContainerExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  /// Define the navigation destinations
  final List<HiveNavigationDestination> _destinations = [
    const HiveNavigationDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    const HiveNavigationDestination(
      icon: HugeIcons.search,
      selectedIcon: HugeIcons.search,
      label: 'Explore',
    ),
    const HiveNavigationDestination(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Notifications',
      hasNotification: true, // Example of notification indicator
    ),
    const HiveNavigationDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: HiveNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _handleNavigation,
        destinations: _destinations,
        // Customize the colors if needed
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.white.withOpacity(0.7),
      ),
    );
  }

  /// Handle navigation when a tab is selected
  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate based on the selected index
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/notifications');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

/// Example of how this would be used with GoRouter
///
/// ```dart
/// final GoRouter router = GoRouter(
///   routes: [
///     ShellRoute(
///       builder: (context, state, child) {
///         // Pass the right index based on the current route
///         int currentIndex = 0;
///         final String location = state.uri.toString();
///
///         if (location.startsWith('/home')) currentIndex = 0;
///         else if (location.startsWith('/explore')) currentIndex = 1;
///         else if (location.startsWith('/notifications')) currentIndex = 2;
///         else if (location.startsWith('/profile')) currentIndex = 3;
///
///         return AppContainerExample(
///           initialIndex: currentIndex,
///           child: child,
///         );
///       },
///       routes: [
///         GoRoute(
///           path: '/home',
///           builder: (context, state) => const HomePage(),
///         ),
///         GoRoute(
///           path: '/explore',
///           builder: (context, state) => const ExplorePage(),
///         ),
///         GoRoute(
///           path: '/notifications',
///           builder: (context, state) => const NotificationsPage(),
///         ),
///         GoRoute(
///           path: '/profile',
///           builder: (context, state) => const ProfilePage(),
///         ),
///       ],
///     ),
///   ],
/// );
/// ```
