// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/error_handling_service.dart';
import 'package:hive_ui/services/performance_service.dart';
import 'package:hive_ui/features/messaging/injection.dart';
import 'package:hive_ui/services/service_initializer.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_ui/debug/debug_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ui/services/optimized_data_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_ui/features/events/events_module.dart';
import 'dart:async';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

// Conditionally import Firebase based on platform
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
// Import real Remote Config with a prefix
import 'package:firebase_remote_config/firebase_remote_config.dart' as fb_remote_config;

// Import Firebase Crashlytics, but handle it in code for Windows platform
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Import stubs with a prefix
import 'package:hive_ui/stubs/firebase_windows_stubs.dart' as stubs;

// Core
import 'package:hive_ui/core/navigation/router_config.dart';
import 'package:hive_ui/core/navigation/routes.dart';

// Profile Feature
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';

// Config & Providers
// import 'package:workmanager/workmanager.dart';

// Add the import for messaging initializer
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';

// Add the import for our AppInitializer
import 'package:hive_ui/core/app_initializer.dart';

// Add this to the top with other imports
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';

// Add the import for the FirebaseInitTracker
import 'package:hive_ui/firebase_init_tracker.dart';

// Global provider container for accessing providers outside of widgets
late ProviderContainer _providerContainer;

/// Class to track Firebase initialization status globally
class FirebaseInitTracker {
  static bool needsInitialization = true;
  static bool isInitialized = false;

  static Future<void> ensureInitialized() async {
    if (!needsInitialization) {
      debugPrint('Firebase already initialized, skipping initialization');
      return;
    }
    
    final performanceService = _providerContainer.read(performanceServiceProvider);
    performanceService.startTrace('firebase_initialization');
    
    try {
      // Skip Firebase initialization on Windows
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint('Windows platform detected, using Firebase stubs');
        // Use our stubs for Windows platform
        stubs.FirebaseWindowsStubs.initialize(); // Initialize stubs
        await stubs.Firebase.initializeApp(); // Call the stub initializeApp
        
        needsInitialization = false;
        isInitialized = true;
        
        debugPrint('✅ Firebase stubs initialized successfully for Windows');
        performanceService.stopTrace('firebase_initialization');
        return;
      }

      debugPrint('🔥 Initializing Firebase for non-Windows platform...');
      
      // Initialize Firebase Core first as it's required for other services
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Verify initialization succeeded
      if (Firebase.apps.isEmpty) {
        debugPrint('❌ Firebase initialization failed - no apps created');
        isInitialized = false;
        performanceService.stopTrace('firebase_initialization');
        return;
      }
      
      debugPrint('✅ Firebase initialized successfully');
      needsInitialization = false;
      isInitialized = true;
      
      // Set up Crashlytics now that Firebase is initialized
      if (!kDebugMode) {
        // Set up Crashlytics for error reporting in non-debug mode
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        };
        
        // Handle errors from async code
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
      
      // Initialize Windows-specific DB if needed
      if (defaultTargetPlatform == TargetPlatform.windows) {
        RealtimeDbWindowsFix.initialize();
      }
      
      // Initialize critical Firebase services immediately and in parallel
      final criticalServicesFutures = [
        _providerContainer.read(firebaseAnalyticsServiceProvider).initialize(),
        _initializeRemoteConfig(), // Initialize Remote Config as a critical service
      ];
      
      // Start critical services immediately
      await Future.wait<void>(criticalServicesFutures);
      
      // Initialize messaging feature
      await initializeFirebaseMessaging();
      // Initialize messaging dependencies
      initializeMessaging();
      // Watch messaging initializer provider
      _providerContainer.read(messagingInitializerProvider);
      
      // Initialize non-critical services after app is visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Safely check Remote Config values using a try-catch block
        try {
          // Use real RemoteConfig if not on Windows
          if (defaultTargetPlatform != TargetPlatform.windows) {
            final remoteConfig = fb_remote_config.FirebaseRemoteConfig.instance;
            final enableLazyInit = remoteConfig.getBool('enable_lazy_initialization');
            if (enableLazyInit) {
              _initializeNonCriticalServices(_providerContainer);
            } else {
              _initializeAllServices(_providerContainer);
            }
          } else {
             // Use stub RemoteConfig on Windows
            final remoteConfig = stubs.FirebaseRemoteConfig.instance;
            final enableLazyInit = remoteConfig.getBool('enable_lazy_initialization');
             if (enableLazyInit) {
              _initializeNonCriticalServices(_providerContainer);
            } else {
              _initializeAllServices(_providerContainer);
            }
          }
        } catch (e) {
          // Handle the error gracefully
          debugPrint('Error accessing Remote Config: $e');
          // Fall back to eager initialization for all services
           _initializeAllServices(_providerContainer);
        }
      });
      
      performanceService.stopTrace('firebase_initialization');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase: $e');
      performanceService.stopTrace('firebase_initialization');
      isInitialized = false;
      _providerContainer.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
    }
  }
}

