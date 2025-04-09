import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/events/presentation/pages/event_detail_page_realtime.dart';
import 'package:hive_ui/models/event.dart';

/// Extension methods for adding event-related routes to GoRouter
extension EventRoutesExtension on GoRouter {
  /// Add event-related routes to the GoRouter
  static List<RouteBase> getEventRoutes() {
    return [
      // Real-time event details route
      GoRoute(
        path: '/events/realtime/:eventId',
        name: 'eventDetailsRealtime',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          final heroTag = state.uri.queryParameters['heroTag'];
          final initialEvent = state.extra is Event ? state.extra as Event : null;
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: EventDetailPageRealtime(
              eventId: eventId,
              heroTag: heroTag,
              initialEventData: initialEvent,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
    ];
  }
}

/// Helper class to initialize event-related routes
class EventRoutesInitializer {
  /// Initialize this module with the provided ProviderContainer
  static void initialize() {
    // This method would be called from the main app initialization
    debugPrint('🛣️ Event routes initialized');
  }
} 