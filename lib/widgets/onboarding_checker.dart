import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// A widget that checks if onboarding is needed and redirects accordingly
class OnboardingChecker extends ConsumerWidget {
  final Widget child;

  // Static flag to prevent multiple redirects
  static bool _redirectInProgress = false;
  static DateTime? _lastRedirectAttempt;

  const OnboardingChecker({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if onboarding is needed on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingStatus(context);
    });

    return child;
  }

  void _checkOnboardingStatus(BuildContext context) {
    try {
      // Avoid checking if a redirect is already in progress
      if (_redirectInProgress) {
        debugPrint('Redirect already in progress, skipping check');
        return;
      }

      // Add debounce to prevent rapid rechecks
      final now = DateTime.now();
      if (_lastRedirectAttempt != null &&
          now.difference(_lastRedirectAttempt!).inSeconds < 2) {
        debugPrint('Redirect attempted too recently, skipping check');
        return;
      }

      // Skip onboarding check if already on onboarding page
      if (GoRouterState.of(context).matchedLocation == '/onboarding') {
        return;
      }

      // Skip check if on the home page and we've tried recently
      if (GoRouterState.of(context).matchedLocation == '/home' &&
          _lastRedirectAttempt != null &&
          now.difference(_lastRedirectAttempt!).inMinutes < 5) {
        return;
      }

      // Get current user email - if they have an email, they're likely already authenticated
      final userEmail = UserPreferencesService.getUserEmail();
      final hasUserData = userEmail.isNotEmpty;

      // If user is on home page and has user data, don't redirect to onboarding
      // This prevents authenticated users from being stuck in an onboarding loop
      if (GoRouterState.of(context).matchedLocation == '/home' && hasUserData) {
        debugPrint(
            'User on home page with email data: $userEmail - skipping onboarding redirect');
        // Mark onboarding as completed if they made it to home
        UserPreferencesService.setOnboardingCompleted(true);
        return;
      }

      // If user hasn't completed onboarding and not on auth pages, redirect to onboarding
      if (!UserPreferencesService.hasCompletedOnboarding() &&
          !_isAuthRoute(GoRouterState.of(context).matchedLocation)) {
        // Skip redirect if user is already authenticated (has email) and on a non-auth page
        // This handles the case of existing users who may have lost onboarding status
        if (hasUserData && GoRouterState.of(context).matchedLocation != '/') {
          debugPrint(
              'Authenticated user detected, marking onboarding as completed instead of redirecting');
          UserPreferencesService.setOnboardingCompleted(true);
          return;
        }

        debugPrint('Onboarding not completed, redirecting to onboarding page');
        _redirectInProgress = true;
        _lastRedirectAttempt = now;

        // Store the navigation context and route
        final currentContext = context;

        // Use Future.microtask to avoid build phase navigation errors
        Future.microtask(() {
          try {
            // Check if we should add a skip parameter
            // Check context validity before accessing GoRouterState
            if (!currentContext.mounted) return;
            final shouldSkipPreferences = _shouldAddSkipParameter(currentContext);
            final redirectPath = shouldSkipPreferences 
                ? '/onboarding?skip=true' 
                : '/onboarding';
                
            // Use the captured context for navigation
            // Check context validity again before navigation
            if (!currentContext.mounted) return;
            currentContext.go(redirectPath);
          } catch (e) {
            debugPrint('Navigation error during onboarding check: $e');
          } finally {
            _redirectInProgress = false;
          }
        });
      }
    } catch (e) {
      // If there's an error (like preferences not initialized),
      // default to showing onboarding
      debugPrint('Error checking onboarding status: $e');
      _redirectInProgress = false;
    }
  }

  bool _isAuthRoute(String route) {
    // Routes that shouldn't trigger onboarding redirect
    return route == '/' || route == '/sign-in' || route == '/create-account';
  }

  /// Determine if we should add a skip parameter based on user context
  bool _shouldAddSkipParameter(BuildContext context) {
    // Check if the user is coming from a specific flow that should skip preferences
    // For now, we'll implement a simple check based on the current route
    // Check context validity before accessing GoRouterState
    if (!context.mounted) return false; 
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    // Skip preferences if the user is coming from a deep link, app invitation, 
    // or has been in the app for a very short time
    return currentLocation == '/' ||
           currentLocation.startsWith('/link/') ||
           currentLocation.startsWith('/invite/') ||
           currentLocation.contains('share=');
  }
}
