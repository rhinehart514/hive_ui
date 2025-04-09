import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/data/mappers/analytics_entity_mapper.dart';
import 'package:hive_ui/features/analytics/data/repositories/analytics_repository.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';

/// Implementation of the domain repository interface using the data layer repository
class AnalyticsRepositoryImpl implements AnalyticsRepositoryInterface {
  final AnalyticsRepository _dataRepository;
  
  AnalyticsRepositoryImpl(this._dataRepository);
  
  @override
  Future<void> trackEvent({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  }) {
    return _dataRepository.trackEvent(
      eventType: eventType,
      properties: properties,
      userId: userId,
    );
  }
  
  @override
  Future<UserMetricsEntity?> getUserMetrics(String userId) async {
    final metricsModel = await _dataRepository.getUserMetrics(userId);
    if (metricsModel == null) return null;
    return UserMetricsMapper.toEntity(metricsModel);
  }
  
  @override
  Future<List<AnalyticsEventEntity>> getUserEvents(
    String userId, {
    int limit = 50,
    AnalyticsEventType? eventType,
  }) async {
    final eventsModels = await _dataRepository.getUserEvents(
      userId, 
      limit: limit, 
      eventType: eventType,
    );
    
    return eventsModels
      .map((model) => AnalyticsEventMapper.toEntity(model))
      .toList();
  }
  
  @override
  Future<Map<String, dynamic>> exportUserAnalytics(String userId) {
    return _dataRepository.exportUserAnalytics(userId);
  }
}

/// Provider for the domain repository interface
final analyticsRepositoryInterfaceProvider = Provider<AnalyticsRepositoryInterface>((ref) {
  final dataRepository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsRepositoryImpl(dataRepository);
}); 