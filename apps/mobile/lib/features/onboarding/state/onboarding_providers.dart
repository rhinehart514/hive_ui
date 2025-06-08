import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_state.dart';
import 'onboarding_state_notifier.dart';

/// Provider for the onboarding state notifier.
final onboardingStateNotifierProvider = StateNotifierProvider<OnboardingStateNotifier, OnboardingState>((ref) {
  return OnboardingStateNotifier();
});

/// Provider for a shared page controller to ensure consistent page changes
final onboardingPageControllerProvider = Provider<PageController>((ref) {
  final initialIndex = ref.watch(currentPageIndexProvider);
  final controller = PageController(initialPage: initialIndex);
  
  ref.onDispose(() {
    controller.dispose();
  });
  
  return controller;
});

/// Provider for the current page index in the onboarding flow.
final currentPageIndexProvider = Provider<int>((ref) {
  return ref.watch(onboardingStateNotifierProvider).currentPageIndex;
});

/// Provider that determines if the current page data is valid.
final isCurrentPageValidProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingStateNotifierProvider);
  return state.isCurrentPageValid();
});

/// Provider that determines if the user can go to the previous page.
final canGoBackProvider = Provider<bool>((ref) {
  final currentIndex = ref.watch(currentPageIndexProvider);
  return currentIndex > 0;
});

/// Provider that determines if the user can go to the next page.
final canGoForwardProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingStateNotifierProvider);
  final isValid = state.isCurrentPageValid();
  final notLastPage = state.currentPageIndex < OnboardingState.totalPages - 1;
  final canProceed = isValid && notLastPage;
  
  debugPrint('canGoForwardProvider: Page ${state.currentPageIndex} - Valid: $isValid, Not Last Page: $notLastPage, Can Proceed: $canProceed');
  
  return canProceed;
});

/// Provider that calculates the completion percentage of the onboarding process.
final completionPercentageProvider = Provider<double>((ref) {
  final currentIndex = ref.watch(currentPageIndexProvider);
  return (currentIndex + 1) / OnboardingState.totalPages;
}); 