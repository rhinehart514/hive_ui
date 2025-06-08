import 'package:flutter/material.dart';

// TODO: Import HIVE theme/colors/styles

class TutorialCardEvents extends StatelessWidget {
  const TutorialCardEvents({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement layout according to HIVE Design System
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Replace with actual HIVE icon/graphic (e.g., calendar)
            Icon(Icons.event, size: 80, color: Colors.white70),
            SizedBox(height: 24),
            Text(
              'Find Your Next Event',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), // Placeholder style
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Browse upcoming events, RSVP, and see who\'s going.',
              style: TextStyle(fontSize: 17, color: Colors.white70), // Placeholder style
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 