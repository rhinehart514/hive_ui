import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart' as fb_remote_config;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/features/messaging/injection.dart';
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';
import 'package:hive_ui/firebase_init_tracker.dart'; // Assuming this moved or refactored
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/error_handling_service.dart';
import 'package:hive_ui/services/performance_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Handles the application's initialization sequence.
class AppInitializer {
  final ProviderContainer _container; // To read providers if needed early

  AppInitializer(this._container);

  /// Performs essential initialization before the app UI is built.
  /// Returns the SharedPreferences instance.
  Future<SharedPreferences> initializeCoreServices(WidgetsBinding widgetsBinding) async {
    debugPrint('🚀 INITIALIZER: Starting core services initialization...');

    // Keep splash screen
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    debugPrint('🚀 SPLASH: Native splash preserved by Initializer');

    // Handle Windows plugins
    _handleWindowsPlugins();

    // Reset Firebase state (consider if this belongs here or elsewhere)
    FirebaseInitTracker.needsInitialization = true;
    FirebaseInitTracker.isInitialized = false;

    // Early Firebase attempt (might remove if handled robustly later)
    await _tryInitializeFirebaseEarly();

    // Configure Crashlytics logging (before full init)
    _configureEarlyErrorHandling();

    // Set device orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
     debugPrint('📱 INITIALIZER: Preferred orientations set');

    // Enable general error logging
    AppErrorObserver.setup();
    debugPrint('❗ INITIALIZER: AppErrorObserver setup complete');

    // Initialize SharedPreferences (critical for overrides)
    final sharedPreferences = await SharedPreferences.getInstance();
    debugPrint('💾 INITIALIZER: SharedPreferences initialized');
    
    // Initialize UserPreferencesService
    try {
      debugPrint('🧩 INITIALIZER: Initializing UserPreferencesService...');
      await UserPreferencesService.initialize();
      debugPrint('✅ INITIALIZER: UserPreferencesService initialized successfully');
    } catch (e) {
      debugPrint('⚠️ INITIALIZER: Error initializing UserPreferencesService: $e');
      // Continue anyway to avoid breaking app startup
    }
    
    // Initialize platform channels for deep links
    await _initializeDeepLinkListener();

    debugPrint('✅ INITIALIZER: Core services initialization complete.');
    return sharedPreferences;
  }

  /// Performs initialization tasks after the first frame is rendered.
  Future<void> initializePostFirstFrameServices(Ref ref) async {
     debugPrint('🚀 INITIALIZER: Starting post-first-frame services initialization...');
     
     // Initialize Firebase and dependent services
     await _initializeFirebaseAndDependents(ref);

     // Example: Initialize other services that can wait
     // await ref.read(someOtherServiceProvider).initialize();

     // Remove splash screen AFTER essential post-frame init
     FlutterNativeSplash.remove();
     debugPrint('🚀 SPLASH: Splash screen removed by Initializer after post-frame setup');
     debugPrint('✅ INITIALIZER: Post-first-frame services initialization complete.');
  }
  
  // --- Private Initialization Methods ---

  void _handleWindowsPlugins() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('🪟 INITIALIZER: Handling Windows-specific plugins...');
      
      // Initialize Realtime Database Windows fix
      RealtimeDbWindowsFix.initialize(persistData: true);
      debugPrint('🪟 INITIALIZER: RealtimeDbWindowsFix initialized with persistence');
      
      // Set "initialized" flags for services that might cause issues on Windows
      // This prevents initialization loops and failures when services are checked
      debugPrint('🪟 INITIALIZER: Marking potentially problematic services as initialized on Windows');
      FirebaseInitTracker.isInitialized = true; // Prevent core Firebase init errors
      
