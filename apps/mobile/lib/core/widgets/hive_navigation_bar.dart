import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

/// Placeholder for the HIVE application's primary bottom navigation bar.
///
/// TODO:
/// - Implement final design based on `brand_aesthetic.md`.
/// - Integrate with navigation state (go_router).
/// - Add navigation items (icons, labels, active states).
/// - Implement HIVE-specific styling (background, item styles, animations).
class HiveNavigationBar extends StatelessWidget {
  const HiveNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Flutter's NavigationBar as a base structure.
    // Styling and items are placeholders for now.
    return NavigationBar(
      backgroundColor: AppColors.surfaceCard, // Example background
      indicatorColor: AppColors.gold.withOpacity(0.2), // Example indicator
      selectedIndex: 0, // Placeholder selection
      onDestinationSelected: (index) {
        // TODO: Implement navigation logic
        debugPrint('Tapped navigation item: $index');
      },
      destinations: const [
        // Placeholder destinations
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: AppColors.textTertiary),
          selectedIcon: Icon(Icons.home, color: AppColors.textPrimary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search, color: AppColors.textTertiary),
          selectedIcon: Icon(Icons.search, color: AppColors.textPrimary),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline, color: AppColors.textTertiary),
          selectedIcon: Icon(Icons.add_circle, color: AppColors.textPrimary),
          label: 'Create',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none, color: AppColors.textTertiary),
          selectedIcon: Icon(Icons.notifications, color: AppColors.textPrimary),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: AppColors.textTertiary),
          selectedIcon: Icon(Icons.person, color: AppColors.textPrimary),
          label: 'Profile',
        ),
      ],
    );
  }
} 