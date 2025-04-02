import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/service_initializer.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:hive_ui/services/error_handling_service.dart';
import 'package:hive_ui/services/performance_service.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/features/messaging/injection.dart';
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';

/// Provider responsible for handling app startup sequence and initialization
final appStartupProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('Starting app initialization sequence...');

    // Track performance for startup
    final performanceService = ref.read(performanceServiceProvider);
    performanceService.startTrace('app_startup');

    // Initialize core user preferences first
    await UserPreferencesService.initialize();
    debugPrint('User preferences initialized');

    // Initialize Firebase services
    try {
      final coreService = ref.read(firebaseCoreServiceProvider);
      final firebaseInitialized =
          await coreService.initializeWithRetry(maxRetries: 3);

      if (firebaseInitialized) {
        debugPrint('Firebase core services initialized');

        // Initialize Firebase Messaging and Analytics
        await Future.wait([
          ref.read(firebaseMessagingServiceProvider).initialize(),
          ref.read(firebaseAnalyticsServiceProvider).initialize(),
        ]);

        // Initialize optimized service layer
        await ServiceInitializer.initializeServices();
        debugPrint('Service layer initialized');

        // Load clubs and spaces data
        try {
          // Try optimized club loading first
          debugPrint('Loading clubs data...');
          final clubs = await OptimizedClubAdapter.getAllClubs();
          debugPrint('Loaded ${clubs.length} clubs successfully');
        } catch (clubError) {
          // Log error but don't block startup
          ref
              .read(errorHandlingServiceProvider)
              .handleError(clubError, type: ErrorType.general);

          // Fall back to standard loading
          try {
            await ClubService.initialize();
            final clubs = await ClubService.loadClubsFromFirestore();
            debugPrint('Loaded ${clubs.length} clubs using fallback method');
          } catch (fallbackError) {
            // Non-fatal error
            debugPrint('Failed to load clubs: $fallbackError');
          }
        }

        // Initialize other dependent services in parallel
        await Future.wait([
          // Initialize space settings
          SpaceService.initSettings(),

          // Initialize messaging
          Future<void>(() async {
            try {
              initializeFirebaseMessaging();
            } catch (e) {
              debugPrint('Failed to initialize messaging: $e');
            }
          }),

          // Initialize analytics
          Future<void>(() async {
            try {
              await AnalyticsService().initialize();
            } catch (e) {
              debugPrint('Failed to initialize analytics: $e');
            }
          }),
        ]);
      } else {
        // Firebase failed to initialize but app can still run with degraded functionality
        debugPrint('Failed to initialize Firebase - running in degraded mode');
        ref.read(errorHandlingServiceProvider).reportUserError(
            'Some services are unavailable',
            type: ErrorType.network);
      }
    } catch (e, stackTrace) {
      // Non-fatal error - app can continue with limited functionality
      ref
          .read(errorHandlingServiceProvider)
          .handleError(e, stackTrace: stackTrace, type: ErrorType.general);
    }

    // Startup complete
    performanceService.stopTrace('app_startup');

    // Return success even with partial failures - this allows the app to start with degraded functionality
    return true;
  } catch (e, stackTrace) {
    debugPrint('Critical error during app startup: $e');
    ref
        .read(errorHandlingServiceProvider)
        .handleError(e, stackTrace: stackTrace, type: ErrorType.general);

    // Stop performance tracking
    ref.read(performanceServiceProvider).stopTrace('app_startup');

    // We still return true to allow the app to start - but with error state
    return true;
  }
});
