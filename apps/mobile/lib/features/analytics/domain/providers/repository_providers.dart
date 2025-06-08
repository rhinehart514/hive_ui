import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/data/repositories/analytics_repository.dart';
import 'package:hive_ui/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:hive_ui/features/analytics/data/repositories/growth_metrics_repository_impl.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';
import 'package:hive_ui/features/analytics/domain/repositories/growth_metrics_repository.dart';

/// Domain provider for the AnalyticsRepositoryInterface
/// 
/// This completes the clean architecture by providing the domain interface
/// while depending on the data layer implementation.
final analyticsRepositoryInterfaceProvider = Provider<AnalyticsRepositoryInterface>((ref) {
  // Reference the data layer repository provider
  final dataRepository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsRepositoryImpl(dataRepository, ref);
});

/// Domain provider for the GrowthMetricsRepository
/// 
/// This integrates the GrowthMetricsRepository implementation into the clean architecture
/// pattern, making it available to use cases and controllers.
final growthMetricsRepositoryProvider = Provider<GrowthMetricsRepository>((ref) {
  return GrowthMetricsRepositoryImpl();
}); 