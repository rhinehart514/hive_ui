import 'package:flutter/material.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_request_page.dart';

/// Routes for the app
class AppRouter {
  /// Routes for different sections
  
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Home routes
  static const String home = '/';
  static const String feed = '/feed';
  
  // Profile routes
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileAnalytics = '/profile/analytics';
  static const String profileVerification = '/profile/verification';
  
  // Space routes
  static const String spaces = '/spaces';
  static const String spaceDetails = '/spaces/:id';
  static const String createSpace = '/spaces/create';
  
  // Event routes
  static const String events = '/events';
  static const String eventDetails = '/events/:id';
  static const String createEvent = '/events/create';
  
  /// Get routes for the app
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      profileVerification: (context) => const VerificationRequestPage(),
      // Add other routes here
    };
  }
  
  /// Navigate to the verification page
  static void navigateToVerification(BuildContext context) {
    Navigator.of(context).pushNamed(profileVerification);
  }
} 