import 'package:flutter/material.dart';
import '../components/event_card/event_card_example.dart';

/// Application routes definitions 
class AppRoutes {
  /// Event card example page route
  static const String eventCardExample = '/event-card-example';

  /// New routes
  static const magicLinkSent = '/magic-link-sent';
  static const verificationError = '/verification-error';

  /// New routes
  static const verifyIdentity = '/verify-identity';
  static const onboardingAccessPass = '/onboarding/access-pass';
  static const onboardingCampusDna = '/onboarding/campus-dna';
  static const adminReviewVerification = '/admin/review-verification';

  /// Core App Sections
  static const feed = '/feed';

  /// Route generator for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case eventCardExample:
        return MaterialPageRoute(builder: (_) => const EventCardExamplePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 