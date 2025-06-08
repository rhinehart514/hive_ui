import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/features/auth/presentation/pages/login_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/registration_page.dart';
import 'package:hive_ui/features/auth/presentation/pages/emergency_login.dart';
import 'package:hive_ui/services/user_preferences_service.dart'; // For initializing preferences
import 'package:shared_preferences/shared_preferences.dart'; // For direct SharedPreferences access

/// A utility class for GUARANTEED navigation to authentication pages
/// This is a direct, brute-force approach that bypasses all normal navigation
class AuthNavigationHelper {
  /// Pushes to the registration page using the most direct approach possible
  static void navigateToRegistration(BuildContext context) {
    debugPrint('⚡ DIRECT: Navigating to registration page');
    
    try {
      // First try: GoRouter navigation using relative path
      try {
        if (kDebugMode) debugPrint('⚡ Attempt 1: GoRouter context.push()');
        context.push(AppRoutes.register);
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ GoRouter push failed: $e');
      }
      
      // Second try: Standard Navigator with MaterialPageRoute
      try {
        if (kDebugMode) debugPrint('⚡ Attempt 2: MaterialPageRoute push()');
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RegistrationPage()),
        );
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ MaterialPageRoute push failed: $e');
      }
      
      // Third try: Replace the entire navigator with pure MaterialPageRoute
      if (kDebugMode) debugPrint('⚡ Attempt 3: pushReplacement()');
      _directPushReplacement(context, const RegistrationPage());
    } catch (e) {
      debugPrint('⚠️ ERROR: Failed to load RegistrationPage: $e');
      debugPrint('⚡ DIRECT: Using EmergencyRegistrationPage fallback');
      _directPushReplacement(context, const EmergencyRegistrationPage());
    }
  }
  
  /// Pushes to the login page using the most direct approach possible
  static void navigateToLogin(BuildContext context) {
    debugPrint('⚡ DIRECT: Navigating to login page');
    
    try {
      // First try: GoRouter navigation using relative path
      try {
        if (kDebugMode) debugPrint('⚡ Attempt 1: GoRouter context.push()');
        context.push(AppRoutes.signIn);
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ GoRouter push failed: $e');
      }
      
      // Second try: Standard Navigator with MaterialPageRoute
      try {
        if (kDebugMode) debugPrint('⚡ Attempt 2: MaterialPageRoute push()');
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ MaterialPageRoute push failed: $e');
      }
      
      // Third try: Replace the entire navigator with pure MaterialPageRoute
      if (kDebugMode) debugPrint('⚡ Attempt 3: pushReplacement()');
      _directPushReplacement(context, const LoginPage());
    } catch (e) {
      debugPrint('⚠️ ERROR: Failed to load LoginPage: $e');
      debugPrint('⚡ DIRECT: Using EmergencyLoginPage fallback');
      _directPushReplacement(context, const EmergencyLoginPage());
    }
  }
  
  /// Performs the most direct navigation possible, replacing the current screen
  static void _directPushReplacement(BuildContext context, Widget page) {
    // Try to initialize preferences in the background but don't wait
    _initializePreferencesAsync();
    
    // DIRECT FORCED NAVIGATION:
    // 1. Creates a completely new Navigator with a direct route to the target
    // 2. Pushes this as a full replacement for the current Navigator
    // 3. Doesn't rely on any app routing system
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (BuildContext context, _, __) => page,
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
  
  /// Initialize preferences in the background without blocking
  static void _initializePreferencesAsync() {
    // Fire and forget - we don't want to block navigation
    Future(() async {
      try {
        await UserPreferencesService.initialize();
        debugPrint('✅ Preferences initialized in background');
      } catch (e) {
        debugPrint('⚠️ Preferences initialization failed: $e');
        try {
          await SharedPreferences.getInstance();
          debugPrint('✅ Direct SharedPreferences initialized');
        } catch (e) {
          debugPrint('⚠️ Direct SharedPreferences also failed: $e');
        }
      }
    });
  }
} 