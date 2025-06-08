import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/verification_request.dart';
import 'package:uuid/uuid.dart';

/// Service to handle verification requests for spaces and organizations
class VerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _verificationRequestsCollection = 'verification_requests';

  /// Submit a new verification request
  static Future<VerificationRequest> submitVerificationRequest({
    required String objectId,
    required String objectType,
    required String name,
    String? message,
    VerificationType verificationType = VerificationType.standard,
    Map<String, String>? additionalDocuments,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(
            'User must be authenticated to submit a verification request');
      }

      // Check if there's already a pending request for this object
      final existingRequests = await _firestore
          .collection(_verificationRequestsCollection)
          .where('objectId', isEqualTo: objectId)
          .where('status', isEqualTo: VerificationRequestStatus.pending.name)
          .get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception(
            'A pending verification request already exists for this space');
      }

      // Get user's display name and photo URL
      final String requesterName = currentUser.displayName ?? 'Unknown User';
      final String? requesterAvatarUrl = currentUser.photoURL;

      // Create a new verification request
      final String requestId = const Uuid().v4();
      final VerificationRequest request = VerificationRequest(
        id: requestId,
        objectId: objectId,
        objectType: objectType,
        name: name,
        requesterId: currentUser.uid,
        requesterName: requesterName,
        requesterAvatarUrl: requesterAvatarUrl,
        message: message,
        createdAt: DateTime.now(),
        status: VerificationRequestStatus.pending,
        verificationType: verificationType,
        additionalDocuments: additionalDocuments,
      );

      // Save the request to Firestore
      await _firestore
          .collection(_verificationRequestsCollection)
          .doc(requestId)
          .set(request.toMap());

      return request;
    } catch (e) {
      debugPrint('Error submitting verification request: $e');
      rethrow;
    }
  }

  /// Get all verification requests for the current user
  static Future<List<VerificationRequest>> getUserVerificationRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection(_verificationRequestsCollection)
          .where('requesterId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              VerificationRequest.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting user verification requests: $e');
      return [];
    }
  }

  /// Get verification requests for a specific object
  static Future<List<VerificationRequest>> getObjectVerificationRequests(
      String objectId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_verificationRequestsCollection)
          .where('objectId', isEqualTo: objectId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              VerificationRequest.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting object verification requests: $e');
      return [];
    }
  }

  /// Get all pending verification requests (admin only)
  static Future<List<VerificationRequest>> getAllPendingRequests() async {
    try {
      // Check if user is an admin (this should be implemented properly based on your auth system)
      // For now, we'll proceed assuming the user has permission

      final querySnapshot = await _firestore
          .collection(_verificationRequestsCollection)
          .where('status', isEqualTo: VerificationRequestStatus.pending.name)
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs
          .map((doc) =>
              VerificationRequest.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending verification requests: $e');
      return [];
    }
  }

  /// Approve a verification request (admin only)
  static Future<bool> approveVerificationRequest(
    String requestId, {
    bool grantVerifiedPlus = false,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(
            'User must be authenticated to approve a verification request');
      }

      // Get the request document
      final docRef =
          _firestore.collection(_verificationRequestsCollection).doc(requestId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Verification request not found');
      }

      final requestData = docSnapshot.data()!;
      final objectId = requestData['objectId'] as String;
      final objectType = requestData['objectType'] as String;

      // Update the request status
      await docRef.update({
        'status': VerificationRequestStatus.approved.name,
        'approvedBy': currentUser.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Update the object's verification status
      final String collectionPath =
          objectType == 'organization' ? 'organizations' : 'spaces';
      final objectRef = _firestore.collection(collectionPath).doc(objectId);

      await objectRef.update({
        'isVerified': true,
        'isVerifiedPlus': grantVerifiedPlus,
        'verificationDate': FieldValue.serverTimestamp(),
        'verifiedBy': currentUser.uid,
      });

      return true;
    } catch (e) {
      debugPrint('Error approving verification request: $e');
      return false;
    }
  }

  /// Reject a verification request (admin only)
  static Future<bool> rejectVerificationRequest(
    String requestId, {
    String? rejectionReason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(
            'User must be authenticated to reject a verification request');
      }

      // Update the request status
      await _firestore
          .collection(_verificationRequestsCollection)
          .doc(requestId)
          .update({
        'status': VerificationRequestStatus.rejected.name,
        'approvedBy': currentUser.uid,
        'rejectionReason': rejectionReason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error rejecting verification request: $e');
      return false;
    }
  }

  /// Cancel a verification request (can only be done by the requester)
  static Future<bool> cancelVerificationRequest(String requestId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception(
            'User must be authenticated to cancel a verification request');
      }

      // Get the request document
      final docRef =
          _firestore.collection(_verificationRequestsCollection).doc(requestId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Verification request not found');
      }

      final requestData = docSnapshot.data()!;
      final requesterId = requestData['requesterId'] as String;

      // Ensure the current user is the requester
      if (requesterId != currentUser.uid) {
        throw Exception('Only the requester can cancel a verification request');
      }

      // Update the request status
      await docRef.update({
        'status': VerificationRequestStatus.cancelled.name,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error cancelling verification request: $e');
      return false;
    }
  }

  /// Check if a user can request verification for an object
  static Future<bool> canRequestVerification(
      String objectId, String objectType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Check if there's already a pending request for this object
      final existingRequests = await _firestore
          .collection(_verificationRequestsCollection)
          .where('objectId', isEqualTo: objectId)
          .where('status', isEqualTo: VerificationRequestStatus.pending.name)
          .get();

      if (existingRequests.docs.isNotEmpty) {
        return false;
      }

      // Check if the object is already verified
      final String collectionPath =
          objectType == 'organization' ? 'organizations' : 'spaces';
      final objectDoc =
          await _firestore.collection(collectionPath).doc(objectId).get();

      if (!objectDoc.exists) {
        return false;
      }

      final objectData = objectDoc.data()!;
      if (objectData['isVerified'] == true) {
        return false;
      }

      // Check if user has permission to request verification
      // This logic might depend on your specific requirements
      // For example, you might check if the user is an admin or owner of the space/organization

      return true;
    } catch (e) {
      debugPrint('Error checking verification eligibility: $e');
      return false;
    }
  }
}
