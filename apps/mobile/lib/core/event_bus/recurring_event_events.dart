import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// Event emitted when a recurring event is created
class RecurringEventCreatedEvent extends AppEvent {
  /// The ID of the created recurring event
  final String eventId;

  /// Constructor
  const RecurringEventCreatedEvent({
    required this.eventId,
  });
}

/// Event emitted when a recurring event is updated
class RecurringEventUpdatedEvent extends AppEvent {
  /// The ID of the updated recurring event
  final String eventId;
  
  /// The updates applied to the event
  final Map<String, dynamic> updates;
  
  /// Whether all instances were updated as well
  final bool updatedAllInstances;

  /// Constructor
  const RecurringEventUpdatedEvent({
    required this.eventId,
    required this.updates,
    this.updatedAllInstances = false,
  });
}

/// Event emitted when a recurring event is cancelled
class RecurringEventCancelledEvent extends AppEvent {
  /// The ID of the cancelled recurring event
  final String eventId;
  
  /// The date after which instances were cancelled (null means all instances)
  final DateTime? afterDate;

  /// Constructor
  const RecurringEventCancelledEvent({
    required this.eventId,
    this.afterDate,
  });
}

/// Event emitted when a specific instance of a recurring event is updated
class EventInstanceUpdatedEvent extends AppEvent {
  /// The ID of the updated instance
  final String instanceId;
  
  /// The ID of the parent recurring event
  final String parentEventId;
  
  /// The updates applied to the instance
  final Map<String, dynamic> updates;

  /// Constructor
  const EventInstanceUpdatedEvent({
    required this.instanceId,
    required this.parentEventId,
    required this.updates,
  });
}

/// Event emitted when a specific instance of a recurring event is cancelled
class EventInstanceCancelledEvent extends AppEvent {
  /// The ID of the cancelled instance
  final String instanceId;
  
  /// The ID of the parent recurring event
  final String parentEventId;

  /// Constructor
  const EventInstanceCancelledEvent({
    required this.instanceId,
    required this.parentEventId,
  });
}

/// Event emitted when new instances of a recurring event are generated
class RecurringEventInstancesGeneratedEvent extends AppEvent {
  /// The ID of the parent recurring event
  final String eventId;
  
  /// The number of new instances generated
  final int count;

  /// Constructor
  const RecurringEventInstancesGeneratedEvent({
    required this.eventId,
    required this.count,
  });
} 