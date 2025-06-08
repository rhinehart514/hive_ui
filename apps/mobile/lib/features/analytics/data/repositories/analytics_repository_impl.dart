import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:hive_ui/features/analytics/data/mappers/analytics_entity_mapper.dart';
import 'package:hive_ui/features/analytics/data/repositories/analytics_repository.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/failures/analytics_failures.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_insights.dart';

/// Implementation of the domain repository interface using the data layer repository
class AnalyticsRepositoryImpl implements AnalyticsRepositoryInterface {
  final AnalyticsRepository _dataRepository;
  final Ref _ref;
  
  AnalyticsRepositoryImpl(this._dataRepository, this._ref);
  
  @override
  Future<dartz.Either<AnalyticsFailure, bool>> trackEvent({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  }) async {
    try {
      await _dataRepository.trackEvent(
        eventType: eventType,
        properties: properties,
        userId: userId,
      );
      return const dartz.Right(true);
    } catch (e) {
      debugPrint('Error tracking event: $e');
      return dartz.Left(EventTrackingFailure(
        eventType: eventType.value,
        originalException: e,
      ));
    }
  }
  
  @override
  Future<dartz.Either<AnalyticsFailure, UserMetricsEntity?>> getUserMetrics(String userId) async {
    try {
      final metricsModel = await _dataRepository.getUserMetrics(userId);
      if (metricsModel == null) return const dartz.Right(null);
      return dartz.Right(UserMetricsMapper.toEntity(metricsModel));
    } catch (e) {
      debugPrint('Error getting user metrics: $e');
      return dartz.Left(MetricsLoadFailure(
        userId: userId,
        originalException: e,
      ));
    }
  }
  
  @override
  Future<dartz.Either<AnalyticsFailure, List<AnalyticsEventEntity>>> getUserEvents(
    String userId, {
    int limit = 50,
    AnalyticsEventType? eventType,
  }) async {
    try {
      final eventsModels = await _dataRepository.getUserEvents(
        userId, 
        limit: limit, 
        eventType: eventType,
      );
      
      final events = eventsModels
        .map((model) => AnalyticsEventMapper.toEntity(model))
        .toList();
        
      return dartz.Right(events);
    } catch (e) {
      debugPrint('Error getting user events: $e');
      return dartz.Left(EventsLoadFailure(
        userId: userId,
        originalException: e,
      ));
    }
  }
  
  @override
  Future<dartz.Either<AnalyticsFailure, Map<String, dynamic>>> exportUserAnalytics(String userId) async {
    try {
      final exportData = await _dataRepository.exportUserAnalytics(userId);
      return dartz.Right(exportData);
    } catch (e) {
      debugPrint('Error exporting user analytics: $e');
      return dartz.Left(ExportFailure(
        userId: userId,
        originalException: e,
      ));
    }
  }

  @override
  Future<dartz.Either<AnalyticsFailure, UserInsights>> getUserInsights(String userId) async {
    try {
      // Get recent events (up to 100 for analysis)
      final events = await _getUserEvents(userId, limit: 100);
      
      // Calculate metrics
      final totalPosts = events.where((e) => 
        e.eventType == AnalyticsEventType.contentCreate).length;
        
      final totalComments = events.where((e) => 
        e.eventType == AnalyticsEventType.contentReaction).length;
        
      final totalLikes = events.where((e) => 
        e.eventType == AnalyticsEventType.contentReaction && 
        e.getProperty<String>('type') == 'like').length;
        
      // Calculate average engagement (likes + comments per post)
      final averageEngagement = totalPosts > 0 
        ? (totalLikes + totalComments) / totalPosts 
        : 0.0;
      
      // Get last active time from most recent event
      final lastActive = events.isNotEmpty 
        ? events.first.timestamp 
        : DateTime.now();
      
      return dartz.Right(UserInsights(
        userId: userId,
        totalPosts: totalPosts,
        totalComments: totalComments,
        totalLikes: totalLikes,
        averageEngagement: averageEngagement,
        lastActive: lastActive,
      ));
    } catch (e) {
      debugPrint('Error getting user insights: $e');
      return dartz.Left(EventsLoadFailure(
        userId: userId,
        originalException: e,
      ));
    }
  }

  Future<List<AnalyticsEventEntity>> _getUserEvents(String userId, {int limit = 50}) async {
    // Implementation of getting user events from data source
    // This would typically call a data source or service
    return []; // Placeholder implementation
  }
}

/// Provider for the domain repository interface
final analyticsRepositoryInterfaceProvider = Provider<AnalyticsRepositoryInterface>((ref) {
  final dataRepository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsRepositoryImpl(dataRepository, ref);
}); 