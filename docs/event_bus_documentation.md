# AppEventBus Documentation

## Overview

The AppEventBus is a central event dispatching system that enables loose coupling between components in the HIVE UI application. Components can emit events without knowing which other components are listening, and components can listen for specific events without needing direct references to the emitting components.

## Core Components

### AppEvent Base Class

All events must extend the `AppEvent` abstract base class:

```dart
abstract class AppEvent {
  const AppEvent();
}
```

### AppEventBus Singleton

The `AppEventBus` is implemented as a singleton with methods for emitting events and subscribing to event streams:

```dart
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
```

## Event Types

### Profile and User-Related Events

- **ProfileUpdatedEvent**: Emitted when a user profile is updated
  ```dart
  class ProfileUpdatedEvent extends AppEvent {
    final String userId;
    final Map<String, dynamic> updates;
  }
  ```

- **FriendRequestSentEvent**: Emitted when a friend request is sent
  ```dart
  class FriendRequestSentEvent extends AppEvent {
    final String senderId;
    final String receiverId;
  }
  ```

- **FriendRequestRespondedEvent**: Emitted when a friend request is responded to
  ```dart
  class FriendRequestRespondedEvent extends AppEvent {
    final String requesterId;
    final String responderId;
    final bool accepted;
  }
  ```

### Event-Related Events

- **EventUpdatedEvent**: Emitted when event details are updated
  ```dart
  class EventUpdatedEvent extends AppEvent {
    final String eventId;
    final Map<String, dynamic> updates;
  }
  ```

- **EventCreatedEvent**: Emitted when a new event is created
  ```dart
  class EventCreatedEvent extends AppEvent {
    final String eventId;
    final String spaceId;
  }
  ```

- **RsvpStatusChangedEvent**: Emitted when a user RSVPs to an event
  ```dart
  class RsvpStatusChangedEvent extends AppEvent {
    final String eventId;
    final String userId;
    final bool isAttending;
  }
  ```

### Space-Related Events

- **SpaceUpdatedEvent**: Emitted when space details are updated
  ```dart
  class SpaceUpdatedEvent extends AppEvent {
    final String spaceId;
    final Map<String, dynamic> updates;
  }
  ```

- **SpaceMembershipChangedEvent**: Emitted when a user joins or leaves a space
  ```dart
  class SpaceMembershipChangedEvent extends AppEvent {
    final String spaceId;
    final String userId;
    final bool isJoining;
  }
  ```

### Content Interaction Events

- **ContentRepostedEvent**: Emitted when content is reposted
  ```dart
  class ContentRepostedEvent extends AppEvent {
    final String contentId;
    final String contentType;
    final String userId;
  }
  ```

## Usage Examples

### Emitting Events

```dart
// Emit an event when a user RSVPs to an event
AppEventBus().emit(
  RsvpStatusChangedEvent(
    eventId: eventId,
    userId: userId,
    isAttending: true,
  ),
);
```

### Listening for Events

```dart
// Set up a listener for RSVP changes
AppEventBus().on<RsvpStatusChangedEvent>().listen((event) {
  // Update UI or invalidate cache based on the RSVP change
  invalidateCache('event:${event.eventId}');
  invalidateCache('user:${event.userId}:events');
});
```

### Optimistic Updates with Event Bus

For operations that might take time (like server calls), it's recommended to:

1. Update local state optimistically
2. Emit the event for optimistic UI updates in other components
3. Perform the actual operation
4. If the operation fails, revert the state and emit a corrective event

```dart
// Store previous state for rollback if needed
final previousState = _isJoined;

try {
  // Update UI optimistically
  setState(() { _isJoined = true; });
  
  // Emit event for other listeners to update optimistically
  AppEventBus().emit(
    SpaceMembershipChangedEvent(
      spaceId: spaceId,
      userId: userId,
      isJoining: true,
    ),
  );
  
  // Perform actual backend operation
  final success = await joinSpace();
  
  if (!success) {
    // Revert optimistic update
    setState(() { _isJoined = previousState; });
    
    // Emit corrective event
    AppEventBus().emit(
      SpaceMembershipChangedEvent(
        spaceId: spaceId,
        userId: userId,
        isJoining: false,
      ),
    );
  }
} catch (e) {
  // Also handle exceptions with state reversal and corrective events
}
```

## Best Practices

1. **Define Clear Events**: Each event should have a clear purpose and carry all necessary data
2. **Use Typed Streams**: Always use the `on<T>()` method to get type-safe event streams
3. **Handle Errors**: When operations fail, emit corrective events to revert optimistic updates
4. **Memory Management**: Always dispose of stream subscriptions when widgets are disposed
5. **Logging**: Use the built-in logging for debugging event flows

## Integration with Cache Manager

The AppEventBus is tightly integrated with the CacheManager to ensure data consistency across the app. The CacheManager listens for events that should invalidate specific caches:

```dart
// In CacheManager._setupListeners()
AppEventBus().on<RsvpStatusChangedEvent>().listen((event) {
  invalidateCache('event:${event.eventId}');
  invalidateCache('user:${event.userId}:events');
});
```

This ensures that cached data is properly invalidated when changes occur, maintaining data consistency across the application. 