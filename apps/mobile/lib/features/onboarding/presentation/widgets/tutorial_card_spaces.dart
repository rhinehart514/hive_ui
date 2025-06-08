import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/state/tutorial_providers.dart';

// TODO: Import HIVE theme/colors/styles
// TODO: Import reusable HIVE button component
// TODO: Import AnalyticsService

class TutorialCardSpaces extends ConsumerWidget {
  const TutorialCardSpaces({super.key});

  void _completeTutorial(BuildContext context, WidgetRef ref) {
    // TODO: Track analytics event: tutorial_completed
    print('Analytics: tutorial_completed'); // Placeholder
    ref.read(tutorialCompletionProvider.notifier).completeTutorial();
    // Pop the dialog/overlay that contains this widget
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement layout according to HIVE Design System
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Replace with actual HIVE icon/graphic (e.g., group/community)
            const Icon(Icons.groups, size: 80, color: Colors.white70),
            const SizedBox(height: 24),
            const Text(
              'Join the Conversation',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), // Placeholder style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Spaces are where communities connect. Find yours or create your own.',
              style: TextStyle(fontSize: 17, color: Colors.white70), // Placeholder style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // TODO: Replace with HIVE standard Button component
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // Placeholder color
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _completeTutorial(context, ref),
              child: const Text('Let\'s Go'),
            ),
          ],
        ),
      ),
    );
  }
} 