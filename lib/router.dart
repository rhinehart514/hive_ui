import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/pages/onboarding_profile.dart';
import 'package:hive_ui/pages/auth/create_account.dart';

final router = GoRouter(
  initialLocation: '/create-account',
  routes: [
    GoRoute(
      path: '/create-account',
      builder: (context, state) => const CreateAccountPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingProfilePage(),
    ),
  ],
);

// Navigation helper functions
void goToOnboarding(BuildContext context) {
  GoRouter.of(context).go('/onboarding');
} 