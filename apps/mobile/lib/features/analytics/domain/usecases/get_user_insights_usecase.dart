import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/failures/analytics_failures.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';
import 'package:hive_ui/features/analytics/domain/providers/repository_providers.dart';

/// Model for representing enriched user insights
class UserInsights {
  final int engagementScore;
  final int? peakActivityHour;
  final String? mostActiveDay;
  final bool isActive;
  final Map<String, int> activityByHour;
  final Map<String, int> activityByDay;
  final UserMetricsEntity metrics;
  final List<AnalyticsEventEntity> recentEvents;

  const UserInsights({
    required this.engagementScore,
    required this.peakActivityHour,
    required this.mostActiveDay,
    required this.isActive,
    required this.activityByHour,
    required this.activityByDay,
    required this.metrics,
    required this.recentEvents,
  });

  /// Get category breakdown from metrics and events
  Map<String, int> get categoryBreakdown {
    final breakdown = <String, int>{};
    
    // Add base metrics
    breakdown['Content'] = metrics.contentCreated;
    breakdown['Engagement'] = metrics.contentEngagement;
    breakdown['Spaces'] = metrics.spacesJoined;
    breakdown['Events'] = metrics.eventsAttended;
    
    return breakdown;
  }
}

final getUserInsightsUseCaseProvider = Provider<GetUserInsightsUseCase>((ref) {
  return GetUserInsightsUseCase(
    repository: ref.watch(analyticsRepositoryInterfaceProvider),
  );
});

/// Use case for calculating and retrieving enriched user insights
class GetUserInsightsUseCase {
  final AnalyticsRepositoryInterface repository;

  const GetUserInsightsUseCase({required this.repository});

  Future<Either<AnalyticsFailure, UserInsights>> call(String userId) async {
    try {
      // Get base metrics
      final metricsResult = await repository.getUserMetrics(userId);
      
      return metricsResult.fold(
        (failure) => Left(failure),
        (metrics) async {
          if (metrics == null) {
            return Left(MetricsLoadFailure(
              userId: userId,
              originalException: 'No metrics found for user',
            ));
          }
          
          // Get recent events
          final eventsResult = await repository.getUserEvents(userId);
          
          return eventsResult.fold(
            (failure) => Left(failure),
            (events) {
              // Calculate enriched insights
              return Right(UserInsights(
                engagementScore: metrics.calculateEngagementScore(),
                peakActivityHour: metrics.getPeakActivityHour(),
                mostActiveDay: metrics.getMostActiveDay(),
                isActive: metrics.isActiveUser(),
                activityByHour: metrics.activityByHour,
                activityByDay: metrics.activityByDay,
                metrics: metrics,
                recentEvents: events,
              ));
            },
          );
        },
      );
    } catch (e) {
      return Left(MetricsLoadFailure(
        userId: userId,
        originalException: e,
      ));
    }
  }
}

class InteractionTrend {
  final String type;
  final int count;
  final DateTime timestamp;

  InteractionTrend({
    required this.type,
    required this.count,
    required this.timestamp,
  });
}