// Initialize Firebase Remote Config
Future<void> _initializeRemoteConfig() async {
  // Skip on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
     debugPrint('Skipping Remote Config initialization on Windows');
     return;
  }
  try {
    final remoteConfig = fb_remote_config.FirebaseRemoteConfig.instance;
    // Use the real RemoteConfigSettings class here
    await remoteConfig.setConfigSettings(fb_remote_config.RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Define default parameters
    await remoteConfig.setDefaults({
      'enable_optimized_caching': true,
      'cache_ttl_minutes': 60,
      'enable_debug_features': false,
      'enable_offline_mode': true,
      'enable_lazy_initialization': true, // Enable lazy loading by default
    });
    
    // Fetch new values
    await remoteConfig.fetchAndActivate();
    debugPrint('Remote config initialized and fetched');
  } catch (e) {
    debugPrint('Error initializing remote config: $e');
    // Non-fatal, continue execution
  }
}

// Helper to initialize non-critical services after the app is visible
void _initializeNonCriticalServices(ProviderContainer container) {
  // Initialize messaging and other non-critical services in the background
  unawaited(container.read(firebaseMessagingServiceProvider).initialize());
  // Initialize Firebase Database service
  unawaited(container.read(firebaseDatabaseServiceProvider).initialize());
  // Remote Config is already initialized as a critical service
  
  // Delay Crashlytics user identification to avoid blocking app startup
  unawaited(_initializeCrashlytics(container));
}

// Helper to initialize all services immediately (fallback approach)
void _initializeAllServices(ProviderContainer container) {
  unawaited(Future.wait<void>([
    container.read(firebaseMessagingServiceProvider).initialize(),
    container.read(firebaseDatabaseServiceProvider).initialize(),
    // Remote Config is already initialized as a critical service
    _initializeCrashlytics(container),
  ]));
}

// Helper to initialize Crashlytics with user info
Future<void> _initializeCrashlytics(ProviderContainer container) async {
   // Skip on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
     debugPrint('Skipping Crashlytics initialization on Windows');
     return;
  }
  try {
    final coreService = container.read(firebaseCoreServiceProvider);
    if (coreService.isUserPreferencesAvailable) {
      final profileRepo = container.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile();
      if (profile != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(profile.id);
      }
    }
  } catch (e) {
    // Safe to ignore, we just won't have user info in crash reports
    debugPrint('Could not set user identifier for Crashlytics: $e');
  }
}

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
  
  // Keep splash screen until initialization completes
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Handle Windows-specific plugins
  _handleWindowsPlugins();
  
  // Set global flag to indicate Firebase needs initialization
  FirebaseInitTracker.needsInitialization = true;
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Create the provider container
  _providerContainer = ProviderContainer(
    observers: [ProviderLogger()],
    overrides: [
      // Override the sharedPreferencesProvider with the actual instance
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );
  
  // Try to initialize Firebase early in the app lifecycle
  try {
    await FirebaseInitTracker.ensureInitialized();
    if (FirebaseInitTracker.isInitialized) {
      debugPrint('✅ Firebase initialized successfully at app startup');
    } else {
      debugPrint('⚠️ Firebase initialization failed at app startup. Will retry later.');
    }
  } catch (e) {
    debugPrint('❌ Error initializing Firebase at app startup: $e');
    // We'll try again in the app initialization provider
  }
  
  // Configure Crashlytics even before Firebase is initialized
  if (!kDebugMode) {
    // Pass all uncaught errors from the framework to Crashlytics in release mode
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Crashlytics will be initialized later, just log for now
      debugPrint('Error details: ${details.exception}');
    };
    
    // Handle errors from async code
    PlatformDispatcher.instance.onError = (error, stack) {
      // Crashlytics will be initialized later, just log for now
      debugPrint('Platform dispatcher error: $error');
      return true;
    };
  }
  
  // Set preferred device orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Enable error logging for the app
  AppErrorObserver.setup();
  
  // Launch the app with proper riverpod provider scope
  runApp(
    ProviderScope(
      parent: _providerContainer,
      observers: [ProviderLogger()],
      child: Phoenix(child: const HiveApp()),
    ),
  );
}

