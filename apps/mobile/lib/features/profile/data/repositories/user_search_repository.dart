import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/core/error/app_error_handler.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Interface for the user search repository
abstract class UserSearchRepository {
  /// Search users based on the provided filters
  Future<Either<AppFailure, List<UserProfile>>> searchUsers(UserSearchFilters filters);
}

/// Implementation of the user search repository using Firestore
class UserSearchRepositoryImpl implements UserSearchRepository {
  final FirebaseFirestore _firestore;

  /// Constructor
  UserSearchRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  @override
  Future<Either<AppFailure, List<UserProfile>>> searchUsers(UserSearchFilters filters) async {
    try {
      // Start with the users collection
      Query query = _firestore.collection('users');

      // Apply filters
      if (filters.query != null && filters.query!.isNotEmpty) {
        // Simple implementation - in production would use more sophisticated search
        query = query.where('displayName', isGreaterThanOrEqualTo: filters.query)
                    .where('displayName', isLessThanOrEqualTo: '${filters.query}\uf8ff');
      }

      if (filters.year != null) {
        query = query.where('year', isEqualTo: filters.year);
      }

      if (filters.major != null) {
        query = query.where('major', isEqualTo: filters.major);
      }

      if (filters.onlyVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      // Get documents
      final snapshot = await query.get();
      
      // Convert to UserProfile objects
      final users = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Ensure id is set from document
            if (!data.containsKey('id')) {
              data['id'] = doc.id;
            }
            return _parseUserProfile(data);
          })
          .where((user) {
            // Apply filters that can't be applied directly in the query
            if (filters.minActivityLevel != null && 
                user.activityLevel < filters.minActivityLevel!) {
              return false;
            }
            
            if (filters.minSharedSpaces != null && 
                user.sharedSpaces < filters.minSharedSpaces!) {
              return false;
            }
            
            if (filters.minSharedEvents != null && 
                user.sharedEvents < filters.minSharedEvents!) {
              return false;
            }
            
            return true;
          })
          .toList();

      return Right(users);
    } catch (e) {
      return Left(UnexpectedFailure(
        technicalMessage: 'Failed to search users: ${e.toString()}',
        exception: e,
      ));
    }
  }

  // Helper to parse user profile from Firestore data
  UserProfile _parseUserProfile(Map<String, dynamic> data) {
    final now = DateTime.now();
    
    // Parse dates if they exist
    DateTime? createdAt;
    DateTime? updatedAt;
    
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt']);
      }
    }
    
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.tryParse(data['updatedAt']);
      }
    }
    
    // Parse interests if they exist
    List<String> interests = [];
    if (data['interests'] != null) {
      if (data['interests'] is List) {
        interests = List<String>.from(
          (data['interests'] as List).map((i) => i.toString())
        );
      }
    }
    
    return UserProfile(
      id: data['id'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      bio: data['bio'],
      year: data['year'] ?? '',
      major: data['major'] ?? '',
      residence: data['residence'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      eventCount: data['eventCount'] ?? 0,
      spaceCount: data['spaceCount'] ?? 0,
      friendCount: data['friendCount'] ?? 0,
      activityLevel: data['activityLevel'] ?? 0,
      sharedSpaces: data['sharedSpaces'] ?? 0,
      sharedEvents: data['sharedEvents'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      interests: interests,
    );
  }
} 