import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/user_repository.dart';

/// Implementation of the UserRepository using Firebase Firestore
class UserRepositoryImpl implements UserRepository {
  final UserDataSource _userDataSource;
  
  /// Creates a new instance with the given data source
  UserRepositoryImpl(this._userDataSource);
  
  @override
  Future<Result<UserProfile, Failure>> getUserProfile(String uid) async {
    return _userDataSource.getUserProfile(uid);
  }
  
  @override
  Future<Result<UserProfile, Failure>> createUserProfile(UserProfile profile, String uid) async {
    return _userDataSource.saveUserProfile(profile, uid);
  }
  
  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    return _userDataSource.updateUserProfile(uid, updates);
  }
  
  @override
  Future<Result<bool, Failure>> isUsernameTaken(String username) async {
    return _userDataSource.isUsernameTaken(username);
  }
  
  @override
  Future<Result<UserProfile, Failure>> getUserProfileByUsername(String username) async {
    try {
      // Get all users with the matching username
      final queryResult = await _userDataSource.getUsersByUsername(username);
      
      if (queryResult.isFailure) {
        return Result.left(queryResult.getFailure);
      }
      
      final users = queryResult.getSuccess;
      
      // Check if any users were found
      if (users.isEmpty) {
        return const Result.left(AuthFailure('User with this username not found'));
      }
      
      // Return the first matching user profile
      return Result.right(users.first);
    } catch (e) {
      return Result.left(ServerFailure('Failed to get user by username: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<void, Failure>> requestVerification(String uid) async {
    return _userDataSource.requestVerification(uid);
  }
  
  @override
  Future<Result<void, Failure>> cancelVerificationRequest(String uid) async {
    try {
      // Get the current user profile
      final userResult = await getUserProfile(uid);
      
      if (userResult.isFailure) {
        return Result.left(userResult.getFailure);
      }
      
      final userProfile = userResult.getSuccess;
      
      // Only allow cancellation if the tier is pending
      if (userProfile.tier != UserTier.pending) {
        return const Result.left(AuthFailure('No pending verification request to cancel'));
      }
      
      // Update the tier back to base
      final updateResult = await updateUserProfile(uid, {'tier': 'base'});
      
      if (updateResult.isFailure) {
        return Result.left(updateResult.getFailure);
      }
      
      return const Result.right(null);
    } catch (e) {
      return Result.left(ServerFailure('Failed to cancel verification request: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<UserTier, Failure>> getVerificationStatus(String uid) async {
    try {
      // Get the user profile
      final userResult = await getUserProfile(uid);
      
      if (userResult.isFailure) {
        return Result.left(userResult.getFailure);
      }
      
      // Return the tier which represents the verification status
      return Result.right(userResult.getSuccess.tier);
    } catch (e) {
      return Result.left(ServerFailure('Failed to get verification status: ${e.toString()}'));
    }
  }
} 