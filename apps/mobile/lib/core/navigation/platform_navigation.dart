import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/features/auth/presentation/pages/login_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/registration_page.dart';

/// Helper class for handling platform-specific navigation issues
class PlatformNavigation {
  /// Navigate to registration page with fallbacks for platforms with issues
  static void navigateToRegistration(BuildContext context) {
    debugPrint('🧭 PlatformNav: Navigating to registration page');
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('🧭 PlatformNav: Using direct navigation on Windows');
      _directNavigation(context, AppRoutes.register, const RegistrationPage());
    } else {
      // Standard navigation for other platforms
      try {
        debugPrint('🧭 PlatformNav: Attempting to use GoRouter');
        context.push(AppRoutes.register);
        debugPrint('✅ PlatformNav: GoRouter push succeeded');
      } catch (e) {
        debugPrint('❌ PlatformNav: GoRouter failed - $e');
        _directNavigation(context, AppRoutes.register, const RegistrationPage());
      }
    }
  }
  
  /// Navigate to sign in page with fallbacks for platforms with issues
  static void navigateToSignIn(BuildContext context) {
    debugPrint('🧭 PlatformNav: Navigating to sign in page');
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('🧭 PlatformNav: Using direct navigation on Windows');
      _directNavigation(context, AppRoutes.signIn, const LoginPage());
    } else {
      // Standard navigation for other platforms
      try {
        debugPrint('🧭 PlatformNav: Attempting to use GoRouter');
        context.push(AppRoutes.signIn);
        debugPrint('✅ PlatformNav: GoRouter push succeeded');
      } catch (e) {
        debugPrint('❌ PlatformNav: GoRouter failed - $e');
        _directNavigation(context, AppRoutes.signIn, const LoginPage());
      }
    }
  }
  
  /// Direct navigation as a last resort
  static void _directNavigation(BuildContext context, String routeName, Widget page) {
    debugPrint('🧭 PlatformNav: Using MaterialPageRoute for $routeName');
    try {
      // First try the standard MaterialPageRoute
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: RouteSettings(name: routeName),
          builder: (context) => page,
        ),
      );
      debugPrint('✅ PlatformNav: MaterialPageRoute push succeeded');
    } catch (e) {
      debugPrint('❌ PlatformNav: MaterialPageRoute failed - $e');
      
      // If that fails, try the most basic navigation possible
      debugPrint('🧭 PlatformNav: Trying direct Widget replacement');
      try {
        // This is a very direct approach for Windows platform
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            // Use the root navigator for more reliable navigation
            final navigator = Navigator.of(context, rootNavigator: true);
            debugPrint('🧭 PlatformNav: Found root navigator: ${navigator.toString()}');
            
            navigator.push(
              PageRouteBuilder(
                settings: RouteSettings(name: routeName),
                pageBuilder: (context, animation, secondaryAnimation) {
                  debugPrint('🧭 PlatformNav: Building page in PageRouteBuilder');
                  return page;
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  debugPrint('🧭 PlatformNav: Applying transition in PageRouteBuilder');
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
            debugPrint('✅ PlatformNav: PageRouteBuilder push succeeded');
          } catch (e) {
            debugPrint('❌ PlatformNav: PageRouteBuilder failed - $e');
            // Last resort - attempt to replace the entire screen
            try {
              debugPrint('🧮 PlatformNav: Attempting LAST RESORT screen replacement');
              // Try to find a Navigator ancestor
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                  settings: RouteSettings(name: routeName),
                  builder: (context) => page,
                ),
              );
              debugPrint('✅ PlatformNav: Last resort navigation succeeded');
            } catch (finalE) {
              debugPrint('💀 PlatformNav: ALL NAVIGATION APPROACHES FAILED - $finalE');
            }
          }
        });
      } catch (e) {
        debugPrint('❌ PlatformNav: All navigation attempts failed - $e');
      }
    }
  }
} 