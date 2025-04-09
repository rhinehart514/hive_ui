import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';

/// Provider for event updates
final eventUpdateProvider = StateNotifierProvider<EventUpdateNotifier, Event?>((ref) {
  return EventUpdateNotifier();
});

/// Notifier for handling event updates
class EventUpdateNotifier extends StateNotifier<Event?> {
  EventUpdateNotifier() : super(null);

  /// Notify listeners about an event update
  void notifyEventUpdate(Event event) {
    state = event;
  }

  /// Clear the current event update
  void clearUpdate() {
    state = null;
  }
} 