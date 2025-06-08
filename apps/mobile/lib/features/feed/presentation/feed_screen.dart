// DEPRECATED: This file is deprecated and should not be used.
// The main feed implementation is now in lib/features/feed/presentation/pages/feed_page.dart
// This file is kept only for backward compatibility and will be removed in a future version.

import 'package:flutter/material.dart';
// Existing Bottom Nav

@Deprecated('Use FeedPage instead - this class will be removed in a future version')
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @Deprecated('Use FeedPage.routeName instead')
  static const String routeName = '/feed';

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedIndex = 0; // Assume Feed is the first item (index 0)

  void _onItemTapped(int index) {
    // TODO: Implement navigation logic based on index
    // For now, just update the state to reflect the selected tab
    // In a real app, this would likely trigger navigation using GoRouter or similar
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      // Example navigation logic (replace with actual router)
      // switch (index) {
      //   case 0: // Feed - already here
      //     break;
      //   case 1: // Explore
      //     context.go('/explore'); // Assuming GoRouter
      //     break;
      //   case 2: // Create
      //     // Show create modal or navigate
      //     break;
      //   case 3: // Rituals
      //      context.go('/rituals');
      //     break;
      //   case 4: // Profile
      //      context.go('/profile');
      //     break;
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'DEPRECATED: Use FeedPage instead',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
} 