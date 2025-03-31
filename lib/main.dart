// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_ui/theme/app_theme.dart';
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

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
import 'package:hive_ui/providers/settings_provider.dart' hide AppTheme, sharedPreferencesProvider;
import 'package:hive_ui/features/settings/presentation/providers/settings_providers.dart' 
    as feature_settings;
import 'providers/app_startup_provider.dart';

// Add the import for messaging initializer
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';

// Background task handler for Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Empty implementation - background tasks currently disabled
  return;
}

// Initialize Firebase and related services
Future<bool> initializeFirebaseServices(FutureProviderRef<bool> ref) async {
  try {
    final coreService = ref.read(firebaseCoreServiceProvider);
    final firebaseInitialized =
        await coreService.initializeWithRetry(maxRetries: 5);

    if (firebaseInitialized) {
      // Initialize Firebase Realtime Database explicitly for Windows
      if (defaultTargetPlatform == TargetPlatform.windows) {
        RealtimeDatabaseWindowsFix.initialize();
      }
      
      // Initialize other Firebase services concurrently
      await Future.wait<void>([
        ref.read(firebaseAnalyticsServiceProvider).initialize(),
        ref.read(firebaseMessagingServiceProvider).initialize(),
      ]);
      return true;
    }

    return false;
  } catch (e) {
    ref
        .read(errorHandlingServiceProvider)
        .handleError(e, type: ErrorType.general);
    return false;
  }
}

// Provider to handle app initialization tasks
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('Starting app initialization...');

    // Initialize analytics service - start timing
    final performanceService = ref.read(performanceServiceProvider);
    performanceService.startTrace('app_initialization');

    // Start the critical path services first
    await UserPreferencesService.initialize();

    // Initialize profile providers
    try {
      debugPrint('Initializing profile providers...');
      // Pre-fetch current user profile to cache
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.getProfile();
      debugPrint('Profile providers initialized successfully');
    } catch (profileError) {
      debugPrint('Error initializing profile providers: $profileError');
      ref
          .read(errorHandlingServiceProvider)
          .handleError(profileError, type: ErrorType.general);
    }

    // Initialize Firebase services
    final firebaseInitialized = await initializeFirebaseServices(ref);
    if (!firebaseInitialized) {
      ref.read(errorHandlingServiceProvider).reportUserError(
          'Firebase services unavailable',
          type: ErrorType.network);
    }

    // Initialize optimized services
    await ServiceInitializer.initializeServices();
    debugPrint('Optimized service layer initialized');

    // Initialize clubs from Firestore first
    try {
      debugPrint('Loading clubs using optimized service...');
      final clubs = await OptimizedClubAdapter.getAllClubs();
      debugPrint('Loaded ${clubs.length} clubs with optimized service');
    } catch (clubError) {
      // Log error but don't block app startup
      ref
          .read(errorHandlingServiceProvider)
          .handleError(clubError, type: ErrorType.general);

      // Fall back to the original service if needed
      try {
        debugPrint('Falling back to original club service...');
        await ClubService.initialize();
        final clubs = await ClubService.loadClubsFromFirestore();
        debugPrint('Loaded ${clubs.length} clubs from fallback service');
      } catch (fallbackError) {
        // Log the fallback error but continue app initialization
        ref
            .read(errorHandlingServiceProvider)
            .handleError(fallbackError, type: ErrorType.general);
      }
    }

    // Initialize other Firebase-dependent services concurrently
    try {
      // Run these operations concurrently to speed up initialization
      await Future.wait([
        SpaceService.initSettings(),
        Future<bool>(() {
          try {
            initializeMessaging();
            return true;
          } catch (e) {
            ref.read(errorHandlingServiceProvider).reportUserError(
                'Failed to initialize messaging',
                type: ErrorType.general);
            return false;
          }
        }),
        Future<bool>(() async {
          try {
            await AnalyticsService().initialize();
            return true;
          } catch (e) {
            // Non-critical - fail silently in production
            return false;
          }
        }),
      ]);

      debugPrint('Concurrent service initialization completed');
    } catch (e) {
      // Non-fatal error, continue with degraded functionality
      ref
          .read(errorHandlingServiceProvider)
          .handleError(e, type: ErrorType.general);
    }

    performanceService.stopTrace('app_initialization');
    debugPrint('App initialization completed successfully');
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    ref
        .read(errorHandlingServiceProvider)
        .handleError(e, stackTrace: stackTrace, type: ErrorType.general);
    ref.read(performanceServiceProvider).stopTrace('app_initialization');

    // For production, we want to allow the app to start even with initialization errors
    return true;
  }
});

// Provider for app-wide scroll behavior settings
enum ScrollBounceMode { bounce, noBounce }

final scrollModeProvider = StateProvider<ScrollBounceMode>((ref) {
  // You can change the default mode here
  return ScrollBounceMode.noBounce;
});

/// Custom scroll behavior for the app
class AppScrollBehavior extends ScrollBehavior {
  final ScrollPhysics _physics;

  AppScrollBehavior(this._physics);

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return _physics;
  }
}

void main() async {
  // Ensure proper initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Realtime Database for Windows
  if (defaultTargetPlatform == TargetPlatform.windows) {
    RealtimeDatabaseWindowsFix.initialize();
  }
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Lock orientation to portrait mode for consistent UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay styles
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Create a container for initializing providers
  final container = ProviderContainer(
    overrides: [
      feature_settings.sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  // Initialize feature-specific settings
  await feature_settings.initializeSharedPreferences(container);

  // Run the app inside Phoenix for restart capability, wrapped with ProviderScope for state management
  runApp(
    Phoenix(
      child: ProviderScope(
        overrides: [
          feature_settings.sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            // Initialize app and check Firebase initialization status
            final initializationStatus = ref.watch(appInitializationProvider);
            
            return initializationStatus.when(
              data: (_) {
                // Only initialize messaging if Firebase is properly initialized
                ref.watch(messagingInitializerProvider);
                
                return MaterialApp.router(
                  title: 'HIVE',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.darkTheme,
                  routerConfig: appRouter,
                  builder: (context, child) {
                    return child!;
                  },
                );
              },
              loading: () => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.darkTheme,
                home: Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/hivelogo.png',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (error, stackTrace) => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.darkTheme,
                home: Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to start application',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              // Restart the app
                              Phoenix.rebirth(context);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
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
    const bool enableDebugTools = !kReleaseMode;

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
          scrollBehavior: AppScrollBehavior(scrollPhysics),
          builder: (context, child) {
            _setupDeviceSettings(context);
            
            // Apply safe area
            final wrappedChild = MediaQuery(
              // Apply font scale
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );

            // Wrap with debug launcher in development mode
            return enableDebugTools
                ? DebugLauncher(child: wrappedChild)
                : wrappedChild;
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
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
  GoRouter.of(context).push('${AppRoutes.getClubSpacePath()}?id=$clubId');
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
