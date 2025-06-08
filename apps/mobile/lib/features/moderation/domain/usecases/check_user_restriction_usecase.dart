import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for checking user restrictions
class CheckUserRestrictionUseCase {
  final ModerationRepository _repository;

  /// Constructor
  CheckUserRestrictionUseCase(this._repository);

  /// Check if a user is currently restricted
  Future<bool> isRestricted(String userId) async {
    return _repository.isUserRestricted(userId);
  }

  /// Get details about a user's restriction
  Future<UserRestrictionEntity?> getRestrictionDetails(String userId) async {
    return _repository.getUserRestrictionByUserId(userId);
  }

  /// Get all active restrictions
  Future<List<UserRestrictionEntity>> getAllActiveRestrictions() async {
    return _repository.getActiveUserRestrictions();
  }

  /// Check if a restriction has expired
  bool isRestrictionExpired(UserRestrictionEntity restriction) {
    return restriction.isExpired;
  }

  /// Get remaining time for a temporary restriction
  Duration? getRemainingRestrictionTime(UserRestrictionEntity restriction) {
    return restriction.remainingDuration;
  }

  /// Get a user-friendly description of the restriction status
  String getRestrictionStatus(UserRestrictionEntity restriction) {
    return restriction.getStatusDescription();
  }
} 