// Initialize Firebase and related services - optimized with parallelization
Future<bool> initializeFirebaseServices(ProviderContainer container) async {
  // Check if we've already initialized Firebase
  if (FirebaseInitTracker.isInitialized) {
    debugPrint('Firebase already initialized, skipping initialization');
    return true;
  }
  
  final performanceService = container.read(performanceServiceProvider);
  performanceService.startTrace('firebase_initialization');
  
  try {
    // Skip Firebase initialization on Windows
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('Windows platform detected, using Firebase stubs');
      // Use our stubs for Windows platform
      stubs.FirebaseWindowsStubs.initialize(); // Initialize stubs
      await stubs.Firebase.initializeApp(); // Call the stub initializeApp
      
      FirebaseInitTracker.needsInitialization = false;
      FirebaseInitTracker.isInitialized = true;
      
      debugPrint('✅ Firebase stubs initialized successfully for Windows');
      performanceService.stopTrace('firebase_initialization');
      return true;
    }

    // For non-Windows platforms, initialize the real Firebase SDK
    debugPrint('🔥 Initializing Firebase for non-Windows platform...');
    
    // Initialize Firebase Core first as it's required for other services
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Verify initialization succeeded
    if (Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase initialization failed - no apps created');
      FirebaseInitTracker.isInitialized = false;
      performanceService.stopTrace('firebase_initialization');
      return false;
    }
    
    debugPrint('✅ Firebase core initialized successfully');
    FirebaseInitTracker.needsInitialization = false;
    FirebaseInitTracker.isInitialized = true;
    
    // Try to initialize critical Firebase services in parallel
    try {
      final criticalServicesFutures = [
        container.read(firebaseAnalyticsServiceProvider).initialize(),
        _initializeRemoteConfig(),
      ];
      
      // Start critical services immediately
      await Future.wait<void>(criticalServicesFutures);
      debugPrint('Critical Firebase services initialized successfully');
    } catch (e) {
      // Non-fatal error, log but continue
      debugPrint('Error initializing critical Firebase services: $e');
    }
    
    // Initialize non-critical services based on config
    _setupNonCriticalServices(container);
    
    performanceService.stopTrace('firebase_initialization');
    return true;
  } catch (e) {
    debugPrint('❌ Error in Firebase services initialization: $e');
    performanceService.stopTrace('firebase_initialization');
    try {
      container.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
    } catch (handlerError) {
      debugPrint('Error handling service exception: $handlerError');
    }
    return false;
  }
}

// Set up non-critical Firebase services
void _setupNonCriticalServices(ProviderContainer container) {
  // Add post frame callback to initialize after the UI is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      // Select initialization strategy based on platform and config
      if (defaultTargetPlatform != TargetPlatform.windows) {
        final remoteConfig = fb_remote_config.FirebaseRemoteConfig.instance;
        final enableLazyInit = remoteConfig.getBool('enable_lazy_initialization');
        
        if (enableLazyInit) {
          _initializeNonCriticalServices(container);
        } else {
          _initializeAllServices(container);
        }
      } else {
        // Use stubs for Windows
        final remoteConfig = stubs.FirebaseRemoteConfig.instance;
        final enableLazyInit = remoteConfig.getBool('enable_lazy_initialization');
        
        if (enableLazyInit) {
          _initializeNonCriticalServices(container);
        } else {
          _initializeAllServices(container);
        }
      }
    } catch (e) {
      // Fallback to eager initialization on error
      debugPrint('Error configuring services: $e');
      _initializeAllServices(container);
    }
  });
}

