import 'package:hive_ui/models/recurring_event.dart';

/// Repository interface for recurring events
abstract class RecurringEventRepository {
  /// Create a new recurring event
  Future<RecurringEvent?> createRecurringEvent(RecurringEvent event);
  
  /// Get a recurring event by ID (either master event or instance)
  Future<RecurringEvent?> getRecurringEventById(String eventId);
  
  /// Get upcoming recurring events
  Future<List<RecurringEvent>> getUpcomingRecurringEvents({int limit = 20});
  
  /// Get instances of a recurring event
  Future<List<RecurringEvent>> getRecurringEventInstances(String parentEventId, {int limit = 10});
  
  /// Update a recurring event - can optionally update all instances too
  Future<bool> updateRecurringEvent(RecurringEvent event, {bool updateAllInstances = false});
  
  /// Update a specific instance of a recurring event
  Future<bool> updateEventInstance(RecurringEvent instance);
  
  /// Cancel a specific instance of a recurring event
  Future<bool> cancelEventInstance(String instanceId, String parentEventId);
  
  /// Cancel a recurring event and all its instances (optionally only after a specific date)
  Future<bool> cancelRecurringEvent(String eventId, {DateTime? afterDate});
  
  /// Generate new instances of a recurring event
  Future<List<RecurringEvent>> generateNewInstances(String eventId, {int count = 5});
  
  /// Save RSVP status for a specific instance
  Future<bool> saveRsvpStatusForInstance(String instanceId, String parentEventId, String userId, bool isAttending);
} 