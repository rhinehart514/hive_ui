import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/presentation/widgets/tutorial_card_events.dart';
import 'package:hive_ui/features/onboarding/presentation/widgets/tutorial_card_feed.dart';
import 'package:hive_ui/features/onboarding/presentation/widgets/tutorial_card_spaces.dart';
import 'package:hive_ui/features/onboarding/state/tutorial_providers.dart';
// TODO: Import AnalyticsService
// TODO: Import AppColors, Theme, reusable components

class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  final PageController _pageController = PageController();
  final List<Widget> _tutorialPages = [
    const TutorialCardFeed(), // Card 1
    // TutorialCardRituals(), // Card 2 - Hidden per decision
    const TutorialCardEvents(), // Card 3 -> Becomes Page 2
    const TutorialCardSpaces(), // Card 4 -> Becomes Page 3
  ];

  @override
  void initState() {
    super.initState();
    // TODO: Inject AnalyticsService instance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Track analytics event: tutorial_started
      print('Analytics: tutorial_started'); // Placeholder
    });

    _pageController.addListener(() {
      // Optional: Can track page changes precisely here if needed
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // TODO: Track analytics event: tutorial_card_viewed
    print('Analytics: tutorial_card_viewed, index: $index'); // Placeholder
    ref.read(tutorialPageIndexProvider.notifier).setPage(index);
  }

  void _completeTutorial() {
    // TODO: Track analytics event: tutorial_completed
    print('Analytics: tutorial_completed'); // Placeholder
    ref.read(tutorialCompletionProvider.notifier).completeTutorial();
    Navigator.of(context).pop(); // Dismiss the overlay
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Apply HIVE Brand Aesthetic (background blur, modal style)
    return Dialog(
      // Or Scaffold/Stack for more control over background/positioning
      backgroundColor: Colors.black.withOpacity(0.85), // Placeholder color
      insetPadding: EdgeInsets.zero, // Use full screen
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _tutorialPages,
            ),
          ),
          _buildProgressIndicator(),
          // TODO: Add Skip/Dismiss button?
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // TODO: Style according to HIVE Design System (maybe gold line segments?)
    final progress = ref.watch(tutorialProgressProvider);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey[800], // Placeholder
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber), // Placeholder
      ),
    );
  }
} 