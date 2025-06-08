import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/repositories/growth_metrics_repository.dart';
import '../providers/repository_providers.dart';

/// Use case for retrieving growth trends data for a specific time period
class GetGrowthTrendsUseCase {
  final GrowthMetricsRepository _repository;

  /// Constructor
  GetGrowthTrendsUseCase(this._repository);

  /// Execute the use case to get growth trends for a number of days
  /// 
  /// [days] The number of days to analyze for trends
  /// Returns a map containing various growth trend data
  Future<Map<String, dynamic>> execute(int days) async {
    final result = await _repository.getGrowthTrends(days);
    return result.fold(
      (failure) => throw failure,
      (data) => data,
    );
  }
}

/// Provider for the GetGrowthTrendsUseCase
final getGrowthTrendsUseCaseProvider = Provider<GetGrowthTrendsUseCase>((ref) {
  final repository = ref.watch(growthMetricsRepositoryProvider);
  return GetGrowthTrendsUseCase(repository);
}); 