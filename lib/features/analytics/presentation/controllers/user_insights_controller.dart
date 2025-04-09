import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/providers/analytics_providers.dart';
import 'package:hive_ui/features/analytics/domain/usecases/get_user_insights_usecase.dart';
import 'package:hive_ui/features/analytics/domain/usecases/track_user_activity_usecase.dart';

/// Controller for user insights UI
class UserInsightsController {
  final TrackUserActivityUseCase _trackActivityUseCase;
  final GetUserInsightsUseCase _getUserInsightsUseCase;
  final Ref _ref;
  
  UserInsightsController({
    required TrackUserActivityUseCase trackActivityUseCase,
    required GetUserInsightsUseCase getUserInsightsUseCase,
    required Ref ref,
  })  : _trackActivityUseCase = trackActivityUseCase,
        _getUserInsightsUseCase = getUserInsightsUseCase,
        _ref = ref;
  
  /// Track that a user viewed analytics
  Future<void> trackAnalyticsView(String userId) async {
    await _trackActivityUseCase.trackProfileView(userId);
  }
  
  /// Refresh the user insights
  Future<void> refreshInsights(String userId) async {
    _ref.invalidate(userInsightsProvider(userId));
  }
  
  /// Get current insights for a user
  AsyncValue<UserInsights> getUserInsights(String userId) {
    return _ref.watch(userInsightsProvider(userId));
  }
  
  /// Export analytics for a user
  Future<Map<String, dynamic>> exportAnalytics(String userId) async {
    final insights = await _getUserInsightsUseCase.execute(userId);
    
    // Track the export event
    _trackActivityUseCase.trackProfileEdit(['export'], userId: userId);
    
    // Return formatted insights for export
    return {
      'userId': userId,
      'exportDate': DateTime.now().toIso8601String(),
      'engagementScore': insights.engagementScore,
      'profileViews': insights.metrics.profileViews,
      'contentCreated': insights.metrics.contentCreated,
      'contentEngagement': insights.metrics.contentEngagement,
      'spacesJoined': insights.metrics.spacesJoined,
      'eventsAttended': insights.metrics.eventsAttended,
      'peakActivityHour': insights.peakActivityHour,
      'mostActiveDay': insights.mostActiveDay,
      'isActive': insights.isActive,
      'categoryBreakdown': insights.categoryBreakdown,
      'recentEvents': insights.recentEvents
          .take(10)
          .map((e) => e.getEventDescription())
          .toList(),
    };
  }
}

/// Provider for the user insights controller
final userInsightsControllerProvider = Provider<UserInsightsController>((ref) {
  final trackActivityUseCase = ref.watch(trackUserActivityUseCaseProvider);
  final getUserInsightsUseCase = ref.watch(getUserInsightsUseCaseProvider);
  
  return UserInsightsController(
    trackActivityUseCase: trackActivityUseCase,
    getUserInsightsUseCase: getUserInsightsUseCase,
    ref: ref,
  );
}); 