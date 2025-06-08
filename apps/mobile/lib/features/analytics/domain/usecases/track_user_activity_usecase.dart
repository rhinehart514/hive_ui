import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';

/// Use case for tracking user activity across the app
class TrackUserActivityUseCase {
  final AnalyticsRepositoryInterface _repository;
  
  TrackUserActivityUseCase(this._repository);
  
  /// Track profile view event
  Future<void> trackProfileView(String viewedUserId, {String? viewerUserId}) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.profileView,
      properties: {
        'viewedUserId': viewedUserId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: viewerUserId,
    );
  }
  
  /// Track profile edit event
  Future<void> trackProfileEdit(List<String> editedFields, {String? userId}) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.profileEdit,
      properties: {
        'fields': editedFields,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: userId,
    );
  }
  
  /// Track friend request sent
  Future<void> trackFriendRequest(String targetUserId, {String? userId}) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.friendRequest,
      properties: {
        'targetUserId': targetUserId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: userId,
    );
  }
  
  /// Track space join event
  Future<void> trackSpaceJoin(String spaceId, String spaceName, {String? userId}) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.spaceJoin,
      properties: {
        'spaceId': spaceId,
        'spaceName': spaceName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: userId,
    );
  }
  
  /// Track event RSVP
  Future<void> trackEventRsvp(
    String eventId, 
    String eventName, 
    String status, 
    {String? userId}
  ) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.eventRsvp,
      properties: {
        'eventId': eventId,
        'eventName': eventName,
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: userId,
    );
  }
  
  /// Track content creation
  Future<void> trackContentCreation(
    String contentId,
    String contentType,
    {String? userId}
  ) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.contentCreate,
      properties: {
        'contentId': contentId,
        'contentType': contentType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: userId,
    );
  }
  
  /// Track content interaction (like, comment)
  Future<void> trackContentInteraction(
    String contentId,
    String interactionType,
    {String? userId}
  ) {
    return _repository.trackEvent(
      eventType: AnalyticsEventType.contentReaction,
      properties: {
        'contentId': contentId,
        'interactionType': interactionType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      userId: userId,
    );
  }
} 