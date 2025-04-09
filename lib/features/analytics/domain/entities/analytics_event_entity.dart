/// Enum defining the types of analytics events
enum AnalyticsEventType {
  // Profile-related events
  profileView,
  profileEdit,
  profileExport,
  profileImport,
  
  // Interaction events
  friendRequest,
  friendRequestAccepted,
  friendRequestRejected,
  
  // Space-related events
  spaceView,
  spaceJoin,
  spaceLeave,
  spaceCreate,
  spaceMessageSent,
  
  // Event-related events
  eventView,
  eventCreate,
  eventEdit,
  eventCancel,
  eventRsvp,
  
  // Content-related events
  contentCreate,
  contentEdit,
  contentView,
  contentShare,
  contentReaction
}

/// Domain entity representing an analytics event
class AnalyticsEventEntity {
  final String id;
  final AnalyticsEventType eventType;
  final String userId;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  
  const AnalyticsEventEntity({
    required this.id,
    required this.eventType,
    required this.userId,
    required this.properties,
    required this.timestamp,
  });
  
  /// Get a property value with type safety
  T? getProperty<T>(String key) {
    final value = properties[key];
    if (value is T) {
      return value;
    }
    return null;
  }
  
  /// Create a string representation of the event
  String getEventDescription() {
    switch (eventType) {
      case AnalyticsEventType.profileView:
        final viewedUserId = getProperty<String>('viewedUserId');
        return 'Profile viewed${viewedUserId != null ? ' (user: $viewedUserId)' : ''}';
        
      case AnalyticsEventType.profileEdit:
        final fields = getProperty<List<String>>('fields');
        return 'Profile edited${fields != null ? ' (fields: ${fields.join(', ')})' : ''}';
        
      case AnalyticsEventType.friendRequest:
        final targetUserId = getProperty<String>('targetUserId');
        return 'Friend request sent${targetUserId != null ? ' to $targetUserId' : ''}';
        
      case AnalyticsEventType.spaceJoin:
        final spaceId = getProperty<String>('spaceId');
        final spaceName = getProperty<String>('spaceName');
        return 'Joined space ${spaceName ?? spaceId ?? ''}';
        
      case AnalyticsEventType.eventRsvp:
        final eventId = getProperty<String>('eventId');
        final eventName = getProperty<String>('eventName');
        final status = getProperty<String>('status');
        return 'RSVP\'d to event ${eventName ?? eventId ?? ''}${status != null ? ' ($status)' : ''}';
        
      case AnalyticsEventType.contentCreate:
        final contentType = getProperty<String>('contentType');
        return 'Created ${contentType ?? 'content'}';
        
      default:
        return 'Event: ${eventType.toString().split('.').last}';
    }
  }
  
  /// Check if the event is recent (within the last 24 hours)
  bool isRecent() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    return diff.inHours < 24;
  }
  
  /// Check if the event is a high-impact event (directly impacts user engagement)
  bool isHighImpact() {
    return [
      AnalyticsEventType.friendRequestAccepted,
      AnalyticsEventType.spaceJoin,
      AnalyticsEventType.eventRsvp,
      AnalyticsEventType.contentCreate,
      AnalyticsEventType.contentShare,
    ].contains(eventType);
  }
}

/// Extension to get string value of event types
extension AnalyticsEventTypeExtension on AnalyticsEventType {
  String get value {
    return toString().split('.').last;
  }
} 