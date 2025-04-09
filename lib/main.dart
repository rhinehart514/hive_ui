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
import 'package:hive_ui/stubs/firebase_windows_stubs.dart' as stubs; // Used for error handling on Windows

// Core
import 'package:hive_ui/core/navigation/router_config.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/deep_link_service.dart';

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

import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth_features;
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Class to track Firebase initialization status globally
class FirebaseInitTracker {
  static bool needsInitialization = true;
  static bool isInitialized = false;
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
  
  // Reset Firebase initialization state
  FirebaseInitTracker.needsInitialization = true;
  FirebaseInitTracker.isInitialized = false;
  
  // Try to initialize Firebase early
  try {
    debugPrint('🔥 Performing early Firebase initialization...');
    
    // Initialize real Firebase for all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Verify initialization succeeded
    if (Firebase.apps.isEmpty) {
      debugPrint('❌ Early Firebase initialization failed - no apps created');
    } else {
      debugPrint('✅ Early Firebase initialization successful with app count: ${Firebase.apps.length}');
      FirebaseInitTracker.needsInitialization = false;
      FirebaseInitTracker.isInitialized = true;
    }
  } catch (e) {
    debugPrint('❌ Error during early Firebase initialization: $e');
    // Will retry during appInitializationProvider
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
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Launch the app with proper riverpod provider scope
  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      overrides: [
        // Override the sharedPreferencesProvider with the actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: Phoenix(child: const HiveApp()),
    ),
  );
}

// Initialize Firebase and related services - optimized with parallelization
Future<bool> initializeFirebaseServices(Ref ref) async {
  // Check if we've already initialized Firebase
  if (!FirebaseInitTracker.needsInitialization) {
    debugPrint('Firebase already initialized, skipping initialization');
    return FirebaseInitTracker.isInitialized;
  }
  
  final performanceService = ref.read(performanceServiceProvider);
  performanceService.startTrace('firebase_initialization');
  
  try {
    // Initialize Firebase regardless of platform
    debugPrint('Initializing Firebase with default options');
    
    // Always use real Firebase, not stubs
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
    
    debugPrint('✅ Firebase initialized successfully with app count: ${Firebase.apps.length}');
    FirebaseInitTracker.needsInitialization = false;
    FirebaseInitTracker.isInitialized = true;
    
    // Set up Crashlytics now that Firebase is initialized (if not on Windows)
    if (!kDebugMode && defaultTargetPlatform != TargetPlatform.windows) {
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
      ref.read(firebaseAnalyticsServiceProvider).initialize(),
      _initializeRemoteConfig(), // Initialize Remote Config as a critical service
    ];
    
    // Start critical services immediately
    await Future.wait<void>(criticalServicesFutures);
    
    // Initialize messaging feature
    await initializeFirebaseMessaging();
    // Initialize messaging dependencies
    initializeMessaging();
    // Watch messaging initializer provider
    ref.watch(messagingInitializerProvider);
    
    // Initialize non-critical services after app is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safely check Remote Config values using a try-catch block
      try {
        final remoteConfig = fb_remote_config.FirebaseRemoteConfig.instance;
        // Use getInt with a default value and handle potential nulls more robustly
        // Assuming 'enable_lazy_initialization' might not be set or fetched correctly.
        // Defaulting to false (eager loading) seems safer if config fails.
        final enableLazyInit = remoteConfig.getBool('enable_lazy_initialization'); 

        if (enableLazyInit) {
          _initializeNonCriticalServices(ref);
        } else {
          // Eagerly initialize all services if flag is false or unset
          _initializeAllServices(ref);
        }
      } catch (e) {
        // Handle the error gracefully
        debugPrint('Error accessing Remote Config (enable_lazy_initialization): $e. Defaulting to eager initialization.');
        // Fall back to eager initialization for all services
        _initializeAllServices(ref);
      }
    });
    
    performanceService.stopTrace('firebase_initialization');
    return true;
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
    performanceService.stopTrace('firebase_initialization');
    FirebaseInitTracker.isInitialized = false;
    ref.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
    return false;
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
void _initializeNonCriticalServices(Ref ref) {
  // Initialize messaging and other non-critical services in the background
  unawaited(ref.read(firebaseMessagingServiceProvider).initialize());
  // Initialize Firebase Database service
  unawaited(ref.read(firebaseDatabaseServiceProvider).initialize());
  // Remote Config is already initialized as a critical service
  
  // Delay Crashlytics user identification to avoid blocking app startup
  unawaited(_initializeCrashlytics(ref));
}

