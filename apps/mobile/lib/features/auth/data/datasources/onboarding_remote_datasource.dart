import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/data/models/onboarding_profile_model.dart';

/// Interface for remote onboarding data operations
abstract class OnboardingRemoteDataSource {
  /// Saves the onboarding profile data to Firestore
  Future<void> saveOnboardingProfile(OnboardingProfileModel profile);

  /// Updates the user's onboarding progress
  Future<void> updateOnboardingProgress(
      String userId, Map<String, dynamic> progressData);

  /// Marks the onboarding process as completed for the user
  Future<void> markOnboardingComplete(String userId);
}

/// Implementation of [OnboardingRemoteDataSource] using Firebase
class FirebaseOnboardingDataSource implements OnboardingRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Create a new [FirebaseOnboardingDataSource]
  FirebaseOnboardingDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> saveOnboardingProfile(OnboardingProfileModel profile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      await _firestore.collection('users').doc(currentUser.uid).set(
            profile.toJson(),
            SetOptions(merge: true),
          );

      debugPrint('Profile saved successfully for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('Error saving onboarding profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateOnboardingProgress(
      String userId, Map<String, dynamic> progressData) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'onboardingProgress': progressData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('Onboarding progress updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating onboarding progress: $e');
      rethrow;
    }
  }

  @override
  Future<void> markOnboardingComplete(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'onboardingCompleted': true,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('Onboarding marked as complete for user: $userId');
    } catch (e) {
      debugPrint('Error marking onboarding as complete: $e');
      rethrow;
    }
  }
}
