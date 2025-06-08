import 'package:hive_ui/features/events/domain/entities/event.dart';
import 'package:hive_ui/models/attendance_record.dart';

/// Repository interface for events following clean architecture principles
abstract class EventRepository {
  /// Fetch events with pagination
  Future<Map<String, dynamic>> fetchEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  });
  
  /// Get event by ID
  Future<Event?> getEventById(String eventId);
  
  /// Get events for a specific space
  Future<List<Event>> getEventsForSpace(String spaceId, String spaceType);
  
  /// Save RSVP status for an event
  Future<bool> saveRsvpStatus(String eventId, String userId, bool isAttending);
  
  /// Get trending events
  Future<List<Event>> getTrendingEvents({int limit = 10});
  
  /// Get events for user's followed spaces
  Future<List<Event>> getEventsForFollowedSpaces(List<String> spaceIds, {int limit = 20});
  
  /// Boost an event to increase its visibility in feeds
  /// Returns true if successful
  Future<bool> boostEvent(String eventId, String userId);
  
  /// Set an event to honey mode for maximum visibility
  /// Returns true if successful
  Future<bool> setEventHoneyMode(String eventId, String userId);
  
  /// Check if a space has used its honey mode allocation for the month
  /// Returns true if honey mode is available
  Future<bool> isHoneyModeAvailable(String spaceId);
  
  /// Record attendance for an event
  /// Returns true if the attendance was successfully recorded
  Future<bool> recordAttendance(String eventId, AttendanceRecord attendanceRecord);
  
  /// Check if a check-in code is valid for an event
  /// Returns true if the code is valid
  Future<bool> validateCheckInCode(String eventId, String code);
  
  /// Generate a check-in code for an event
  /// Returns the generated code
  Future<String> generateCheckInCode(String eventId, String generatedBy);
} 