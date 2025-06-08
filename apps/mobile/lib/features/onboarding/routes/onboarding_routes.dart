import 'package:flutter/material.dart';
import '../presentation/screens/profile_onboarding_screen.dart';
import '../presentation/screens/tutorial_screen.dart';

/// Route names for the onboarding feature.
class OnboardingRoutes {
  OnboardingRoutes._(); // Private constructor to prevent instantiation
  
  /// The route for the profile completion onboarding flow.
  static const String profileOnboarding = '/onboarding/profile';
  
  /// The route for the onboarding tutorial after profile completion.
  static const String tutorial = '/onboarding/tutorial';
}

/// Route configurations for the onboarding feature.
class OnboardingRouteConfig {
  OnboardingRouteConfig._(); // Private constructor to prevent instantiation
  
  /// Returns the route map for the onboarding feature.
  static Map<String, WidgetBuilder> routes() {
    return {
      OnboardingRoutes.profileOnboarding: (context) => const ProfileOnboardingScreen(),
      OnboardingRoutes.tutorial: (context) => const TutorialScreen(),
    };
  }
} 