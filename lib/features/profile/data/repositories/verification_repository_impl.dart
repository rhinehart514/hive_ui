import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/core/error/failures/app_failure_code.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/features/profile/domain/repositories/verification_repository.dart';
import 'package:dartz/dartz.dart';

// Create a concrete implementation of AppFailure for verification failures
class VerificationFailure extends AppFailure {
  const VerificationFailure({
    required String code,
    required String userMessage,
    String? technicalMessage,
    dynamic exception,
    bool isCritical = false,
  }) : super(
    code: code,
    userMessage: userMessage,
    technicalMessage: technicalMessage ?? userMessage,
    exception: exception,
    isCritical: isCritical,
  );
  
  // Factory constructor for easily creating common verification failures
  factory VerificationFailure.fromCode(
    AppFailureCode code, {
    String? message,
    dynamic exception,
  }) {
    final userMessage = message ?? _getDefaultMessageForCode(code);
    return VerificationFailure(
      code: code.name,
      userMessage: userMessage,
      technicalMessage: 'Verification error: ${code.name} - $userMessage',
      exception: exception,
    );
  }
  
  // Helper function to get default message for failure codes
  static String _getDefaultMessageForCode(AppFailureCode code) {
    switch (code) {
      case AppFailureCode.unauthorized:
        return 'You do not have permission to perform this action';
      case AppFailureCode.operationFailed:
        return 'The verification operation failed';
      case AppFailureCode.invalidArgument:
        return 'Invalid information provided for verification';
      case AppFailureCode.notFound:
        return 'Verification record not found';
      default:
        return 'An error occurred with the verification process';
    }
  }
}

/// Firebase implementation of [VerificationRepository]
class FirebaseVerificationRepository implements VerificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Collection reference for verification data
  final CollectionReference _verificationCollection;

  /// Constructor
  FirebaseVerificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _verificationCollection = (firestore ?? FirebaseFirestore.instance).collection('user_verifications');

  @override
  Future<UserVerification?> getVerificationStatus(String userId) async {
    try {
      final docSnapshot = await _verificationCollection.doc(userId).get();
      
      if (!docSnapshot.exists) {
        return UserVerification.empty(userId);
      }
      
      return UserVerification.fromDocument(docSnapshot);
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      return null;
    }
  }

  @override
  Stream<UserVerification?> watchVerificationStatus(String userId) {
    return _verificationCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return UserVerification.empty(userId);
      }
      
      return UserVerification.fromDocument(snapshot);
    }).handleError((e) {
      debugPrint('Error watching verification status: $e');
      return null;
    });
  }

  @override
  Future<void> requestEmailVerification(String userId) async {
    final currentUser = _auth.currentUser;
    
    // Ensure the user is requesting verification for themselves
    if (currentUser == null || currentUser.uid != userId) {
      throw VerificationFailure.fromCode(
        AppFailureCode.unauthorized,
        message: 'You can only request verification for your own account',
      );
    }
    
    try {
      // Send email verification
      await currentUser.sendEmailVerification();
      
      // Record verification request in Firestore
      await _verificationCollection.doc(userId).set({
        'userId': userId,
        'level': VerificationLevel.verified.index,
        'status': VerificationStatus.pending.index,
        'submittedAt': FieldValue.serverTimestamp(),
        'verificationType': 'email',
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error requesting email verification: $e');
      throw VerificationFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to send verification email: ${e.toString()}',
        exception: e,
      );
    }
  }

  @override
  Future<void> submitVerifiedPlusClaim({
    required String userId,
    required String role,
    required String justification,
    String? documentUrl,
  }) async {
    final currentUser = _auth.currentUser;
    
    // Ensure the user is submitting for themselves
    if (currentUser == null || currentUser.uid != userId) {
      throw VerificationFailure.fromCode(
        AppFailureCode.unauthorized,
        message: 'You can only submit claims for your own account',
      );
    }
    
    try {
      // Create or update verification record
      await _verificationCollection.doc(userId).set({
        'userId': userId,
        'level': VerificationLevel.verifiedPlus.index,
        'status': VerificationStatus.pending.index,
        'submittedAt': FieldValue.serverTimestamp(),
        'verificationType': 'verification_plus',
        'metadata': {
          'role': role,
          'justification': justification,
          'documentUrl': documentUrl,
        },
      }, SetOptions(merge: true));
      
      // Create a verification request in the admin queue
      await _firestore.collection('verification_requests').add({
        'userId': userId,
        'userEmail': currentUser.email,
        'userName': currentUser.displayName,
        'requestType': 'verification_plus',
        'role': role,
        'justification': justification,
        'documentUrl': documentUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      debugPrint('Error submitting verified+ claim: $e');
      throw VerificationFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to submit verification claim: ${e.toString()}',
        exception: e,
      );
    }
  }

  @override
  Future<void> updateVerificationStatus({
    required String userId,
    required VerificationStatus newStatus,
    VerificationLevel? newLevel,
    String? rejectionReason,
    required String verifierId,
  }) async {
    final currentUser = _auth.currentUser;
    
    // Ensure the user is an admin or authorized verifier
    if (currentUser == null || currentUser.uid != verifierId) {
      // In a real app, check admin/verifier role here
      final isAdmin = await _checkIfUserIsAdmin(verifierId);
      if (!isAdmin) {
        throw VerificationFailure.fromCode(
          AppFailureCode.unauthorized,
          message: 'Only authorized verifiers can update verification status',
        );
      }
    }
    
    // Validate inputs
    if (newStatus == VerificationStatus.rejected && (rejectionReason == null || rejectionReason.isEmpty)) {
      throw VerificationFailure.fromCode(
        AppFailureCode.invalidArgument,
        message: 'Rejection reason is required when rejecting a verification',
      );
    }
    
    if (newStatus == VerificationStatus.verified && newLevel == null) {
      throw VerificationFailure.fromCode(
        AppFailureCode.invalidArgument,
        message: 'Verification level is required when verifying a user',
      );
    }
    
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.index,
        'verifierId': verifierId,
      };
      
      if (newStatus == VerificationStatus.verified) {
        updateData['level'] = newLevel!.index;
        updateData['verifiedAt'] = FieldValue.serverTimestamp();
      }
      
      if (newStatus == VerificationStatus.rejected) {
        updateData['rejectionReason'] = rejectionReason;
      }
      
      // Update verification status
      await _verificationCollection.doc(userId).set(updateData, SetOptions(merge: true));
      
      // Update request status in admin queue
      await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get()
          .then((snapshot) {
        for (final doc in snapshot.docs) {
          doc.reference.update({
            'status': newStatus == VerificationStatus.verified ? 'approved' : 'rejected',
            'verifierId': verifierId,
            'verifiedAt': newStatus == VerificationStatus.verified ? FieldValue.serverTimestamp() : null,
            'rejectionReason': rejectionReason,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
    } catch (e) {
      debugPrint('Error updating verification status: $e');
      throw VerificationFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to update verification status: ${e.toString()}',
        exception: e,
      );
    }
  }
  
  /// Check if a user has admin privileges
  Future<bool> _checkIfUserIsAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData != null && userData.containsKey('roles')) {
        final roles = List<String>.from(userData['roles'] ?? []);
        return roles.contains('admin') || roles.contains('verifier');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
} 