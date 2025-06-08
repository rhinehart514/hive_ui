import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';

/// Utility class for testing and diagnosing routing issues
class RouteDiagnostics {
  /// Tests a GoRouter navigation to the specified route
  static Future<bool> testRoute(BuildContext context, String route) async {
    bool success = false;
    try {
      // Attempt to navigate using GoRouter
      context.go(route);
      debugPrint('✅ ROUTE TEST: Successfully navigated to $route');
      success = true;
    } catch (e) {
      debugPrint('❌ ROUTE TEST: Failed to navigate to $route - Error: $e');
      success = false;
    }
    return success;
  }

  /// Tests all critical app routes and returns a diagnostic report
  static Future<Map<String, bool>> testCriticalRoutes(BuildContext context) async {
    final results = <String, bool>{};
    
    // Define critical routes to test
    final criticalRoutes = [
      AppRoutes.landing,
      AppRoutes.signIn,
      AppRoutes.register,
      AppRoutes.home,
      AppRoutes.profile,
      AppRoutes.spaces,
    ];
    
    // Test each route
    for (final route in criticalRoutes) {
      results[route] = await testRoute(context, route);
      // Add a delay to allow navigation to complete
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    return results;
  }
  
  /// Run diagnostics and log results
  static void runDiagnostics(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🧭 ROUTE DIAGNOSTICS: Starting route tests...');
      testCriticalRoutes(context).then((results) {
        debugPrint('🧭 ROUTE DIAGNOSTICS RESULTS:');
        int passCount = 0;
        int failCount = 0;
        
        results.forEach((route, success) {
          if (success) {
            passCount++;
            debugPrint('✅ $route: PASS');
          } else {
            failCount++;
            debugPrint('❌ $route: FAIL');
          }
        });
        
        final totalTests = results.length;
        final passPercentage = (passCount / totalTests) * 100;
        
        debugPrint('🧭 SUMMARY: $passCount/$totalTests tests passed (${passPercentage.toStringAsFixed(1)}%)');
        
        if (failCount > 0) {
          debugPrint('⚠️ ATTENTION: $failCount routes failed navigation tests');
        } else {
          debugPrint('🎉 SUCCESS: All routes passed navigation tests!');
        }
      });
    }
  }
} 