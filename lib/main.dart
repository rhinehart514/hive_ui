// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/services/error_handling_service.dart';
import 'package:hive_ui/services/performance_service.dart';
import 'package:hive_ui/features/messaging/injection.dart';
import 'package:hive_ui/services/service_initializer.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_ui/debug/debug_launcher.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ui/services/optimized_data_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_ui/features/events/events_module.dart';
import 'dart:async';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

// Core
import 'package:hive_ui/core/navigation/router_config.dart';
import 'package:hive_ui/core/navigation/routes.dart';

// Profile Feature
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';

// Config & Providers
// import 'package:workmanager/workmanager.dart';
import 'package:hive_ui/features/settings/presentation/providers/settings_providers.dart' 
    as feature_settings;

// Add the import for messaging initializer
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';

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
  
  // Configure Crashlytics even before Firebase is initialized
  if (!kDebugMode) {
    // Pass all uncaught errors from the framework to Crashlytics in release mode
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
      observers: [ProviderLogger()],
      child: Phoenix(child: const HiveApp()),
    ),
  );
}

// Initialize Firebase and related services - optimized with parallelization
Future<bool> initializeFirebaseServices(Ref ref) async {
  final performanceService = ref.read(performanceServiceProvider);
  performanceService.startTrace('firebase_initialization');
  
  try {
    final coreService = ref.read(firebaseCoreServiceProvider);
    
    // Initialize Firebase Core first as it's required for other services
    final firebaseInitialized = await coreService.initializeWithRetry(maxRetries: 3);

    if (firebaseInitialized) {
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
          final remoteConfig = FirebaseRemoteConfig.instance;
          final enableLazyInit = remoteConfig.getBool('enable_lazy_initialization');
          if (enableLazyInit) {
            _initializeNonCriticalServices(ref);
          } else {
            // Fall back to eager initialization for all services
            _initializeAllServices(ref);
          }
        } catch (e) {
          // Handle the error gracefully
          debugPrint('Error accessing Remote Config: $e');
          // Fall back to eager initialization for all services
          _initializeAllServices(ref);
        }
      });
      
      performanceService.stopTrace('firebase_initialization');
      return true;
    }

    performanceService.stopTrace('firebase_initialization');
    ref.read(errorHandlingServiceProvider).handleError('Firebase initialization failed', type: ErrorType.general);
    return false;
  } catch (e) {
    performanceService.stopTrace('firebase_initialization');
    ref.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
    return false;
  }
}

// Initialize Firebase Remote Config
Future<void> _initializeRemoteConfig() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
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
  // Remote Config is already initialized as a critical service
  
  // Delay Crashlytics user identification to avoid blocking app startup
  unawaited(_initializeCrashlytics(ref));
}

// Helper to initialize all services immediately (fallback approach)
void _initializeAllServices(Ref ref) {
  unawaited(Future.wait<void>([
    ref.read(firebaseMessagingServiceProvider).initialize(),
    // Remote Config is already initialized as a critical service
    _initializeCrashlytics(ref),
  ]));
}

// Helper to initialize Crashlytics with user info
Future<void> _initializeCrashlytics(Ref ref) async {
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

// Provider to handle app initialization tasks - optimized with priority-based initialization
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('Starting app initialization...');

    // Measure startup performance
    final performanceService = ref.read(performanceServiceProvider);
    performanceService.startTrace('app_initialization');

    // Critical path: User preferences must be loaded first
    debugPrint('Initializing UserPreferencesService...');
    await UserPreferencesService.initialize();
    debugPrint('UserPreferencesService initialized successfully');

    // Initialize Firebase services
    final firebaseInitialized = await initializeFirebaseServices(ref);
    
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

    // Initialize RSS service for feed
    // RssService.initialize();
    
    // Initialize events module with the correct provider container
    try {
      debugPrint('Initializing events module...');
      initializeEventsModule(ref.container);
      debugPrint('Events module initialized successfully');
    } catch (e) {
      debugPrint('Error initializing events module: $e');
      ref.read(errorHandlingServiceProvider).handleError(e, type: ErrorType.general);
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
      
      // Only send to crashlytics in non-debug mode
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
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

    // Enable debug mode in development only
    const bool enableDebugTools = true; // Always enable debug tools

    return isInitialized.when(
      data: (_) {
        // Setup scroll physics based on platform
        final ScrollPhysics scrollPhysics = ref.watch(scrollModeProvider) == ScrollBounceMode.bounce
            ? const AlwaysScrollableScrollPhysics() // With bounce
            : const ClampingScrollPhysics(); // No bounce

        // Application root with localization and routes
        return MaterialApp.router(
          debugShowCheckedModeBanner: !kReleaseMode, // Hide debug banner in release
          title: 'HIVE',
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
          scrollBehavior: AppScrollBehavior(),
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
    // Initialize required services
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
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
