import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/usecases/get_growth_trends_usecase.dart';
import 'package:hive_ui/features/analytics/domain/usecases/track_event_usecase.dart';

/// Controller for analytics functionality
class AnalyticsController extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final TrackEventUseCase _trackEventUseCase;
  final GetGrowthTrendsUseCase _getGrowthTrendsUseCase;
  
  /// Constructor
  AnalyticsController({
    required TrackEventUseCase trackEventUseCase,
    required GetGrowthTrendsUseCase getGrowthTrendsUseCase,
  }) : 
    _trackEventUseCase = trackEventUseCase,
    _getGrowthTrendsUseCase = getGrowthTrendsUseCase,
    super(const AsyncValue.loading());
  
  /// Track an analytics event
  Future<void> trackEvent(AnalyticsEventType eventType, Map<String, dynamic> properties) async {
    try {
      await _trackEventUseCase.execute(
        eventType: eventType,
        properties: properties,
      );
    } catch (e) {
      debugPrint('Error tracking event: $e');
      // Don't update state, as this is a non-UI operation
    }
  }
  
  /// Load growth trends for a specific time period
  Future<void> loadGrowthTrends(int days) async {
    state = const AsyncValue.loading();
    
    try {
      final trends = await _getGrowthTrendsUseCase.execute(days);
      state = AsyncValue.data(trends);
    } catch (e, stackTrace) {
      debugPrint('Error loading growth trends: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for the analytics controller
final analyticsControllerProvider = StateNotifierProvider<AnalyticsController, AsyncValue<Map<String, dynamic>>>((ref) {
  final trackEventUseCase = ref.watch(trackEventUseCaseProvider);
  final getGrowthTrendsUseCase = ref.watch(getGrowthTrendsUseCaseProvider);
  
  return AnalyticsController(
    trackEventUseCase: trackEventUseCase,
    getGrowthTrendsUseCase: getGrowthTrendsUseCase,
  );
}); 