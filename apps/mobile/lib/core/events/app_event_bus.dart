import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Types of events that can be broadcast across the app
enum AppEventType {
  /// User joined a space
  spaceJoined,
  
  /// User left a space
  spaceLeft,
  
  /// User RSVPed to an event
  eventRsvp,
  
  /// User boosted content
  contentBoosted,
  
  /// User profile updated
  profileUpdated,
  
  /// User trail updated
  trailUpdated,
  
  /// Refresh feed requested
  refreshFeed,
  
  /// Refresh spaces requested
  refreshSpaces,
  
  /// Refresh profile requested
  refreshProfile,
  
  /// User navigated to a tab
  tabNavigation,
  
  /// Custom event type
  custom
}

/// Event data structure for the app event bus
class AppEvent {
  /// Type of event
  final AppEventType type;
  
  /// ID of the related entity (space, event, etc.)
  final String? entityId;
  
  /// Type of the related entity
  final String? entityType;
  
  /// Additional data for the event
  final Map<String, dynamic>? data;
  
  /// Event source for debugging
  final String? source;
  
  /// Time when the event was created
  final DateTime timestamp;

  AppEvent({
    required this.type,
    this.entityId,
    this.entityType,
    this.data,
    this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  String toString() {
    return 'AppEvent{type: $type, entityId: $entityId, entityType: $entityType, source: $source, timestamp: $timestamp}';
  }
}

/// Global event bus for the app
/// Enables communication between different parts of the app
class AppEventBus {
  /// Stream controller for the event bus
  final StreamController<AppEvent> _controller = StreamController<AppEvent>.broadcast();
  
  /// Stream of events from the bus
  Stream<AppEvent> get stream => _controller.stream;
  
  /// Fire an event to all listeners
  void fire(AppEvent event) {
    if (_controller.isClosed) {
      debugPrint('Warning: Attempted to fire event after EventBus was disposed: $event');
      return;
    }
    
    debugPrint('🚌 EVENT BUS: ${event.source ?? 'Unknown'} fired $event');
    _controller.add(event);
  }
  
  /// Fire a space joined event
  void fireSpaceJoined(String spaceId, String spaceName, {String? source}) {
    fire(AppEvent(
      type: AppEventType.spaceJoined,
      entityId: spaceId,
      entityType: 'space',
      data: {'name': spaceName},
      source: source ?? 'spaces_tab',
    ));
  }
  
  /// Fire a space left event
  void fireSpaceLeft(String spaceId, String spaceName, {String? source}) {
    fire(AppEvent(
      type: AppEventType.spaceLeft,
      entityId: spaceId,
      entityType: 'space',
      data: {'name': spaceName},
      source: source ?? 'spaces_tab',
    ));
  }
  
  /// Fire an event RSVP event
  void fireEventRsvp(String eventId, String eventName, bool isGoing, {String? source}) {
    fire(AppEvent(
      type: AppEventType.eventRsvp,
      entityId: eventId,
      entityType: 'event',
      data: {
        'name': eventName,
        'isGoing': isGoing,
      },
      source: source ?? 'feed_tab',
    ));
  }
  
  /// Fire a content boosted event
  void fireContentBoosted(String contentId, String contentType, String contentName, {String? source}) {
    fire(AppEvent(
      type: AppEventType.contentBoosted,
      entityId: contentId,
      entityType: contentType,
      data: {'name': contentName},
      source: source ?? 'feed_tab',
    ));
  }
  
  /// Fire a profile updated event
  void fireProfileUpdated({String? source}) {
    fire(AppEvent(
      type: AppEventType.profileUpdated,
      source: source ?? 'profile_tab',
    ));
  }
  
  /// Fire a trail updated event
  void fireTrailUpdated({String? source}) {
    fire(AppEvent(
      type: AppEventType.trailUpdated,
      source: source ?? 'profile_tab',
    ));
  }
  
  /// Fire a refresh feed event
  void fireRefreshFeed({String? source}) {
    fire(AppEvent(
      type: AppEventType.refreshFeed,
      source: source ?? 'app',
    ));
  }
  
  /// Fire a refresh spaces event
  void fireRefreshSpaces({String? source}) {
    fire(AppEvent(
      type: AppEventType.refreshSpaces,
      source: source ?? 'app',
    ));
  }
  
  /// Fire a refresh profile event
  void fireRefreshProfile({String? source}) {
    fire(AppEvent(
      type: AppEventType.refreshProfile,
      source: source ?? 'app',
    ));
  }
  
  /// Fire a tab navigation event
  void fireTabNavigation(int tabIndex, {String? source}) {
    fire(AppEvent(
      type: AppEventType.tabNavigation,
      data: {'tabIndex': tabIndex},
      source: source ?? 'navigation',
    ));
  }
  
  /// Dispose the event bus
  void dispose() {
    _controller.close();
  }
}

/// Global instance of the app event bus
final appEventBus = AppEventBus();

/// Provider for the app event bus
final appEventBusProvider = Provider<AppEventBus>((ref) {
  return appEventBus;
});

/// Provider for a specific event type stream
final appEventStreamProvider = StreamProvider.family<AppEvent, AppEventType>((ref, eventType) {
  final eventBus = ref.watch(appEventBusProvider);
  return eventBus.stream.where((event) => event.type == eventType);
});

/// Provider for a general app event stream
final appEventStreamAllProvider = StreamProvider<AppEvent>((ref) {
  final eventBus = ref.watch(appEventBusProvider);
  return eventBus.stream;
}); 