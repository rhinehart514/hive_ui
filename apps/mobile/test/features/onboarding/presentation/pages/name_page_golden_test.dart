
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/name_page.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_state.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_state_notifier.dart';
import 'package:mockito/mockito.dart';

class MockOnboardingStateNotifier extends StateNotifier<OnboardingState> 
    with Mock implements OnboardingStateNotifier {
  MockOnboardingStateNotifier(super.state);
  
  @override
  void updateName(String firstName, String lastName) {}
  
  @override
  bool goToNextPage({bool forceNavigation = false}) => true;
}

void main() {
  late ProviderContainer container;
  
  setUp(() {
    const mockState = OnboardingState(
      firstName: '',
      lastName: '',
      currentPageIndex: 0,
    );
    
    container = ProviderContainer(
      overrides: [
        onboardingStateNotifierProvider.overrideWithProvider(
          StateNotifierProvider<OnboardingStateNotifier, OnboardingState>(
            (ref) => MockOnboardingStateNotifier(mockState),
          ),
        ),
        isCurrentPageValidProvider.overrideWith((ref) => false),
        currentPageIndexProvider.overrideWith((ref) => 0),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  testGoldens('NamePage displays correctly with empty fields', (tester) async {
    await loadAppFonts();
    
    // Create the widget under test
    final testWidget = MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: UncontrolledProviderScope(
          container: container,
          child: const NamePage(),
        ),
      ),
    );

    // Build the widget
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Verify golden image
    await screenMatchesGolden(tester, 'name_page_empty');
  });

  testGoldens('NamePage displays correctly with filled fields', (tester) async {
    await loadAppFonts();
    
    // Create a state with pre-filled values
    const mockState = OnboardingState(
      firstName: 'John',
      lastName: 'Doe',
      currentPageIndex: 0,
    );
    
    // Create a new container with the updated state
    final filledContainer = ProviderContainer(
      overrides: [
        onboardingStateNotifierProvider.overrideWithProvider(
          StateNotifierProvider<OnboardingStateNotifier, OnboardingState>(
            (ref) => MockOnboardingStateNotifier(mockState),
          ),
        ),
        isCurrentPageValidProvider.overrideWith((ref) => true),
        currentPageIndexProvider.overrideWith((ref) => 0),
      ],
    );
    
    // Create the widget under test
    final testWidget = MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: UncontrolledProviderScope(
          container: filledContainer,
          child: const NamePage(),
        ),
      ),
    );

    // Build the widget
    await tester.pumpWidget(testWidget);
    
    // Allow time for the widget to fully initialize and populate fields
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify golden image
    await screenMatchesGolden(tester, 'name_page_filled');
    
    // Dispose the container
    filledContainer.dispose();
  });

  testGoldens('NamePage displays validation errors when empty fields are submitted', (tester) async {
    await loadAppFonts();
    
    // Create the widget under test
    final testWidget = MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: UncontrolledProviderScope(
          container: container,
          child: const NamePage(),
        ),
      ),
    );

    // Build the widget
    await tester.pumpWidget(testWidget);
    
    // Simulate field interactions to trigger validation errors
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    
    // Tap the second field and leave it empty too
    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    
    // Allow time for animations to complete
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify golden image with error states
    await screenMatchesGolden(tester, 'name_page_errors');
  });
} 