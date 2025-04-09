# HIVE UI State Synchronization Implementation Plan

This document outlines the concrete steps to implement the solutions identified in the UI state synchronization audit. These changes will ensure all architectural layers are properly integrated while maintaining the current UI/UX design.

## Phase 1: High Priority Implementation (Immediate)

### 1. Implement Application Event Bus

**File Location:** `lib/core/event_bus/app_event_bus.dart`

```dart
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
```

### 2. Fix RSVP Status Updates

#### 2.1. Modify `SaveRsvpStatusUseCase`

**File Location:** `lib/features/feed/domain/usecases/save_rsvp_status_usecase.dart`

```dart
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/features/feed/domain/repositories/feed_repository.dart';

class SaveRsvpStatusUseCase {
  final FeedRepository _repository;
  final AppEventBus _eventBus;
  
  SaveRsvpStatusUseCase({
    required FeedRepository repository,
    AppEventBus? eventBus,
  }) : _repository = repository,
       _eventBus = eventBus ?? AppEventBus();
  
  Future<bool> execute(String eventId, String userId, bool isAttending) async {
    try {
      // Save to backend
      final success = await _repository.saveRsvpStatus(eventId, userId, isAttending);
      
      if (success) {
        // Emit event to notify all listeners
        _eventBus.emit(RsvpStatusChangedEvent(
          eventId: eventId,
          userId: userId,
          isAttending: isAttending,
        ));
      }
      
      return success;
    } catch (e) {
      rethrow;
    }
  }
}
```

#### 2.2. Update `EventCard` Component

**File Location:** `lib/components/event_card/event_card.dart`

```dart
// Modify _handleRsvp method:
void _handleRsvp() async {
  if (widget.onRsvp != null) {
    HapticFeedback.mediumImpact();
    
    // Store previous state for possible rollback
    final previousRsvpState = _isRsvped;
    
    try {
      // Play animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      
      // Update local state immediately for responsive feel
      setState(() {
        _isRsvped = !_isRsvped;
      });
      
      // Call the callback with the event
      await widget.onRsvp!(widget.event);
    } catch (e) {
      // If there's an error, revert the local state
      if (mounted) {
        setState(() {
          _isRsvped = previousRsvpState;
        });
        
        // Revert animation if needed
        if (_animationController.status == AnimationStatus.completed) {
          _animationController.reverse();
        }
      }
    }
  }
}
```

### 3. Add Cross-Provider Listeners

#### 3.1. Update `FeedEventsNotifier`

**File Location:** `lib/features/feed/domain/providers/feed_events_provider.dart`

```dart
// Initialize listeners in constructor
FeedEventsNotifier({
  required GetEventsUseCase getEventsUseCase,
  required SaveRsvpStatusUseCase saveRsvpStatusUseCase,
  required Ref ref,
}) : _getEventsUseCase = getEventsUseCase,
     _saveRsvpStatusUseCase = saveRsvpStatusUseCase,
     _ref = ref,
     super(FeedEventsState()) {
  debugPrint('📱 FEED EVENTS NOTIFIER: Created with initial state: ${state.status}');
  
  // Listen for profile changes
  _listenToProfileChanges();
  
  // Listen for RSVP status changes
  _listenToRsvpChanges();
}

// Add methods to listen for changes
void _listenToProfileChanges() {
  AppEventBus().on<ProfileUpdatedEvent>().listen((event) {
    // If profile updated contains savedEvents change
    if (event.updates.containsKey('savedEvents')) {
      _syncWithProfile();
    }
  });
}

void _listenToRsvpChanges() {
  AppEventBus().on<RsvpStatusChangedEvent>().listen((event) {
    // Find event in state and update it
    _updateEventRsvpStatus(event.eventId, event.userId, event.isAttending);
  });
}

// Add method to sync with profile
Future<void> _syncWithProfile() async {
  try {
    final profileState = _ref.read(profileProvider);
    if (profileState.profile == null) return;
    
    // Update events based on profile saved events
    final savedEventIds = profileState.profile!.savedEvents.map((e) => e.id).toSet();
    
    // Update attendance status for all events in feed
    state = state.copyWith(
      events: state.events.map((event) {
        if (savedEventIds.contains(event.id)) {
          // User has saved this event, ensure they're in attendees
          if (!event.attendees.contains(profileState.profile!.id)) {
            return event.copyWith(
              attendees: [...event.attendees, profileState.profile!.id],
            );
          }
        } else {
          // User hasn't saved this event, ensure they're not in attendees
          if (event.attendees.contains(profileState.profile!.id)) {
            return event.copyWith(
              attendees: event.attendees.where((id) => id != profileState.profile!.id).toList(),
            );
          }
        }
        return event;
      }).toList(),
    );
    
    // Also update the feed items
    _updateFeedItemsFromEvents();
  } catch (e) {
    debugPrint('❌ Error syncing with profile: $e');
  }
}

// Add method to update feed items from events
void _updateFeedItemsFromEvents() {
  state = state.copyWith(
    feedItems: state.feedItems.map((item) {
      if (item['type'] == 'event') {
        final eventId = (item['data'] as Event).id;
        final updatedEvent = state.events.firstWhere(
          (e) => e.id == eventId,
          orElse: () => item['data'] as Event,
        );
        return {...item, 'data': updatedEvent};
      } else if (item['type'] == 'repost') {
        final repost = item['data'] as RepostItem;
        final eventId = repost.event.id;
        final updatedEvent = state.events.firstWhere(
          (e) => e.id == eventId,
          orElse: () => repost.event,
        );
        return {...item, 'data': repost.copyWith(event: updatedEvent)};
      }
      return item;
    }).toList(),
  );
}
```

