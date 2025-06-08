import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/user_repository.dart';
import 'package:hive_ui/domain/analytics/analytics_event.dart';
import 'package:hive_ui/domain/repositories/analytics_repository.dart';

/// Use case for detecting and handling username collisions
class UsernameCollisionDetectionUseCase {
  final UserRepository _userRepository;
  final AnalyticsRepository _analyticsRepository;
  
  /// Creates a new instance with the given repositories
  UsernameCollisionDetectionUseCase(this._userRepository, this._analyticsRepository);
  
  /// Checks if a username is already taken
  Future<Result<bool, Failure>> isUsernameTaken(String username) async {
    try {
      return await _userRepository.isUsernameTaken(username);
    } catch (e) {
      return Result.left(ServerFailure('Failed to check username: ${e.toString()}'));
    }
  }
  
  /// Generates an alternative username when a collision is detected
  Future<Result<String, Failure>> generateAlternativeUsername(
    String username, 
    {int maxAttempts = 5}
  ) async {
    try {
      // Try different suffixes
      for (var i = 1; i <= maxAttempts; i++) {
        // Add a different random 4-digit suffix
        final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
        final alternativeUsername = '${username}_$randomSuffix';
        
        // Check if this alternative is available
        final checkResult = await isUsernameTaken(alternativeUsername);
        
        if (checkResult.isFailure) {
          continue; // Try again with a different suffix
        }
        
        final isTaken = checkResult.getSuccess;
        
        if (!isTaken) {
          // Log the collision and successful resolution
          _logCollision(username, alternativeUsername);
          return Result.right(alternativeUsername);
        }
      }
      
      // If we couldn't find an available alternative after maxAttempts
      _logCollision(username, null, success: false);
      return const Result.left(AuthFailure(
        'Unable to generate an alternative username. Please try a different name.'
      ));
    } catch (e) {
      return Result.left(ServerFailure('Failed to generate alternative username: ${e.toString()}'));
    }
  }
  
  /// Logs a username collision event for analytics
  Future<void> _logCollision(String originalUsername, String? alternativeUsername, {bool success = true}) async {
    try {
      final analyticsEvent = AnalyticsEvent(
        type: AnalyticsEventType.error,
        parameters: {
          'error_type': 'username_collision',
          'original_username': originalUsername,
          'alternative_username': alternativeUsername,
          'resolution_success': success,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      await _analyticsRepository.trackEvent(analyticsEvent);
    } catch (e) {
      // Fail silently - this is just analytics logging
      // We don't want to fail the main operation if analytics fails
    }
  }
  
  /// Gets the current collision rate (number of collisions / total username generations)
  Future<Result<double, Failure>> getCollisionRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This would be implemented in a real analytics system
      // For now we return a placeholder
      return const Result.right(0.0);
    } catch (e) {
      return Result.left(ServerFailure('Failed to get collision rate: ${e.toString()}'));
    }
  }
} 