// Helper to initialize all services immediately (fallback approach)
void _initializeAllServices(Ref ref) {
  unawaited(Future.wait<void>([
    ref.read(firebaseMessagingServiceProvider).initialize(),
    ref.read(firebaseDatabaseServiceProvider).initialize(),
    // Remote Config is already initialized as a critical service
    _initializeCrashlytics(ref),
  ]));
}

// Helper to initialize Crashlytics with user info
Future<void> _initializeCrashlytics(Ref ref) async {
   // Skip on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
     debugPrint('Skipping Crashlytics initialization on Windows');
     return;
  }
  try {
    final coreService = ref.read(firebaseCoreServiceProvider);
    if (coreService.isUserPreferencesAvailable) {
      final profileRepo = ref.read(profileRepositoryProvider);
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
    // Set FirebaseInitTracker flags properly before initialization
    FirebaseInitTracker.needsInitialization = true;
    FirebaseInitTracker.isInitialized = false;
    
    final firebaseInitialized = await initializeFirebaseServices(ref);
    
    if (!firebaseInitialized) {
      debugPrint('⚠️ CRITICAL: Firebase initialization failed. App may have auth issues.');
    } else {
      debugPrint('✅ Firebase initialized successfully. Auth system should work properly.');
      
      // Mark Firebase as initialized globally so all repositories can use it
      FirebaseInitTracker.isInitialized = true;
      FirebaseInitTracker.needsInitialization = false;
      debugPrint('🌐 Firebase initialization status broadcast to all repositories');
    }
    
    // Check network connectivity - critical for deciding initialization path
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isOffline = connectivityResult == ConnectivityResult.none;
    
    // Get app version information
    final packageInfo = await PackageInfo.fromPlatform();
    debugPrint('Starting ${packageInfo.appName} v${packageInfo.version}+${packageInfo.buildNumber}');

    // Initialize profile as a parallel task - don't block on this
    unawaited(_initializeProfileInBackground(ref, isOffline));
    
    // Initialize optimized services in parallel
    final serviceInitFuture = ServiceInitializer.initializeServices();
    final dataServiceFuture = OptimizedDataService.initialize();
    final clubAdapterFuture = OptimizedClubAdapter.initialize();
    
    // Wait for these essential services to complete
    await Future.wait([serviceInitFuture, dataServiceFuture, clubAdapterFuture]);
    debugPrint('Optimized service layer initialized');

    // Pre-warm caches asynchronously after essential initialization
    if (!isOffline) {
      unawaited(_prewarmCachesInBackground(performanceService));
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
    ref.read(appInitializerProvider);
    
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
class HiveApp extends ConsumerStatefulWidget {
  const HiveApp({Key? key}) : super(key: key);

  @override
  ConsumerState<HiveApp> createState() => _HiveAppState();
}

class _HiveAppState extends ConsumerState<HiveApp> {
  final _streamSubscriptions = <StreamSubscription>[];
  bool _listenersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize app services that don't need ref.listen
    _initializeAppServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // We'll no longer setup listeners here as it's causing issues
    // Instead, we'll use ref.listen in the build method
  }

  Future<void> _initializeAppServices() async {
    // Initialize deep link service
    ref.read(deepLinkServiceProvider).initialize();
    
    // ... other service initialization that doesn't use ref.listen ...
  }

  // Loading screen widget
  Widget _buildLoadingScreen() {
    return const Scaffold(
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
    );
  }

  // Error screen widget
  Widget _buildErrorScreen(Object error) {
    return Scaffold(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Setup listeners in the build method, which is the correct place for ref.listen
    // Add a listener to the auth state to process pending deep links
    ref.listen(auth_features.authStateProvider, (previous, next) {
      // If user just got authenticated
      if (previous is AsyncLoading && next is AsyncData && next.value != null && next.value!.isNotEmpty) {
        // Check if onboarding is complete before processing deep links
        final isOnboardingComplete = UserPreferencesService.hasCompletedOnboarding();
        final hasAcceptedTerms = ref.read(userPreferencesProvider).hasAcceptedTerms;
        
        if (isOnboardingComplete && hasAcceptedTerms) {
          // Process any pending deep links
          ref.read(deepLinkServiceProvider).processPendingDeepLink();
        }
      }
    });
    
    // Listen to onboarding completion to process pending deep links
    ref.listen(userPreferencesProvider, (previous, next) {
      if (previous != null && next != null) {
        final prevTerms = previous.hasAcceptedTerms;
        final nextTerms = next.hasAcceptedTerms;
        
        // If terms just got accepted
        if (!prevTerms && nextTerms) {
          // Check if onboarding is also complete
          final isOnboardingComplete = UserPreferencesService.hasCompletedOnboarding();
          
          if (isOnboardingComplete) {
            // Process any pending deep links
            ref.read(deepLinkServiceProvider).processPendingDeepLink();
          }
        }
      }
    });
    
    // Original implementation from HiveApp's build method
    // Watch app initialization state
    final appInitializationState = ref.watch(appInitializationProvider);
    final routeState = ref.watch(routerProvider);
    
    return appInitializationState.when(
      data: (status) {
        // Hide splash screen after initialization
        if (status) FlutterNativeSplash.remove();
        
        return MaterialApp.router(
          routerConfig: routeState,
          title: 'Hive',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,
        );
      },
      loading: () => MaterialApp(
        home: _buildLoadingScreen(),
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
      ),
      error: (error, stackTrace) => MaterialApp(
        home: _buildErrorScreen(error),
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
      ),
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
  
  // Alternatively, if we need to maintain old URLs during transition:
  // GoRouter.of(context).push(AppRoutes.getLegacyClubSpacePath(clubId));
}

void goToHiveLab(BuildContext context) {
  GoRouter.of(context).push(AppRoutes.getHiveLabPath());
}

/// Initializes all clubs from events and stores them in Firestore
Future<void> initializeAndStoreAllClubs() async {
  debugPrint('\n======== INITIALIZING ALL CLUBS ========');

  try {
    // Initialize required services - always use real Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
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
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

// Provider to ensure Firebase is initialized before auth operations
final firebaseInitializationProvider = Provider<bool>((ref) {
  return FirebaseInitTracker.isInitialized;
});

// Provider that returns a Future for verifying Firebase initialization
final firebaseVerificationProvider = FutureProvider<bool>((ref) async {
  try {
    // Import the verification function from firebase_services.dart
    final isInitialized = await verifyFirebaseInitialization();
    debugPrint('Firebase verification complete. Initialized: $isInitialized');
    return isInitialized;
  } catch (e) {
    debugPrint('Error verifying Firebase initialization: $e');
    return false;
  }
});

// Handle Windows-specific plugin issues
void _handleWindowsPlugins() {
  // Check if running on Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
    debugPrint('Windows platform detected, applying plugin workarounds');
    
    // Handle connectivity_plus plugin issues
    try {
      WidgetsFlutterBinding.ensureInitialized().platformDispatcher.onError = (error, stack) {
        if (error.toString().contains('MissingPluginException') && 
            error.toString().contains('connectivity_status')) {
          debugPrint('Suppressing connectivity_plus plugin error on Windows platform');
          return true; // Suppress the error
        }
        return false; // Let other errors propagate - including Firebase ones
      };
    } catch (e) {
      debugPrint('Error setting platform dispatcher error handler: $e');
    }
  }
}