### 4. Implement Proper Optimistic Updates

#### 4.1. Update `ProfileNotifier.saveEvent`

**File Location:** `lib/features/profile/presentation/providers/profile_providers.dart`

```dart
Future<bool> saveEvent(Event event) async {
  if (state.isLoading) return false; // Prevent concurrent updates
  
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }
    
    // Check if the event is already saved
    if (state.profile?.savedEvents.any((e) => e.id == event.id) ?? false) {
      return true; // Already saved
    }
    
    // Store previous state for rollback
    final previousState = state;
    
    // Start loading state
    state = state.copyWith(
      isLoading: true,
      error: null,
      pendingUpdates: {...state.pendingUpdates, 'savedEvents': DateTime.now()}
    );
    
    // Update the profile state optimistically
    if (state.profile != null) {
      final updatedEvents = List<Event>.from(state.profile!.savedEvents)..add(event);
      
      state = state.copyWith(
        profile: state.profile!.copyWith(
          savedEvents: updatedEvents,
          eventCount: updatedEvents.length,
          updatedAt: DateTime.now(),
        ),
        isLoading: true,
      );
    }
    
    // Perform the update
    await _repository.saveEvent(currentUser.uid, event);
    
    // Emit event to notify listeners
    AppEventBus().emit(ProfileUpdatedEvent(
      userId: currentUser.uid,
      updates: {'savedEvents': DateTime.now()},
    ));
    
    // Update final state on success
    state = state.copyWith(
      isLoading: false,
      error: null,
      pendingUpdates: Map<String, DateTime>.from(state.pendingUpdates)..remove('savedEvents'),
      lastSyncTime: DateTime.now(),
    );
    
    return true;
  } catch (e) {
    debugPrint('ProfileNotifier: Error saving event: $e');
    
    // Revert profile state on error
    if (state.profile != null) {
      state = state.copyWith(
        profile: state.profile,
        isLoading: false,
        error: 'Failed to save event: $e',
        pendingUpdates: Map<String, DateTime>.from(state.pendingUpdates)..remove('savedEvents'),
      );
    }
    
    return false;
  }
}
```

## Phase 2: Medium Priority Implementation (Next Sprint)

### 1. Create Provider Dependency Chain

#### 1.1. Refactor `EventProvider`

**File Location:** `lib/providers/event_providers.dart`

```dart
/// Provider for all events
final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  // Listen to event updates
  ref.listen<Event?>(eventUpdateProvider, (previous, next) {
    if (next != null) {
      // If an event was updated, invalidate this provider
      ref.invalidateSelf();
    }
  });
  
  // Get current time
  final now = DateTime.now();

  // Load events from Firestore
  final events = await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 50,
  );

  // Filter out events that have already started
  return events.where((event) => event.startDate.isAfter(now)).toList();
});
```

### 2. Fix Repository Synchronization

#### 2.1. Update `EventRepository`

**File Location:** `lib/features/events/data/repositories/event_repository_impl.dart`

```dart
class EventRepositoryImpl implements EventRepository {
  final FirebaseFirestore _firestore;
  final AppEventBus _eventBus;
  
  EventRepositoryImpl({
    FirebaseFirestore? firestore,
    AppEventBus? eventBus,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _eventBus = eventBus ?? AppEventBus();

  @override
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('events').doc(eventId).update(updates);
      
      // Emit event to notify all parts of the app
      _eventBus.emit(EventUpdatedEvent(
        eventId: eventId,
        updates: updates,
      ));
      
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }
  
  // Other repository methods...
}
```

### 3. Implement Firestore Stream Consumers

#### 3.1. Create `EventStreamProvider`

**File Location:** `lib/features/events/domain/providers/event_stream_provider.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';

/// Provider that streams a specific event's real-time updates
final singleEventStreamProvider = StreamProvider.family<Event, String>((ref, eventId) {
  return FirebaseFirestore.instance
      .collection('events')
      .doc(eventId)
      .snapshots()
      .map((snapshot) => Event.fromJson({
            ...snapshot.data()!,
            'id': snapshot.id,
          }));
});

/// Provider that streams events for a specific user
final userEventsStreamProvider = StreamProvider.family<List<Event>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('attendees', arrayContains: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Event.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList());
});
```

### 4. Create UI State Refresh Mechanism

#### 4.1. Create Global Refresh Controller

