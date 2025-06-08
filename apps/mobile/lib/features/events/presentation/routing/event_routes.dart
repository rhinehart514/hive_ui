import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/events/presentation/pages/event_detail_page_realtime.dart';
import 'package:hive_ui/models/event.dart';

/// Contains route definitions for the events feature
class EventRoutes {
  /// Base path for event routes
  static const String basePath = '/events';
  
  /// Path for real-time event details
  static const String realtimeEventDetail = '$basePath/realtime/:eventId';
  
  /// Get full path for real-time event details
  static String getRealtimeEventDetailPath(String eventId, {String? heroTag}) {
    final path = '$basePath/realtime/$eventId';
    return heroTag != null ? '$path?heroTag=$heroTag' : path;
  }
  
  /// Get all event routes
  static List<RouteBase> getRoutes() {
    debugPrint('🛣️ EventRoutes: Configuring event routes');
    
    return [
      GoRoute(
        path: realtimeEventDetail,
        name: 'eventDetailsRealtime',
        pageBuilder: (context, state) {
          debugPrint('🛣️ EventRoutes: Navigating to event details for eventId: ${state.pathParameters['eventId']}');
          
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

  /// Initialize method to match expected API
  static void initialize() {
    debugPrint('🛣️ EventRoutes: Initialized');
  }
}

/// Helper class for event navigation
class EventNavigation {
  /// Navigate to event details page
  static void navigateToEventDetails(BuildContext context, Event event, {String? heroTag}) {
    debugPrint('🧭 EventNavigation: Navigating to event details for ${event.id}');
    
    context.push(
      EventRoutes.getRealtimeEventDetailPath(event.id, heroTag: heroTag),
      extra: event,
    );
  }
} 