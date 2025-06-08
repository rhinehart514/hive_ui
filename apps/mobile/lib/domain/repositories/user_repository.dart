import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Gets a user's profile by user ID
  Future<Result<UserProfile, Failure>> getUserProfile(String uid);
  
  /// Creates a new user profile
  Future<Result<UserProfile, Failure>> createUserProfile(UserProfile profile, String uid);
  
  /// Updates an existing user profile
  Future<Result<UserProfile, Failure>> updateUserProfile(String uid, Map<String, dynamic> updates);
  
  /// Checks if a username is already taken
  Future<Result<bool, Failure>> isUsernameTaken(String username);
  
  /// Gets a user profile by username
  Future<Result<UserProfile, Failure>> getUserProfileByUsername(String username);
  
  /// Requests verification for a user
  Future<Result<void, Failure>> requestVerification(String uid);
  
  /// Cancels a verification request for a user
  Future<Result<void, Failure>> cancelVerificationRequest(String uid);
  
  /// Gets the verification status for a user
  Future<Result<UserTier, Failure>> getVerificationStatus(String uid);
} 