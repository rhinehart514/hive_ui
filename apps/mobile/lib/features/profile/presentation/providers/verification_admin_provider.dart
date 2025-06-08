import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';

/// Represents a verification request with all necessary data for admin review
class VerificationRequest {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final int currentLevel;
  final int requestedLevel;
  final String spaceId;
  final String role;
  final String? additionalInfo;
  final DateTime createdAt;
  final String status;

  VerificationRequest({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    required this.currentLevel,
    required this.requestedLevel,
    required this.spaceId,
    required this.role,
    this.additionalInfo,
    required this.createdAt,
    required this.status,
  });

  factory VerificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String?,
      userEmail: data['userEmail'] as String?,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      currentLevel: data['currentLevel'] as int,
      requestedLevel: data['requestedLevel'] as int,
      spaceId: data['spaceId'] as String,
      role: data['role'] as String,
      additionalInfo: data['additionalInfo'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] as String,
    );
  }
}

/// Provider that streams all pending verification requests
final pendingVerificationRequestsProvider = StreamProvider<List<VerificationRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection('verificationRequests')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => VerificationRequest.fromFirestore(doc))
            .toList();
      });
});

/// Tracks which request IDs are currently being processed to prevent double-processing
final processingRequestIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Controls the verification admin functionality
class VerificationAdminNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StateNotifierProviderRef _ref;
  
  VerificationAdminNotifier(this._ref)
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance,
        super(const AsyncValue.data(null));

  /// Approves a verification request
  Future<void> approveRequest(String requestId) async {
    final batch = _firestore.batch();
    
    try {
      // Add the request ID to processing set
      _ref.read(processingRequestIdsProvider.notifier).update((state) => 
        {...state, requestId});
      
      state = const AsyncValue.loading();
      
      // Get the request
      final requestDoc = await _firestore
          .collection('verificationRequests')
          .doc(requestId)
          .get();
      
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }
      
      final request = VerificationRequest.fromFirestore(requestDoc);
      
      // 1. Update the request status
      batch.update(
        _firestore.collection('verificationRequests').doc(requestId),
        {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': _auth.currentUser?.uid,
        },
      );
      
      // 2. Update the user's verification level
      final userRef = _firestore.collection('users').doc(request.userId);
      batch.update(userRef, {
        'verificationLevel': request.requestedLevel,
      });
      
      // 3. If this is a Verified+ request, add the user as a leader to the space
      if (request.requestedLevel == VerificationLevel.verifiedPlus.index) {
        final spaceRef = _firestore.collection('spaces').doc(request.spaceId);
        batch.update(spaceRef, {
          'leaders': FieldValue.arrayUnion([request.userId]),
        });
        
        // Add a role claim to the user's profile
        batch.update(userRef, {
          'roles': FieldValue.arrayUnion(['leader']),
          'leaderOf': FieldValue.arrayUnion([request.spaceId]),
        });
      }
      
      // Commit all changes in a single batch
      await batch.commit();
      
      // Update the user's custom claims via a Cloud Function
      // This call will trigger a cloud function to update the user's Firebase Auth claims
      await _firestore.collection('claimUpdates').add({
        'userId': request.userId,
        'verificationLevel': request.requestedLevel,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      // Remove the request ID from processing set
      _ref.read(processingRequestIdsProvider.notifier).update(
        (state) => state.difference({requestId}),
      );
    }
  }

  /// Rejects a verification request
  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      // Add the request ID to processing set
      _ref.read(processingRequestIdsProvider.notifier).update((state) => 
        {...state, requestId});
      
      state = const AsyncValue.loading();
      
      // Update the request
      await _firestore.collection('verificationRequests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectionReason': reason,
      });
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    } finally {
      // Remove the request ID from processing set
      _ref.read(processingRequestIdsProvider.notifier).update(
        (state) => state.difference({requestId}),
      );
    }
  }
}

/// Provider for the verification admin functionality
final verificationAdminProvider = StateNotifierProvider<VerificationAdminNotifier, AsyncValue<void>>(
  (ref) => VerificationAdminNotifier(ref),
); 