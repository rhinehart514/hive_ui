import 'package:hive_ui/features/analytics/data/models/analytics_event_model.dart';
import 'package:hive_ui/features/analytics/data/models/user_metrics_model.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';

/// Mapper for converting between analytics event models and entities
class AnalyticsEventMapper {
  /// Convert from data model to domain entity
  static AnalyticsEventEntity toEntity(AnalyticsEventModel model) {
    return AnalyticsEventEntity(
      id: model.id,
      eventType: _stringToEventType(model.eventType),
      userId: model.userId,
      properties: model.properties,
      timestamp: model.timestamp,
    );
  }
  
  /// Convert from domain entity to data model
  static AnalyticsEventModel fromEntity(AnalyticsEventEntity entity) {
    return AnalyticsEventModel(
      id: entity.id,
      eventType: entity.eventType.toString().split('.').last,
      userId: entity.userId,
      properties: entity.properties,
      timestamp: entity.timestamp,
    );
  }
  
  /// Convert string event type to enum
  static AnalyticsEventType _stringToEventType(String eventType) {
    return AnalyticsEventType.values.firstWhere(
      (e) => e.toString().split('.').last == eventType,
      orElse: () => AnalyticsEventType.profileView, // Default
    );
  }
}

/// Mapper for converting between user metrics models and entities
class UserMetricsMapper {
  /// Convert from data model to domain entity
  static UserMetricsEntity toEntity(UserMetricsModel model) {
    return UserMetricsEntity(
      userId: model.userId,
      profileViews: model.profileViews,
      contentCreated: model.contentCreated,
      contentEngagement: model.contentEngagement,
      spacesJoined: model.spacesJoined,
      eventsAttended: model.eventsAttended,
      activityByHour: model.activityByHour,
      activityByDay: model.activityByDay,
      lastUpdated: model.lastUpdated,
    );
  }
  
  /// Convert from domain entity to data model
  static UserMetricsModel fromEntity(UserMetricsEntity entity) {
    return UserMetricsModel(
      userId: entity.userId,
      profileViews: entity.profileViews,
      contentCreated: entity.contentCreated,
      contentEngagement: entity.contentEngagement,
      spacesJoined: entity.spacesJoined,
      eventsAttended: entity.eventsAttended,
      activityByHour: entity.activityByHour,
      activityByDay: entity.activityByDay,
      lastUpdated: entity.lastUpdated,
    );
  }
} 