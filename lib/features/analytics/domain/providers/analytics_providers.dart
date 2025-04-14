import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/usecases/get_user_insights_usecase.dart';
import 'package:hive_ui/features/analytics/domain/usecases/track_user_activity_usecase.dart';
import 'package:hive_ui/features/analytics/domain/providers/repository_providers.dart' as domain_repo;

/// Provider for the track user activity use case
final trackUserActivityUseCaseProvider = Provider<TrackUserActivityUseCase>((ref) {
  final repository = ref.watch(domain_repo.analyticsRepositoryInterfaceProvider);
  return TrackUserActivityUseCase(repository);
});

/// Provider for the get user insights use case
final getUserInsightsUseCaseProvider = Provider<GetUserInsightsUseCase>((ref) {
  final repository = ref.watch(domain_repo.analyticsRepositoryInterfaceProvider);
  return GetUserInsightsUseCase(repository: repository);
});

/// Provider for user insights data for a specific user
final userInsightsProvider = FutureProvider.family<UserInsights, String>((ref, userId) async {
  final useCase = ref.watch(getUserInsightsUseCaseProvider);
  final result = await useCase.call(userId);
  return result.fold(
    (failure) => throw failure,
    (insights) => insights,
  );
}); 