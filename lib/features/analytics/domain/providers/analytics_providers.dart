import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:hive_ui/features/analytics/domain/usecases/get_user_insights_usecase.dart';
import 'package:hive_ui/features/analytics/domain/usecases/track_user_activity_usecase.dart';

/// Provider for the track user activity use case
final trackUserActivityUseCaseProvider = Provider<TrackUserActivityUseCase>((ref) {
  final repository = ref.watch(analyticsRepositoryInterfaceProvider);
  return TrackUserActivityUseCase(repository);
});

/// Provider for the get user insights use case
final getUserInsightsUseCaseProvider = Provider<GetUserInsightsUseCase>((ref) {
  final repository = ref.watch(analyticsRepositoryInterfaceProvider);
  return GetUserInsightsUseCase(repository);
});

/// Provider for user insights data for a specific user
final userInsightsProvider = FutureProvider.family<UserInsights, String>((ref, userId) async {
  final useCase = ref.watch(getUserInsightsUseCaseProvider);
  return useCase.execute(userId);
}); 