import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/analytics_repository.dart';

/// Use case for monitoring onboarding metrics
class MonitorOnboardingMetricsUseCase {
  final AnalyticsRepository _analyticsRepository;
  
  /// Creates a new instance with the given repository
  MonitorOnboardingMetricsUseCase(this._analyticsRepository);
  
  /// Gets the current onboarding completion rate
  Future<Result<double, Failure>> getCompletionRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _analyticsRepository.getOnboardingCompletionRate(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      return Result.left(ServerFailure(
        'Failed to get onboarding completion rate: ${e.toString()}'
      ));
    }
  }
  
  /// Checks if the onboarding completion rate is below the target threshold
  Future<Result<bool, Failure>> isCompletionRateBelowThreshold({
    required double threshold,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final completionResult = await getCompletionRate(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (completionResult.isFailure) {
      return Result.left(completionResult.getFailure);
    }
    
    final completionRate = completionResult.getSuccess;
    return Result.right(completionRate < threshold);
  }
  
  /// Gets the average time spent in onboarding
  Future<Result<Duration, Failure>> getAverageOnboardingTime() async {
    try {
      return await _analyticsRepository.getAverageOnboardingTime();
    } catch (e) {
      return Result.left(ServerFailure(
        'Failed to get average onboarding time: ${e.toString()}'
      ));
    }
  }
  
  /// Gets the drop-off rates for each onboarding step
  Future<Result<Map<String, double>, Failure>> getStepDropoffRates() async {
    try {
      return await _analyticsRepository.getOnboardingStepDropoffRates();
    } catch (e) {
      return Result.left(ServerFailure(
        'Failed to get onboarding step drop-off rates: ${e.toString()}'
      ));
    }
  }
  
  /// Determines if feature flag auto-disable should be triggered based on completion rate
  /// Will return true if the completion rate is below the threshold (20%)
  /// consistently for the specified duration (72 hours)
  Future<Result<bool, Failure>> shouldTriggerAutoDisable({
    double threshold = 0.8,
    Duration monitoringPeriod = const Duration(hours: 72),
  }) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(monitoringPeriod);
      
      // Get completion rate for the monitoring period
      final rateResult = await getCompletionRate(
        startDate: startDate,
        endDate: now,
      );
      
      if (rateResult.isFailure) {
        return Result.left(rateResult.getFailure);
      }
      
      final completionRate = rateResult.getSuccess;
      
      // Check if the rate is below threshold
      return Result.right(completionRate < threshold);
    } catch (e) {
      return Result.left(ServerFailure(
        'Failed to determine auto-disable status: ${e.toString()}'
      ));
    }
  }
} 