// Replace the appInitializationProvider with updated version that includes AppInitializer
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('Starting app initialization...');

    // Measure startup performance
    final performanceService = ref.read(performanceServiceProvider);
    performanceService.startTrace('app_initialization');

    // Initialize state synchronization components first
    debugPrint('Initializing state synchronization components...');
    await AppInitializer.initialize();
    debugPrint('State synchronization components initialized successfully');

    // Critical path: User preferences must be loaded first
    debugPrint('Initializing UserPreferencesService...');
    await UserPreferencesService.initialize();
    debugPrint('UserPreferencesService initialized successfully');

    // Initialize Firebase services - MOST CRITICAL STEP
    debugPrint('🔥 Starting Firebase initialization - CRITICAL PATH');
    final bool firebaseInitialized = await initializeFirebaseServices(ref.container);
    
    if (!firebaseInitialized) {
      debugPrint('⚠️ CRITICAL: Firebase initialization failed. App may have auth issues.');
    } else {
      debugPrint('✅ Firebase initialized successfully. Auth system should work properly.');
    }
    
    // Check network connectivity - critical for deciding initialization path
    // Use try-catch to handle potential plugin issues
    bool isOffline = false;
    try {
      final List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();
      isOffline = connectivityResults.isEmpty || 
                  (connectivityResults.length == 1 && connectivityResults.first == ConnectivityResult.none);
      debugPrint('Connectivity check completed. Device is ${isOffline ? 'offline' : 'online'}');
    } catch (e) {
      // Handle connectivity plugin failures gracefully
      debugPrint('Connectivity check failed: $e');
      debugPrint('⚠️ Assuming device is online due to connectivity check failure');
      isOffline = false;
    }
    
    // Get app version information
    PackageInfo packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
      debugPrint('Starting ${packageInfo.appName} v${packageInfo.version}+${packageInfo.buildNumber}');
    } catch (e) {
      debugPrint('Could not retrieve package info: $e');
    }

    // Initialize profile as a parallel task - don't block on this
    try {
      unawaited(_initializeProfileInBackground(ref, isOffline));
    } catch (e) {
      debugPrint('Profile initialization error (non-critical): $e');
    }
    
    // Initialize optimized services in parallel
    try {
      final serviceInitFuture = ServiceInitializer.initializeServices();
      final dataServiceFuture = OptimizedDataService.initialize();
      final clubAdapterFuture = OptimizedClubAdapter.initialize();
      
      // Wait for these essential services to complete
      await Future.wait([serviceInitFuture, dataServiceFuture, clubAdapterFuture]);
      debugPrint('Optimized service layer initialized');
    } catch (e) {
      debugPrint('Error initializing optimized services: $e');
      // Non-fatal, continue initialization
    }

    // Pre-warm caches asynchronously after essential initialization
    if (!isOffline) {
      try {
        unawaited(_prewarmCachesInBackground(performanceService));
      } catch (e) {
        debugPrint('Cache warming error (non-critical): $e');
      }
    }

    // Initialize events module with the correct provider container
    try {
      debugPrint('Initializing events module...');
      initializeEventsModule(ref.container);
      debugPrint('Events module initialized successfully');
    } catch (e) {
      debugPrint('Error initializing events module: $e');
      ref.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
    }

    // Initialize providers that need WidgetRef access
    try {
      ref.read(appInitializerProvider);
    } catch (e) {
      debugPrint('Error initializing app initializer provider: $e');
    }
    
    performanceService.stopTrace('app_initialization');
    
    // Hide splash screen after initialization is complete
    FlutterNativeSplash.remove();
    
    return true;
  } catch (e) {
    debugPrint('Error during app initialization: $e');
    
    // Hide splash screen even if there's an error
    FlutterNativeSplash.remove();
    
    // Let the app continue with limited functionality
    return false;
  }
});

// Helper to initialize profile in background
Future<void> _initializeProfileInBackground(Ref ref, bool isOffline) async {
  try {
    debugPrint('Initializing profile providers in background...');
    final profileRepo = ref.read(profileRepositoryProvider);
    await profileRepo.getProfile();
    debugPrint('Profile providers initialized successfully');
  } catch (e) {
    debugPrint('Error initializing profile providers: $e');
    ref.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
  }
}

// Helper to prewarm caches in background
Future<void> _prewarmCachesInBackground(PerformanceService performanceService) async {
  try {
    performanceService.startTrace('cache_warmup');
    await _prewarmCaches();
    performanceService.stopTrace('cache_warmup');
  } catch (e) {
    debugPrint('Error prewarming caches: $e');
    // Non-critical, app can continue
  }
}

