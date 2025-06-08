import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive_ui/features/onboarding/presentation/widgets/onboarding_progress_indicator.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_state.dart';

void main() {
  late ProviderContainer container;
  
  setUp(() {
    container = ProviderContainer(
      overrides: [
        currentPageIndexProvider.overrideWith((ref) => 0),
        completionPercentageProvider.overrideWith((ref) => 1 / OnboardingState.totalPages),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  testGoldens('OnboardingProgressIndicator displays correctly at step 1', (tester) async {
    await loadAppFonts();
    
    // Create a test wrapper for the OnboardingProgressIndicator
    final testWidget = MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: UncontrolledProviderScope(
          container: container,
          child: const Center(
            child: OnboardingProgressIndicator(),
          ),
        ),
      ),
    );

    // Build the widget
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Verify golden image
    await screenMatchesGolden(tester, 'onboarding_progress_indicator_step1');
  });

  testGoldens('OnboardingProgressIndicator displays correctly at step 3', (tester) async {
    await loadAppFonts();
    
    // Update the container with new provider overrides for step 3
    container = ProviderContainer(
      overrides: [
        currentPageIndexProvider.overrideWith((ref) => 2), // third step (0-based index)
        completionPercentageProvider.overrideWith((ref) => 3 / OnboardingState.totalPages),
      ],
    );
    
    // Create a test wrapper for the OnboardingProgressIndicator
    final testWidget = MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: UncontrolledProviderScope(
          container: container,
          child: const Center(
            child: OnboardingProgressIndicator(),
          ),
        ),
      ),
    );

    // Build the widget
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Verify golden image
    await screenMatchesGolden(tester, 'onboarding_progress_indicator_step3');
  });

  testGoldens('OnboardingProgressIndicator displays correctly at final step', (tester) async {
    await loadAppFonts();
    
    // Update the container with new provider overrides for final step
    container = ProviderContainer(
      overrides: [
        currentPageIndexProvider.overrideWith((ref) => OnboardingState.totalPages - 1),
        completionPercentageProvider.overrideWith((ref) => 1.0),
      ],
    );
    
    // Create a test wrapper for the OnboardingProgressIndicator
    final testWidget = MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: UncontrolledProviderScope(
          container: container,
          child: const Center(
            child: OnboardingProgressIndicator(),
          ),
        ),
      ),
    );

    // Build the widget
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Verify golden image
    await screenMatchesGolden(tester, 'onboarding_progress_indicator_final');
  });
} 