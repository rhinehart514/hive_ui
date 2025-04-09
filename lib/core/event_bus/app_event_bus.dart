import 'dart:async';
import 'package:flutter/foundation.dart';

/// Base class for all application events
abstract class AppEvent {
  const AppEvent();
}

/// Event emitted when an RSVP status changes
class RsvpStatusChangedEvent extends AppEvent {
  final String eventId;
  final String userId;
  final bool isAttending;

  const RsvpStatusChangedEvent({
    required this.eventId,
    required this.userId,
    required this.isAttending,
  });
}

/// Event emitted when a profile is updated
class ProfileUpdatedEvent extends AppEvent {
  final String userId;
  final Map<String, dynamic> updates;

  const ProfileUpdatedEvent({
    required this.userId,
    required this.updates,
  });
}

/// Event emitted when an event is updated
class EventUpdatedEvent extends AppEvent {
  final String eventId;
  final Map<String, dynamic> updates;

  const EventUpdatedEvent({
    required this.eventId, 
    required this.updates,
  });
}

/// Event emitted when space membership changes
class SpaceMembershipChangedEvent extends AppEvent {
  final String spaceId;
  final String userId;
  final bool isJoining;

  const SpaceMembershipChangedEvent({
    required this.spaceId,
    required this.userId,
    required this.isJoining,
  });
}

/// Event emitted when a space is updated
class SpaceUpdatedEvent extends AppEvent {
  final String spaceId;
  final Map<String, dynamic> updates;

  const SpaceUpdatedEvent({
    required this.spaceId,
    required this.updates,
  });
}

/// Event emitted when a new event is created
class EventCreatedEvent extends AppEvent {
  final String eventId;
  final String spaceId;

  const EventCreatedEvent({
    required this.eventId,
    required this.spaceId,
  });
}

/// Event emitted when a friend request is sent
class FriendRequestSentEvent extends AppEvent {
  final String senderId;
  final String receiverId;

  const FriendRequestSentEvent({
    required this.senderId,
    required this.receiverId,
  });
}

/// Event emitted when a friend request is responded to
class FriendRequestRespondedEvent extends AppEvent {
  final String requesterId;
  final String responderId;
  final bool accepted;

  const FriendRequestRespondedEvent({
    required this.requesterId,
    required this.responderId,
    required this.accepted,
  });
}

/// Event emitted when content is reposted
class ContentRepostedEvent extends AppEvent {
  final String contentId;
  final String contentType;
  final String userId;

  const ContentRepostedEvent({
    required this.contentId,
    required this.contentType,
    required this.userId,
  });
}

/// Central event bus for application-wide events
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  
  factory AppEventBus() => _instance;
  
  AppEventBus._internal();
  
  final _controller = StreamController<AppEvent>.broadcast();
  
  /// Stream of app events
  Stream<AppEvent> get stream => _controller.stream;
  
  /// Stream of specific event types
  Stream<T> on<T extends AppEvent>() {
    return stream.where((event) => event is T).cast<T>();
  }
  
  /// Emit an event to all listeners
  void emit(AppEvent event) {
    if (!_controller.isClosed) {
      debugPrint('🔔 AppEventBus: Emitting ${event.runtimeType}');
      _controller.add(event);
    }
  }
  
  /// Dispose the event bus
  void dispose() {
    _controller.close();
  }
} 