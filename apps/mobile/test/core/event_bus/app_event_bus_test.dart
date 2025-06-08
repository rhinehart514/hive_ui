import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

void main() {
  group('AppEventBus Integration Tests', () {
    late AppEventBus eventBus;
    late List<StreamSubscription> subscriptions;

    setUp(() {
      // Create a new instance for testing
      eventBus = AppEventBus();
      subscriptions = [];
    });

    tearDown(() {
      // Clean up subscriptions
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
      subscriptions.clear();
    });

    test('AppEventBus is a singleton', () {
      final instance1 = AppEventBus();
      final instance2 = AppEventBus();

      expect(instance1, equals(instance2));
    });

    test('Events are emitted and received by appropriate listeners', () async {
      // Create counters to track event reception
      int rsvpEventCount = 0;
      int profileEventCount = 0;
      int anyEventCount = 0;

      // Set up listeners
      subscriptions.add(
        eventBus.on<RsvpStatusChangedEvent>().listen((_) {
          rsvpEventCount++;
        }),
      );

      subscriptions.add(
        eventBus.on<ProfileUpdatedEvent>().listen((_) {
          profileEventCount++;
        }),
      );

      subscriptions.add(
        eventBus.stream.listen((_) {
          anyEventCount++;
        }),
      );

      // Emit events
      eventBus.emit(const RsvpStatusChangedEvent(
        eventId: 'event1',
        userId: 'user1',
        isAttending: true,
      ));

      eventBus.emit(const ProfileUpdatedEvent(
        userId: 'user1',
        updates: {'name': 'New Name'},
      ));

      // Allow time for all events to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify counts
      expect(rsvpEventCount, 1);
      expect(profileEventCount, 1);
      expect(anyEventCount, 2);
    });

    test('Multiple listeners for the same event type all receive the event', () async {
      // Set up counters
      int listener1Count = 0;
      int listener2Count = 0;
      
      // Set up multiple listeners for the same event type
      subscriptions.add(
        eventBus.on<EventUpdatedEvent>().listen((_) {
          listener1Count++;
        }),
      );

      subscriptions.add(
        eventBus.on<EventUpdatedEvent>().listen((_) {
          listener2Count++;
        }),
      );

      // Emit event
      eventBus.emit(const EventUpdatedEvent(
        eventId: 'event1',
        updates: {'title': 'New Title'},
      ));

      // Allow time for event processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify both listeners received the event
      expect(listener1Count, 1);
      expect(listener2Count, 1);
    });

    test('Events are properly typed when received', () async {
      RsvpStatusChangedEvent? receivedRsvpEvent;
      ProfileUpdatedEvent? receivedProfileEvent;

      // Set up listeners that capture the event object
      subscriptions.add(
        eventBus.on<RsvpStatusChangedEvent>().listen((event) {
          receivedRsvpEvent = event;
        }),
      );

      subscriptions.add(
        eventBus.on<ProfileUpdatedEvent>().listen((event) {
          receivedProfileEvent = event;
        }),
      );

      // Create events with specific data
      const rsvpEvent = RsvpStatusChangedEvent(
        eventId: 'event1',
        userId: 'user1',
        isAttending: true,
      );

      const profileEvent = ProfileUpdatedEvent(
        userId: 'user2',
        updates: {'bio': 'New bio'},
      );

      // Emit events
      eventBus.emit(rsvpEvent);
      eventBus.emit(profileEvent);

      // Allow time for event processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify events were received with correct data
      expect(receivedRsvpEvent, isNotNull);
      expect(receivedRsvpEvent?.eventId, equals('event1'));
      expect(receivedRsvpEvent?.userId, equals('user1'));
      expect(receivedRsvpEvent?.isAttending, isTrue);

      expect(receivedProfileEvent, isNotNull);
      expect(receivedProfileEvent?.userId, equals('user2'));
      expect(receivedProfileEvent?.updates['bio'], equals('New bio'));
    });

    test('Cancelled subscriptions no longer receive events', () async {
      int eventCount = 0;
      
      // Set up a subscription that we'll cancel
      final subscription = eventBus.on<SpaceUpdatedEvent>().listen((_) {
        eventCount++;
      });
      
      subscriptions.add(subscription);

      // Emit first event
      eventBus.emit(const SpaceUpdatedEvent(
        spaceId: 'space1',
        updates: {'name': 'Updated Space'},
      ));

      // Allow time for event processing
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify first event was received
      expect(eventCount, 1);

      // Cancel the subscription
      await subscription.cancel();
      
      // Remove from our tracking list
      subscriptions.remove(subscription);

      // Emit another event
      eventBus.emit(const SpaceUpdatedEvent(
        spaceId: 'space1',
        updates: {'description': 'New description'},
      ));

      // Allow time for event processing
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify count hasn't increased
      expect(eventCount, 1);
    });

    test('AppEventBus handles high-frequency events properly', () async {
      int eventCount = 0;
      
      // Set up listener
      subscriptions.add(
        eventBus.on<ContentRepostedEvent>().listen((_) {
          eventCount++;
        }),
      );

      // Emit multiple events in quick succession
      for (int i = 0; i < 100; i++) {
        eventBus.emit(ContentRepostedEvent(
          contentId: 'content$i',
          contentType: 'post',
          userId: 'user1',
        ));
      }

      // Allow time for all events to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify all events were received
      expect(eventCount, 100);
    });
    
    test('AppEventBus properly handles listener errors', () async {
      bool errorCaught = false;
      
      // Set up listener that will throw an error
      final subscription = eventBus.on<SpaceMembershipChangedEvent>().listen((_) {
        throw Exception('Test error');
      });
      
      // Add error handler
      subscription.onError((error) {
        errorCaught = true;
      });
      
      subscriptions.add(subscription);

      // Emit event
      eventBus.emit(const SpaceMembershipChangedEvent(
        spaceId: 'space1',
        userId: 'user1',
        isJoining: true,
      ));

      // Allow time for event processing
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify error was caught
      expect(errorCaught, isTrue);
    });
  });
} 