import '../entities/profile_analytics.dart';
// Assume ProfileRepository or a new AnalyticsRepository handles fetching analytics
import '../repositories/profile_repository.dart'; 
// TODO: Confirm correct repository and add dependency injection

/// Use case for getting profile analytics for a user.
class GetProfileAnalyticsUseCase {
  // final AnalyticsRepository _repository; // Or ProfileRepository if combined
  final ProfileRepository _repository; // Placeholder - adjust repository if needed

  GetProfileAnalyticsUseCase(this._repository);

  /// Executes the use case to fetch profile analytics.
  /// 
  /// [userId] The ID of the user whose analytics are being requested.
  /// Returns ProfileAnalytics or null if not found/error.
  Future<ProfileAnalytics?> execute(String userId) {
    // Call the repository method to fetch analytics
    return _repository.getProfileAnalytics(userId);
  }
} 