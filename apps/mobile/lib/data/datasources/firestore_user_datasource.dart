import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Abstract interface for user data sources.
abstract class UserDataSource {
  /// Saves a user's profile to the data store.
  Future<Result<UserProfile, Failure>> saveUserProfile(UserProfile userProfile, String uid);

  /// Retrieves a user's profile from the data store.
  Future<Result<UserProfile, Failure>> getUserProfile(String uid);

  /// Updates specific fields of a user's profile.
  Future<Result<UserProfile, Failure>> updateUserProfile(String uid, Map<String, dynamic> updates);

  /// Checks if a username is already taken.
  Future<Result<bool, Failure>> isUsernameTaken(String username);

  /// Requests verification for a user's account.
  Future<Result<void, Failure>> requestVerification(String uid);

  /// Retrieves users by username.
  Future<Result<List<UserProfile>, Failure>> getUsersByUsername(String username);
}

/// Firestore implementation of [UserDataSource].
class FirestoreUserDataSource implements UserDataSource {
  final FirebaseFirestore _firestore;
  final String _usersCollection;
  final String _verificationRequestsCollection;

  /// Creates a new instance with the given dependencies.
  ///
  /// [firestore] - The Firestore instance to use.
  /// [usersCollection] - The name of the collection where user profiles are stored.
  /// [verificationRequestsCollection] - The name of the collection where verification requests are stored.
  FirestoreUserDataSource(
    this._firestore,
    this._usersCollection,
    this._verificationRequestsCollection,
  );

  @override
  Future<Result<UserProfile, Failure>> saveUserProfile(UserProfile userProfile, String uid) async {
    try {
      // Check if the username is taken
      final usernameCheck = await isUsernameTaken(userProfile.username);
      if (usernameCheck.isSuccess && usernameCheck.getSuccess) {
        return const Result.left(
          InvalidInputFailure('This username is already taken. Please choose a different one.'),
        );
      }

      // Create the document
      final userDoc = _firestore.collection(_usersCollection).doc(uid);
      
      // Convert to JSON and add metadata
      final userData = userProfile.toJson();
      userData['uid'] = uid;
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      userData['v'] = 1; // Schema version
      
      // Save to Firestore
      await userDoc.set(userData);
      
      return Result.right(userProfile);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to save user profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<UserProfile, Failure>> getUserProfile(String uid) async {
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(uid).get();
      
      if (!userDoc.exists) {
        return const Result.left(
          InvalidInputFailure('User profile not found.'),
        );
      }
      
      final userData = userDoc.data();
      if (userData == null) {
        return const Result.left(
          ServerFailure('User profile data is null.'),
        );
      }
      
      return Result.right(UserProfile.fromJson(userData));
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to get user profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      // Check if username is being updated and if it's taken
      if (updates.containsKey('username')) {
        final usernameCheck = await isUsernameTaken(updates['username']);
        if (usernameCheck.isSuccess && usernameCheck.getSuccess) {
          return const Result.left(
            InvalidInputFailure('This username is already taken. Please choose a different one.'),
          );
        }
      }
      
      // Add timestamp for update
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update the document
      await _firestore.collection(_usersCollection).doc(uid).update(updates);
      
      // Get the updated profile
      return getUserProfile(uid);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to update user profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool, Failure>> isUsernameTaken(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      return Result.right(querySnapshot.docs.isNotEmpty);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to check username: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> requestVerification(String uid) async {
    try {
      // Get the user profile to verify it exists
      final userResult = await getUserProfile(uid);
      if (userResult.isFailure) {
        return Result.left(userResult.getFailure);
      }
      
      // Create a verification request
      await _firestore.collection(_verificationRequestsCollection).add({
        'uid': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
      });
      
      // Update the user's tier to pending
      await updateUserProfile(uid, {'tier': 'pending'});
      
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to request verification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<UserProfile>, Failure>> getUsersByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .get();
      
      final userProfiles = querySnapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
      
      return Result.right(userProfiles);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to get users by username: ${e.toString()}'),
      );
    }
  }
}

/// Failure that occurs when invalid input is provided.
class InvalidInputFailure extends Failure {
  const InvalidInputFailure(String message) : super(message);
} 