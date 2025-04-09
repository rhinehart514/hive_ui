import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/events/data/repositories/event_repository_impl.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/attendance_record.dart';
import 'package:hive_ui/firebase_init_tracker.dart';
import 'package:hive_ui/main.dart' show appInitializationProvider;

/// Provider for the EventRepository with safe initialization
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  // Listen to app initialization
  final appInitialized = ref.watch(appInitializationProvider);
  
  // Return a placeholder repository during initialization or a real one when ready
  return appInitialized.when(
    data: (_) {
      return FirebaseInitTracker.createPlaceholderRepo<EventRepository>(
        'EventRepository',
        () => EventRepositoryImpl(), // Real implementation
        () => _PlaceholderEventRepository(), // Placeholder
      );
    },
    loading: () {
      debugPrint('App still initializing but event repository requested. Using placeholder.');
      return _PlaceholderEventRepository();
    },
    error: (error, _) {
      debugPrint('App initialization error but event repository requested: $error');
      return _PlaceholderEventRepository();
    },
  );
});

/// Placeholder implementation that handles pre-initialization access safely
class _PlaceholderEventRepository implements EventRepository {
  @override
  Future<Map<String, dynamic>> fetchEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return {
      'events': <Event>[],
      'total': 0,
      'hasMore': false,
    };
  }
  
  @override
  Future<Event?> getEventById(String eventId) async {
    return null;
  }
  
  @override
  Future<List<Event>> getEventsForSpace(String spaceId, String spaceType) async {
    return [];
  }
  
  @override
  Future<bool> saveRsvpStatus(String eventId, String userId, bool isAttending) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }
  
  @override
  Future<List<Event>> getTrendingEvents({int limit = 10}) async {
    return [];
  }
  
  @override
  Future<List<Event>> getEventsForFollowedSpaces(List<String> spaceIds, {int limit = 20}) async {
    return [];
  }
  
  @override
  Future<bool> boostEvent(String eventId, String userId) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }
  
  @override
  Future<bool> setEventHoneyMode(String eventId, String userId) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }
  
  @override
  Future<bool> isHoneyModeAvailable(String spaceId) async {
    return false;
  }
  
  @override
  Future<bool> recordAttendance(String eventId, AttendanceRecord attendanceRecord) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }
  
  @override
  Future<bool> validateCheckInCode(String eventId, String code) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }
  
  @override
  Future<String> generateCheckInCode(String eventId, String generatedBy) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }
} 