// Pre-warm application caches asynchronously for better user experience
Future<void> _prewarmCaches() async {
  try {
    // Try to pre-fetch spaces using a different method
    final spaces = await SpaceService.getSpaces();
    debugPrint('Pre-warmed ${spaces.length} spaces');

    // Additional pre-warming logic here
  } catch (e) {
    debugPrint('Error pre-warming caches: $e');
  }
}

// Provider for app-wide scroll behavior settings
enum ScrollBounceMode { bounce, noBounce }

final scrollModeProvider = StateProvider<ScrollBounceMode>((ref) {
  // You can change the default mode here
  return ScrollBounceMode.noBounce;
});

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

// Global app error observer
class AppErrorObserver {
  static bool _isSetup = false;

  static void setup() {
    if (_isSetup) return;
    
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      
      // Only send to crashlytics in non-debug mode and not on Windows
      if (!kDebugMode && defaultTargetPlatform != TargetPlatform.windows) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else if (!kDebugMode && defaultTargetPlatform == TargetPlatform.windows) {
        // Use stub Crashlytics on Windows release builds if needed (optional)
        stubs.FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        debugPrint('ERROR: ${details.exception}');
        debugPrint('STACK: ${details.stack}');
      }
    };
    
    _isSetup = true;
  }
}

/// HIVE application class
class HiveApp extends ConsumerWidget {
  const HiveApp({Key? key}) : super(key: key);