**File Location:** `lib/core/refresh/global_refresh_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RefreshTarget {
  feed,
  events,
  profile,
  spaces,
  all,
}

class GlobalRefreshController extends ChangeNotifier {
  final Ref _ref;
  
  GlobalRefreshController(this._ref);
  
  void requestRefresh(RefreshTarget target) {
    debugPrint('🔄 GlobalRefreshController: Refreshing $target');
    
    switch (target) {
      case RefreshTarget.feed:
        _ref.refresh(feedEventsProvider);
        break;
      case RefreshTarget.events:
        _ref.refresh(eventsProvider);
        break;
      case RefreshTarget.profile:
        _ref.read(profileProvider.notifier).refreshProfile();
        break;
      case RefreshTarget.spaces:
        _ref.refresh(spacesProvider);
        break;
      case RefreshTarget.all:
        _ref.refresh(feedEventsProvider);
        _ref.refresh(eventsProvider);
        _ref.read(profileProvider.notifier).refreshProfile();
        _ref.refresh(spacesProvider);
        break;
    }
    
    notifyListeners();
  }
}

final globalRefreshControllerProvider = Provider<GlobalRefreshController>((ref) {
  return GlobalRefreshController(ref);
});
```

## Phase 3: Low Priority Implementation (Future Improvements)

### 1. Create Domain Event System

**File Location:** `lib/core/domain/domain_events.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';

abstract class DomainEvent<T> {
  final T data;
  final DateTime occurredOn;
  
  DomainEvent(this.data) : occurredOn = DateTime.now();
}

class EventCreatedDomainEvent extends DomainEvent<Map<String, dynamic>> {
  EventCreatedDomainEvent(Map<String, dynamic> data) : super(data);
}

class EventUpdatedDomainEvent extends DomainEvent<Map<String, dynamic>> {
  EventUpdatedDomainEvent(Map<String, dynamic> data) : super(data);
}

class DomainEventBus {
  static final DomainEventBus _instance = DomainEventBus._internal();
  
  factory DomainEventBus() => _instance;
  
  DomainEventBus._internal();
  
  final _controller = StreamController<DomainEvent>.broadcast();
  
  Stream<DomainEvent> get events => _controller.stream;
  
  void publish(DomainEvent event) {
    debugPrint('🌐 DomainEventBus: Publishing ${event.runtimeType}');
    _controller.add(event);
  }
  
  Stream<T> of<T extends DomainEvent>() {
    return events.where((event) => event is T).cast<T>();
  }
  
  void dispose() {
    _controller.close();
  }
}
```

### 2. Setup Comprehensive Cache Invalidation

**File Location:** `lib/core/cache/cache_manager.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// Manages cache invalidation across the app
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  
  factory CacheManager() => _instance;
  
  CacheManager._internal() {
    _setupListeners();
  }
  
  final Map<String, DateTime> _lastInvalidationTimes = {};
  
  void _setupListeners() {
    // Listen for events that should invalidate caches
    AppEventBus().on<RsvpStatusChangedEvent>().listen((event) {
      invalidateCache('event:${event.eventId}');
      invalidateCache('user:${event.userId}:events');
    });
    
    AppEventBus().on<ProfileUpdatedEvent>().listen((event) {
      invalidateCache('user:${event.userId}');
      invalidateCache('user:${event.userId}:events');
    });
    
    AppEventBus().on<EventUpdatedEvent>().listen((event) {
      invalidateCache('event:${event.eventId}');
      invalidateCache('events');
    });
  }
  
  /// Invalidate a specific cache
  void invalidateCache(String cacheKey) {
    _lastInvalidationTimes[cacheKey] = DateTime.now();
    debugPrint('🧹 CacheManager: Invalidated cache for $cacheKey');
  }
  
  /// Check if a cache is valid
  bool isCacheValid(String cacheKey, DateTime cacheTime) {
    final lastInvalidation = _lastInvalidationTimes[cacheKey];
    if (lastInvalidation == null) return true;
    return cacheTime.isAfter(lastInvalidation);
  }
}
```

## Integration Approach

To ensure all architectural layers are properly integrated while maintaining the current UI/UX, we will:

1. **Maintain Presentation Layer Unchanged**: Keep all UI components visually identical
2. **Enhance State Management**: Update the existing providers to properly synchronize state
3. **Implement Cross-Layer Communication**: Add event bus for consistent communication
4. **Optimize Backend Integration**: Use real-time listeners for critical data changes

This implementation plan follows the principles outlined in the HIVE overview, ensuring a unified campus experience with proper integration between feeds, spaces, profiles, and events.

## Testing Approach

1. **Unit Tests**: Test individual state management classes and event handling
2. **Integration Tests**: Verify cross-component updates work correctly
3. **Manual Testing Scenarios**: 
   - RSVP to an event and check updates across all views
   - Update profile and verify changes reflect in feeds
   - Create events and ensure proper propagation

## Timeline

- **Phase 1**: 1-2 weeks
- **Phase 2**: 2-3 weeks
- **Phase 3**: 3-4 weeks 