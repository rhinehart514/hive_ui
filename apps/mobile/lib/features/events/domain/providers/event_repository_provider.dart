import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/initialization/app_initializer.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/features/events/data/repositories/event_repository_impl.dart';
import 'package:hive_ui/features/events/domain/entities/event.dart';
import 'package:hive_ui/models/attendance_record.dart';

/// Provider for the EventRepository with safe initialization
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final appInitialized = ref.watch(appInitializationProvider);
  
  // Return a placeholder if Firebase isn't initialized
  if (appInitialized == false) {
    return _PlaceholderEventRepository();
  } else {
    // Create and return the real repository
    return EventRepositoryImpl();
  }
});

/// A placeholder implementation used when Firebase is not initialized yet
class _PlaceholderEventRepository implements EventRepository {
  @override
  Future<Map<String, dynamic>> fetchEvents({
    bool forceRefresh = false, 
    int page = 1, 
    int pageSize = 20, 
    DateTime? startDate, 
    DateTime? endDate, 
    String? category
  }) async {
    // Return empty result
    return {
      'events': <Event>[],
      'totalCount': 0,
      'hasMore': false,
      'page': page,
    };
  }

  @override
  Future<Event?> getEventById(String eventId) async {
    // Return null as placeholder
    return null;
  }

  @override
  Future<List<Event>> getEventsForSpace(String spaceId, String spaceType) async {
    // Return empty list as placeholder
    return [];
  }

  @override
  Future<bool> saveRsvpStatus(String eventId, String userId, bool isAttending) async {
    // Return success as placeholder
    return true;
  }

  @override
  Future<List<Event>> getTrendingEvents({int limit = 10}) async {
    // Return empty list as placeholder
    return [];
  }

  @override
  Future<List<Event>> getEventsForFollowedSpaces(List<String> spaceIds, {int limit = 20}) async {
    // Return empty list as placeholder
    return [];
  }

  @override
  Future<bool> boostEvent(String eventId, String userId) async {
    // Return success as placeholder
    return true;
  }

  @override
  Future<bool> setEventHoneyMode(String eventId, String userId) async {
    // Return success as placeholder
    return true;
  }

  @override
  Future<bool> isHoneyModeAvailable(String spaceId) async {
    // Return availability as placeholder
    return true;
  }

  @override
  Future<bool> recordAttendance(String eventId, AttendanceRecord attendanceRecord) async {
    // Return success as placeholder
    return true;
  }

  @override
  Future<bool> validateCheckInCode(String eventId, String code) async {
    // Return validation as placeholder
    return true;
  }

  @override
  Future<String> generateCheckInCode(String eventId, String generatedBy) async {
    // Return placeholder code
    return "PLACEHOLDER";
  }
}

/// Provider for an event by ID
final eventByIdProvider = FutureProvider.family<Event?, String>((ref, eventId) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventById(eventId);
});

/// Provider for trending events
final trendingEventsProvider = FutureProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getTrendingEvents();
});

/// Provider for space events
final spaceEventsProvider = FutureProvider.family<List<Event>, String>((ref, spaceId) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventsForSpace(spaceId, 'space');
}); 