      // Additional Windows-specific initializations can go here
      debugPrint('🪟 INITIALIZER: All Windows-specific plugins handled');
    }
  }

  Future<void> _tryInitializeFirebaseEarly() async {
     if (!FirebaseInitTracker.needsInitialization) return; // Already done?
     try {
       debugPrint('🔥 INITIALIZER: Attempting early Firebase initialization...');
       await Firebase.initializeApp(
         options: DefaultFirebaseOptions.currentPlatform,
       );
       if (Firebase.apps.isNotEmpty) {
         debugPrint('✅ INITIALIZER: Early Firebase initialization successful.');
         FirebaseInitTracker.needsInitialization = false;
         FirebaseInitTracker.isInitialized = true;
       } else {
          debugPrint('❌ INITIALIZER: Early Firebase initialization failed (no apps).');
       }
     } catch (e) {
       debugPrint('❌ INITIALIZER: Error during early Firebase initialization: $e');
     }
  }

  void _configureEarlyErrorHandling() {
    if (!kDebugMode) {
      debugPrint('🔒 INITIALIZER: Configuring early error handling for Crashlytics (Release Mode)');
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        // Log or store details if Crashlytics isn't ready
        debugPrint('EARLY FLUTTER ERROR: ${details.exception}'); 
        // Attempt to record if Crashlytics is somehow ready
         if (FirebaseInitTracker.isInitialized && defaultTargetPlatform != TargetPlatform.windows) {
           FirebaseCrashlytics.instance.recordFlutterFatalError(details);
         }
      };

      PlatformDispatcher.instance.onError = (error, stack) {
         debugPrint('EARLY PLATFORM ERROR: $error');
         // Attempt to record if Crashlytics is somehow ready
         if (FirebaseInitTracker.isInitialized && defaultTargetPlatform != TargetPlatform.windows) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
         }
        return true; // Indicate error was handled
      };
    } else {
       debugPrint('🐛 INITIALIZER: Skipping Crashlytics error handling setup (Debug Mode)');
    }
  }
  
  Future<void> _initializeDeepLinkListener() async {
     try {
       debugPrint('🔗 INITIALIZER: Initializing platform channels for deep links...');
       await getInitialLink(); // Initializes the channel
       debugPrint('✅ INITIALIZER: Platform channels initialized for deep links.');
     } catch (e) {
       debugPrint('⚠️ INITIALIZER: Error initializing deep link platform channels: $e');
     }
  }
  
  Future<void> _initializeFirebaseAndDependents(Ref ref) async {
      // Special handling for Windows platform
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint('🪟 INITIALIZER: Using Windows-specific Firebase initialization approach');
        
        // On Windows, we'll try Firebase core init but won't let it block the app
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('✅ INITIALIZER: Windows Firebase initialization successful');
          FirebaseInitTracker.isInitialized = true;
        } catch (e) {
          debugPrint('⚠️ INITIALIZER: Windows Firebase initialization failed: $e');
          // Mark as initialized anyway to prevent further attempts
          FirebaseInitTracker.isInitialized = true;
        }
        
        // Skip most Firebase dependent services on Windows, initialize only what's necessary
        debugPrint('🪟 INITIALIZER: Setting up minimal Firebase dependencies for Windows');
        
        // Initialize only essential services and skip others
        try {
          initializeMessaging(); // Basic DI setup
          debugPrint('✅ INITIALIZER: Windows-compatible service initialization complete');
        } catch (e) {
          debugPrint('⚠️ INITIALIZER: Error in Windows service initialization: $e');
        }
        
        return;
      }
      
      // Standard initialization for non-Windows platforms
      if (!FirebaseInitTracker.needsInitialization) {
        debugPrint('🔥 INITIALIZER: Firebase already initialized, skipping redundant init.');
        // Still ensure dependents are initialized if needed
        await _initializeFirebaseDependents(ref);
        return;
      }

      final performanceService = ref.read(performanceServiceProvider);
      performanceService.startTrace('firebase_initialization');
      debugPrint('🔥 INITIALIZER: Starting full Firebase initialization...');

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        if (Firebase.apps.isEmpty) {
           debugPrint('❌ INITIALIZER: Firebase initialization failed (no apps).');
           FirebaseInitTracker.isInitialized = false;
        } else {
           debugPrint('✅ INITIALIZER: Firebase successfully initialized (${Firebase.apps.length} apps).');
           FirebaseInitTracker.needsInitialization = false;
           FirebaseInitTracker.isInitialized = true;

           // Configure full error handling now
           _configureFullErrorHandling();

           // Initialize dependent services
           await _initializeFirebaseDependents(ref);
        }
      } catch (e) {
        debugPrint('❌ INITIALIZER: Error during full Firebase initialization: $e');
        FirebaseInitTracker.isInitialized = false;
        // Consider how to handle this failure - maybe notify user?
      } finally {
         performanceService.stopTrace('firebase_initialization');
      }
  }
  
   void _configureFullErrorHandling() {
      if (!kDebugMode && defaultTargetPlatform != TargetPlatform.windows) {
          debugPrint('🔒 INITIALIZER: Configuring full error handling for Crashlytics (Release Mode)');
          final originalOnError = FlutterError.onError;
          FlutterError.onError = (FlutterErrorDetails details) {
            // Call original handler if exists (e.g., presentError)
            originalOnError?.call(details);
            // Record error
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          };

          final originalPlatformOnError = PlatformDispatcher.instance.onError;
           PlatformDispatcher.instance.onError = (error, stack) {
             FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
             // Call original handler if exists, otherwise return true
             return originalPlatformOnError?.call(error, stack) ?? true;
          };
      }
   }

  Future<void> _initializeFirebaseDependents(Ref ref) async {
     debugPrint('🔥 INITIALIZER: Initializing Firebase dependent services...');
     
      // Initialize critical services in parallel
      final criticalFutures = [
        ref.read(firebaseAnalyticsServiceProvider).initialize(),
        _initializeRemoteConfig(), // Uses global instance
        // Add other critical services here
      ];
      await Future.wait<void>(criticalFutures);
      debugPrint('🔥 INITIALIZER: Critical Firebase dependents initialized.');

      // Initialize messaging feature (assuming async init)
      await initializeFirebaseMessaging(); // From messaging_initializer.dart
      
      // Initialize messaging DI setup from injection.dart
      debugPrint('💬 INITIALIZER: Setting up messaging dependency injection...');
      initializeMessaging(); 
      
      // Ensure the providers are watched/initialized
      try {
        // Initialize the messagingInitializerProvider which sets up messaging services
        debugPrint('💬 INITIALIZER: Initializing messaging providers...');
        ref.watch(messagingInitializerProvider);
        
        // Force initialization of RealtimeMessagingService by watching its provider
        // This ensures the service's initialize() method is called
        final realtimeService = ref.read(realtimeMessagingServiceProvider);
        debugPrint('💬 INITIALIZER: RealtimeMessagingService provider accessed: ${realtimeService.runtimeType}');
      } catch (e) {
        debugPrint('⚠️ INITIALIZER: Error initializing messaging providers: $e');
        // Continue anyway to avoid breaking the app
      }
      
      debugPrint('💬 INITIALIZER: Firebase Messaging initialized.');

      // Initialize other non-critical Firebase services
      // e.g., await ref.read(firestoreServiceProvider).initialize();
      debugPrint('✅ INITIALIZER: Firebase dependent services initialization complete.');
  }

  Future<void> _initializeRemoteConfig() async {
     try {
        final remoteConfig = fb_remote_config.FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(fb_remote_config.RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1), // Adjust as needed
        ));
        await remoteConfig.setDefaults(const {
            // Define default values for your Remote Config keys
            "feature_flag_example": false, 
        });
        await remoteConfig.fetchAndActivate();
        debugPrint('⚙️ INITIALIZER: Firebase Remote Config fetched and activated.');
     } catch (e) {
        debugPrint('❌ INITIALIZER: Error initializing Firebase Remote Config: $e');
     }
  }

}

// --- App Initialization Provider ---

/// Provider to manage the AppInitializer instance and trigger initialization.
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Create the initializer instance (can pass container if needed)
  final initializer = AppInitializer(ref.container);

  // Trigger post-first-frame initialization. 
  // This runs after the first build cycle completes.
  // We rely on main.dart calling initializeCoreServices before runApp.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
     await initializer.initializePostFirstFrameServices(ref);
  });

  // The FutureProvider itself doesn't need to return a complex value here,
  // as its main purpose is to trigger the post-frame initialization.
  // It resolves immediately, allowing the UI depending on it (like the router)
  // to proceed while initialization happens asynchronously via addPostFrameCallback.
  return Future.value(); 
}); 