import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';

/// Model for representing user insights
class UserInsights {
  final UserMetricsEntity metrics;
  final List<AnalyticsEventEntity> recentEvents;
  final int engagementScore;
  final int? peakActivityHour;
  final String? mostActiveDay;
  final bool isActive;
  final Map<String, int> categoryBreakdown;
  
  UserInsights({
    required this.metrics,
    required this.recentEvents,
    required this.engagementScore,
    this.peakActivityHour,
    this.mostActiveDay,
    required this.isActive,
    required this.categoryBreakdown,
  });
}

/// Use case for calculating and retrieving user insights
class GetUserInsightsUseCase {
  final AnalyticsRepositoryInterface _repository;
  
  GetUserInsightsUseCase(this._repository);
  
  /// Get comprehensive insights for a user
  Future<UserInsights> execute(String userId) async {
    // Get user metrics
    final metrics = await _repository.getUserMetrics(userId);
    if (metrics == null) {
      throw Exception('Failed to retrieve user metrics');
    }
    
    // Get recent events
    final recentEvents = await _repository.getUserEvents(
      userId,
      limit: 100,
    );
    
    // Calculate engagement score
    final engagementScore = metrics.calculateEngagementScore();
    
    // Get peak activity time
    final peakHour = metrics.getPeakActivityHour();
    final mostActiveDay = metrics.getMostActiveDay();
    
    // Determine if user is active
    final isActive = metrics.isActiveUser();
    
    // Calculate category breakdown
    final categoryBreakdown = _calculateCategoryBreakdown(recentEvents);
    
    return UserInsights(
      metrics: metrics,
      recentEvents: recentEvents,
      engagementScore: engagementScore,
      peakActivityHour: peakHour,
      mostActiveDay: mostActiveDay,
      isActive: isActive,
      categoryBreakdown: categoryBreakdown,
    );
  }
  
  /// Calculate breakdown of user activity by category
  Map<String, int> _calculateCategoryBreakdown(List<AnalyticsEventEntity> events) {
    final breakdown = <String, int>{
      'profile': 0,
      'social': 0,
      'spaces': 0,
      'events': 0,
      'content': 0,
    };
    
    for (final event in events) {
      switch (event.eventType) {
        case AnalyticsEventType.profileView:
        case AnalyticsEventType.profileEdit:
        case AnalyticsEventType.profileExport:
        case AnalyticsEventType.profileImport:
          breakdown['profile'] = (breakdown['profile'] ?? 0) + 1;
          break;
          
        case AnalyticsEventType.friendRequest:
        case AnalyticsEventType.friendRequestAccepted:
        case AnalyticsEventType.friendRequestRejected:
          breakdown['social'] = (breakdown['social'] ?? 0) + 1;
          break;
          
        case AnalyticsEventType.spaceView:
        case AnalyticsEventType.spaceJoin:
        case AnalyticsEventType.spaceLeave:
        case AnalyticsEventType.spaceCreate:
        case AnalyticsEventType.spaceMessageSent:
          breakdown['spaces'] = (breakdown['spaces'] ?? 0) + 1;
          break;
          
        case AnalyticsEventType.eventView:
        case AnalyticsEventType.eventCreate:
        case AnalyticsEventType.eventEdit:
        case AnalyticsEventType.eventCancel:
        case AnalyticsEventType.eventRsvp:
          breakdown['events'] = (breakdown['events'] ?? 0) + 1;
          break;
          
        case AnalyticsEventType.contentCreate:
        case AnalyticsEventType.contentEdit:
        case AnalyticsEventType.contentView:
        case AnalyticsEventType.contentShare:
        case AnalyticsEventType.contentReaction:
          breakdown['content'] = (breakdown['content'] ?? 0) + 1;
          break;
      }
    }
    
    return breakdown;
  }
} 