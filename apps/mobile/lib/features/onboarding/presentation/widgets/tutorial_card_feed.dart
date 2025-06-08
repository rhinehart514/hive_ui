import 'package:flutter/material.dart';

// TODO: Import HIVE theme/colors/styles

class TutorialCardFeed extends StatelessWidget {
  const TutorialCardFeed({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement layout according to HIVE Design System
    // Use AppColors.text, standard padding, SF Pro font styles, etc.
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Replace with actual HIVE icon/graphic
            Icon(Icons.dynamic_feed, size: 80, color: Colors.white70),
            SizedBox(height: 24),
            Text(
              'Welcome to the Feed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), // Placeholder style
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Discover events, updates, and what\'s happening in your spaces.',
              style: TextStyle(fontSize: 17, color: Colors.white70), // Placeholder style
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 