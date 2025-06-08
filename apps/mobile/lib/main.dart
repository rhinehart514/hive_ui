// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/app.dart';
import 'package:hive_ui/design_system_test_page.dart'; // DESIGN SYSTEM TEST PAGE
import 'package:hive_ui/core/initialization/app_initializer.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_ui/core/navigation/routes.dart'; // Import for AppRoutes
import 'package:hive_ui/features/auth/presentation/pages/emergency_login.dart'; // Import for EmergencyLoginPage
// Import for LoginPage
// Import for RegistrationPage

// Background task handler for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Empty implementation - background tasks currently disabled
  return;
}

// Main entry point with error handling
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // WINDOWS FIX: Explicitly disable problematic Firebase features on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
    debugPrint('🪟 Windows platform detected - applying platform-specific fixes');
    // Enable Firebase debugging but don't initialize problematic services yet
    try {
      // We'll log initialization issues but continue even if this fails
      debugPrint('🪟 Setting Firebase debug mode for Windows');
    } catch (e) {
      debugPrint('🪟 Unable to configure Firebase logging: $e');
    }
    
    // FIXED: We've resolved the button tap issues in the landing page
    // No longer need the emergency launcher bypass, but leaving a debug print
    if (kDebugMode) {
      debugPrint('🪟 Windows UI fix has been applied - using standard app launch flow');
    }
  }
  
  // Print available routes in debug mode for troubleshooting
  if (kDebugMode) {
    print('Debug: Starting app with available routes...');
    // This will print all route constants for debugging
    AppRoutes.printRoutes();
  }
  
  // Create a temporary container to potentially read providers if needed by initializer
  final container = ProviderContainer(); 
  final initializer = AppInitializer(container);
  final SharedPreferences sharedPreferences = await initializer.initializeCoreServices(widgetsBinding);
  
  // Dispose the temporary container if it was used
  container.dispose(); 
  
  // Set up a failsafe global key we can use to force navigation
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Set up an error handler that can be used as a last resort
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 CRITICAL ERROR: ${details.exception}');
    // Log to crashlytics would go here
  };

  // 🚀 DEVELOPMENT UNBLOCKED: Launch full HIVE app
  runApp(
    ProviderScope(
      observers: [
        if (kDebugMode) ProviderLogger(),
      ],
      child: Phoenix(
        child: const HiveApp(),
      ),
    ),
  );
  
  // Safety timeout for splash screen removal
  Future.delayed(const Duration(seconds: 10), () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚨 SPLASH: Safety timeout reached in main, forcing removal.');
      FlutterNativeSplash.remove();
    });
  });
}

// Utility class to observe provider logs in debug builds
class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode && provider.name != null) {
      debugPrint(
        '[${provider.name}] value: $newValue',
      );
    }
  }
}

// Emergency launcher for Windows debugging
class WindowsEmergencyDebugLauncher extends StatelessWidget {
  const WindowsEmergencyDebugLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('EMERGENCY LAUNCHER', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HIVE EMERGENCY LAUNCHER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'This is a direct launcher that bypasses regular app structure',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            // Button with most basic possible implementation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('👆 Direct button press detected in emergency launcher');
                  
                  // Show confirmation to test interactivity
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Button Pressed!'),
                      content: const Text('The button press was detected successfully.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: const Text(
                  'TEST BUTTON',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            // Second button to launch normal app
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton(
                onPressed: () {
                  debugPrint('🚀 Launching normal app from emergency launcher');
                  
                  // Launch normal app with restart
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const _NormalAppLauncher(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: const Text(
                  'LAUNCH NORMAL APP',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper to launch the normal app
class _NormalAppLauncher extends StatelessWidget {
  const _NormalAppLauncher({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Present different launch options
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('App Launch Options'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SAFE MODE LAUNCHER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'The buttons on landing page were not tappable. Try these direct navigation options:',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              // Login button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginDirectLaunch(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  minimumSize: const Size(250, 50),
                ),
                child: const Text('Go to Login Page', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              
              // Registration button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationDirectLaunch(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  minimumSize: const Size(250, 50),
                ),
                child: const Text('Go to Registration Page', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              
              // Emergency Login
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmergencyLoginPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  minimumSize: const Size(250, 50),
                ),
                child: const Text('Emergency Login Page', 
                  style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Direct launch wrappers for specific pages
class LoginDirectLaunch extends StatelessWidget {
  const LoginDirectLaunch({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Login Page Direct Launch'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Direct launch of login page would go here.\n\nImplementation needed.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class RegistrationDirectLaunch extends StatelessWidget {
  const RegistrationDirectLaunch({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Registration Page Direct Launch'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Direct launch of registration page would go here.\n\nImplementation needed.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// DESIGN SYSTEM TEST APP - Only allowed code before design system completion
class DesignSystemTestApp extends StatelessWidget {
  const DesignSystemTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HIVE Design System Test Lab',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DesignSystemTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