  // Set up device-specific settings
  void _setupDeviceSettings(BuildContext context) {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the initialized state of the app
    final isInitialized = ref.watch(appInitializationProvider);
    // Watch the router provider to get the GoRouter instance
    final router = ref.watch(routerProvider);

    // Enable debug mode in development only
    const bool enableDebugTools = true; // Always enable debug tools

    return isInitialized.when(
      data: (_) {
        // Get the scroll physics based on the user preference
        final scrollMode = ref.watch(scrollModeProvider);
        final scrollPhysics = scrollMode == ScrollBounceMode.bounce
            ? const AlwaysScrollableScrollPhysics() // With bounce
            : const ClampingScrollPhysics(); // No bounce

        // Application root with localization and routes
        return MaterialApp.router(
          debugShowCheckedModeBanner: !kReleaseMode, // Hide debug banner in release
          title: 'HIVE',
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          // Use the router instance obtained from the provider
          routerConfig: router,
          // Apply the scroll physics from user preferences
          scrollBehavior: AppScrollBehavior(scrollPhysics),
          builder: (context, child) {
            _setupDeviceSettings(context);
            
            // Apply safe area
            final wrappedChild = MediaQuery(
              // Apply font scale
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );

            // Simplified stack with only the main content
            return Stack(
              children: [
                enableDebugTools
                    ? DebugLauncher(child: wrappedChild)
                    : wrappedChild,
              ],
            );
          },
        );
      },
      error: (error, stackTrace) {
        // Show error view
        return MaterialApp(
          title: 'HIVE',
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Initializing App',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Phoenix.rebirth(context);
                    },
                    child: const Text('Restart App'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () {
        // Show loading screen
        return MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading HIVE...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ... rest of the code ...
}

// Navigation helper functions
void goToHome(BuildContext context) {
  GoRouter.of(context).go(AppRoutes.home);
}

void goToSpaces(BuildContext context) {
  GoRouter.of(context).go(AppRoutes.spaces);
}

void goToProfile(BuildContext context) {
  GoRouter.of(context).go(AppRoutes.profile);
}

void goToMessaging(BuildContext context) {
  GoRouter.of(context).go(AppRoutes.messaging);
}

void goToChatCreation(BuildContext context, {String? initialUserId}) {
  GoRouter.of(context).push(AppRoutes.createChat, extra: {
    'initialUserId': initialUserId,
  });
}

void goToChat(
  BuildContext context,
  String chatId, {
  required String chatName,
  String? chatAvatar,
  bool isGroupChat = false,
  List<String> participantIds = const [],
}) {
  GoRouter.of(context).push('/messaging/chat/$chatId', extra: {
    'chatName': chatName,
    'chatAvatar': chatAvatar,
    'isGroupChat': isGroupChat,
    'participantIds': participantIds,
  });
}

void goToOrganization(BuildContext context, String organizationId) {
  GoRouter.of(context)
      .push(AppRoutes.getOrganizationProfilePath(organizationId));
}

void goToClubSpace(BuildContext context, String clubId) {
  // Use the new space detail path with the default type for clubs
  GoRouter.of(context).push(AppRoutes.getSpaceDetailPath('student_organizations', clubId));
}

void goToHiveLab(BuildContext context) {
  GoRouter.of(context).push(AppRoutes.getHiveLabPath());
}

/// Initializes all clubs from events and stores them in Firestore
Future<void> initializeAndStoreAllClubs() async {
  debugPrint('\n======== INITIALIZING ALL CLUBS ========');

  try {
    // Initialize required services
    // Use real Firebase if not on Windows
    if (defaultTargetPlatform != TargetPlatform.windows) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Use stub Firebase on Windows
      await stubs.Firebase.initializeApp();
    }
    await UserPreferencesService.initialize();

    // Initialize optimized services
    await ServiceInitializer.initializeServices();

    // Fetch events from RSS
    debugPrint('Fetching events from RSS...');
    final events = await RssService.fetchEvents(forceRefresh: true);
    debugPrint('Fetched ${events.length} events');

    // Generate clubs from events - use original service for this specialized operation
    // but leverage optimized service for caching the results
    debugPrint('Generating clubs from events...');
    await ClubService.initialize();
    final clubs = await ClubService.generateClubsFromEvents(events);
    debugPrint('Generated ${clubs.length} clubs');

    // Store all clubs in Firestore
    debugPrint('Storing all clubs in Firestore...');
    final success = await ClubService.syncAllClubsToFirestore();

    if (success) {
      debugPrint('\n✅ SUCCESSFULLY STORED ALL CLUBS IN FIRESTORE');
      // Clear optimized cache to ensure fresh data
      await OptimizedClubAdapter.clearCache();
    } else {
      debugPrint('\n❌ FAILED TO STORE CLUBS IN FIRESTORE');
    }
  } catch (e, stackTrace) {
    debugPrint('\n❌ ERROR INITIALIZING CLUBS: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

// More compatible implementation of AppScrollBehavior
class AppScrollBehavior extends ScrollBehavior {
  final ScrollPhysics? physicsOverride;
  
  // Constructor that allows overriding the default physics
  const AppScrollBehavior([this.physicsOverride]);

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return physicsOverride ?? const BouncingScrollPhysics();
  }
}

// Provider to ensure Firebase is initialized before auth operations
final firebaseInitializationProvider = Provider<bool>((ref) {
  // This provider should only be read after appInitializationProvider completes
  final appInitialized = ref.read(appInitializationProvider).valueOrNull;
  if (appInitialized != true) {
    debugPrint('WARNING: firebaseInitializationProvider accessed before app initialization complete');
    return FirebaseInitTracker.isInitialized; // Return current state
  }
  return FirebaseInitTracker.isInitialized;
});

// Handle Windows-specific plugin issues
void _handleWindowsPlugins() {
  // Check if running on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
    debugPrint('Windows platform detected, applying plugin workarounds');
    
    // Handle connectivity_plus plugin issues
    try {
      // Set up a global error handler for missing plugin exceptions
      WidgetsFlutterBinding.ensureInitialized().platformDispatcher.onError = (error, stack) {
        // Suppress specific plugin errors on Windows
        if (error.toString().contains('MissingPluginException')) {
          if (error.toString().contains('connectivity')) {
            debugPrint('Suppressing connectivity_plus plugin error on Windows platform');
            return true; // Suppress the error
          }
          if (error.toString().contains('firebase') || 
              error.toString().contains('crashlytics') ||
              error.toString().contains('analytics')) {
            debugPrint('Suppressing Firebase plugin error on Windows platform: $error');
            return true; // Suppress the error
          }
        }
        return false; // Let other errors propagate
      };
    } catch (e) {
      debugPrint('Error setting platform dispatcher error handler: $e');
    }
    
    // Initialize stubs early
    try {
      debugPrint('Pre-initializing Firebase stubs for Windows');
      stubs.FirebaseWindowsStubs.initialize();
    } catch (e) {
      debugPrint('Error initializing Firebase stubs: $e');
    }
  }
}
