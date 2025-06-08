import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_admin_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/oauth_callback_page.dart';

/// Routes for settings and profile management
final List<RouteBase> _profileRoutes = [
  // ... existing routes ...
  GoRoute(
    path: 'verification/admin',
    name: 'verification_admin',
    builder: (context, state) => const VerificationAdminPage(),
  ),
  // ... existing routes ...
]; 

/// Routes for authentication
final List<RouteBase> _authRoutes = [
  // ... existing routes ...
  GoRoute(
    path: 'oauth/callback/google-edu',
    name: 'googleEduOauthCallback',
    builder: (context, state) => const OAuthCallbackPage(provider: 'google-edu'),
  ),
  // ... existing routes ...
]; 

/// Safely navigate with fallbacks to ensure navigation always works
void safeNavigate(BuildContext context, String routeName) {
  debugPrint('🧭 safeNavigate: Attempting to navigate to $routeName');
  try {
    // First try go_router navigation with go
    debugPrint('🧭 safeNavigate: Trying context.go($routeName)');
    context.go(routeName);
    debugPrint('🧭 safeNavigate: Navigation successful with context.go');
  } catch (e) {
    debugPrint('🧭 safeNavigate: Primary navigation error: $e');
    try {
      // Then try push instead of go (this often works when go fails)
      debugPrint('🧭 safeNavigate: Trying context.push($routeName)');
      context.push(routeName);
      debugPrint('🧭 safeNavigate: Navigation successful with context.push');
    } catch (e) {
      debugPrint('🧭 safeNavigate: Secondary navigation error: $e');
      try {
        // Then try named route with Navigator
        debugPrint('🧭 safeNavigate: Trying Navigator.pushNamed($routeName)');
        Navigator.of(context).pushNamed(routeName);
        debugPrint('🧭 safeNavigate: Navigation successful with Navigator.pushNamed');
      } catch (e) {
        debugPrint('🧭 safeNavigate: All navigation methods failed: $e');
        // Finally show dialog if all navigation attempts fail
        _showNavigationErrorDialog(context, routeName);
      }
    }
  }
}

/// Show a friendly error dialog if navigation fails
void _showNavigationErrorDialog(BuildContext context, String routeName) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Navigation Error'),
      content: Text('Unable to navigate to $routeName. Please try again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Logs navigation events for debugging and analytics
class HiveRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('🧭 NAVIGATION: Pushed ${route.settings.name} (from ${previousRoute?.settings.name})');
    super.didPush(route, previousRoute);
    
    // Record navigation analytics in production
    if (!kDebugMode) {
      try {
        // Analytics logging would go here
        // e.g., FirebaseAnalytics.instance.logScreenView(screenName: route.settings.name);
      } catch (e) {
        debugPrint('🧭 NAVIGATION: Analytics error $e');
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('🧭 NAVIGATION: Popped ${route.settings.name} (back to ${previousRoute?.settings.name})');
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('🧭 NAVIGATION: Removed ${route.settings.name}');
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('🧭 NAVIGATION: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
} 