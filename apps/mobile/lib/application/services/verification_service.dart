import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Status of a verification request
enum VerificationStatus {
  /// User has not requested verification
  notRequested,
  
  /// Request is pending review
  pending,
  
  /// Request has been approved
  approved,
  
  /// Request has been rejected
  rejected,
}

/// Service that manages user verification requests and status.
class VerificationService {
  final UserDataSource _userDataSource;
  
  /// Creates a new instance with the given data source.
  VerificationService(this._userDataSource);
  
  /// Requests verification for the given user.
  /// 
  /// Returns a [Result] with void on success or a [Failure] on error.
  Future<Result<void, Failure>> requestVerification(String userId) async {
    return _userDataSource.requestVerification(userId);
  }
  
  /// Gets the current verification status for the given user.
  /// 
  /// Returns a [Result] with [VerificationStatus] on success or a [Failure] on error.
  Future<Result<VerificationStatus, Failure>> getVerificationStatus(String userId) async {
    final result = await _userDataSource.getUserProfile(userId);
    
    if (result.isFailure) {
      return Result.left(result.getFailure);
    }
    
    final profile = result.getSuccess;
    
    switch (profile.tier) {
      case UserTier.pending:
        return const Result.right(VerificationStatus.pending);
      case UserTier.verified_plus:
        return const Result.right(VerificationStatus.approved);
      case UserTier.base:
      default:
        return const Result.right(VerificationStatus.notRequested);
    }
  }
  
  /// Cancels a pending verification request.
  /// 
  /// Returns a [Result] with void on success or a [Failure] on error.
  Future<Result<void, Failure>> cancelVerificationRequest(String userId) async {
    final userResult = await _userDataSource.getUserProfile(userId);
    
    if (userResult.isFailure) {
      return Result.left(userResult.getFailure);
    }
    
    final profile = userResult.getSuccess;
    
    // Only allow cancellation if the status is pending
    if (profile.tier != UserTier.pending) {
      return const Result.left(InvalidInputFailure('No pending verification request to cancel'));
    }
    
    // Update the user's tier back to base
    final updates = {'tier': 'base'};
    final updateResult = await _userDataSource.updateUserProfile(userId, updates);
    
    if (updateResult.isFailure) {
      return Result.left(updateResult.getFailure);
    }
    
    return const Result.right(null);
  }
  
  /// Checks if a user has verified plus tier status.
  /// 
  /// Returns a [Result] with boolean on success or a [Failure] on error.
  Future<Result<bool, Failure>> isVerifiedPlus(String userId) async {
    final result = await _userDataSource.getUserProfile(userId);
    
    if (result.isFailure) {
      return Result.left(result.getFailure);
    }
    
    final profile = result.getSuccess;
    return Result.right(profile.tier == UserTier.verified_plus);
  }
  
  /// Upgrades a user to verified plus tier after approval.
  /// 
  /// This should only be called by admin users or systems.
  /// Returns a [Result] with void on success or a [Failure] on error.
  Future<Result<void, Failure>> upgradeToVerifiedPlus(String userId) async {
    final profileResult = await _userDataSource.getUserProfile(userId);
    
    if (profileResult.isFailure) {
      return Result.left(profileResult.getFailure);
    }
    
    final profile = profileResult.getSuccess;
    final updatedProfile = profile.copyWith(tier: UserTier.verified_plus);
    
    return _userDataSource.saveUserProfile(updatedProfile, userId);
  }
} 