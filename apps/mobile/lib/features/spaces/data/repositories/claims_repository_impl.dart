import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/spaces/data/models/claim_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/claim_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/claims_repository.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of the ClaimsRepository interface
class ClaimsRepositoryImpl implements ClaimsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SpacesRepository _spacesRepository;

  /// Path to the claims collection in Firestore
  static const String _claimsCollection = 'claims';

  /// Constructor
  ClaimsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required SpacesRepository spacesRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _spacesRepository = spacesRepository;

  @override
  Future<ClaimEntity> submitClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String userEmail,
    required String role,
    required String verificationMethod,
    String? notes,
  }) async {
    try {
      // Check if the space exists and can be claimed
      final space = await _spacesRepository.getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }

      // Verify that the space is in the correct claim status
      if (space.claimStatus != SpaceClaimStatus.unclaimed) {
        throw Exception('Space cannot be claimed in its current state');
      }

      // Generate a unique ID for the claim
      final claimId = const Uuid().v4();

      // Create the claim model
      final claimModel = ClaimModel(
        id: claimId,
        spaceId: spaceId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        role: role,
        verificationMethod: verificationMethod,
        notes: notes,
        submittedAt: DateTime.now(),
        status: 'pending',
      );

      // Save to Firestore
      await _firestore
          .collection(_claimsCollection)
          .doc(claimId)
          .set(claimModel.toFirestore());

      // Update the space's claim status
      await _spacesRepository.updateClaimStatus(
        spaceId,
        SpaceClaimStatus.pending,
        claimId: claimId,
      );

      return claimModel.toEntity();
    } catch (e) {
      debugPrint('Error submitting claim: $e');
      rethrow;
    }
  }

  @override
  Future<ClaimEntity?> getClaimById(String claimId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_claimsCollection).doc(claimId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ClaimModel.fromFirestore(docSnapshot).toEntity();
    } catch (e) {
      debugPrint('Error getting claim by ID: $e');
      return null;
    }
  }

  @override
  Future<List<ClaimEntity>> getClaimsBySpaceId(String spaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_claimsCollection)
          .where('spaceId', isEqualTo: spaceId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ClaimModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting claims by space ID: $e');
      return [];
    }
  }

  @override
  Future<List<ClaimEntity>> getClaimsByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_claimsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ClaimModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting claims by user ID: $e');
      return [];
    }
  }

  @override
  Future<bool> approveClaim(String claimId, {String? adminId}) async {
    try {
      // Get the current admin ID or use the provided one
      final admin = adminId ?? _auth.currentUser?.uid;
      if (admin == null) {
        throw Exception('No admin ID provided and no current user');
      }

      // Get the claim
      final claim = await getClaimById(claimId);
      if (claim == null) {
        throw Exception('Claim not found');
      }

      // Update the claim status
      await _firestore.collection(_claimsCollection).doc(claimId).update({
        'status': 'approved',
        'processedBy': admin,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Update the space's claim status
      await _spacesRepository.updateClaimStatus(
        claim.spaceId,
        SpaceClaimStatus.claimed,
        claimId: claimId,
      );

      // Get the space to update its admins
      final space = await _spacesRepository.getSpaceById(claim.spaceId);
      if (space != null && !space.admins.contains(claim.userId)) {
        // Add the claimant as an admin
        await _spacesRepository.addAdmin(claim.spaceId, claim.userId);
      }

      return true;
    } catch (e) {
      debugPrint('Error approving claim: $e');
      return false;
    }
  }

  @override
  Future<bool> rejectClaim(String claimId,
      {String? adminId, String? rejectionReason}) async {
    try {
      // Get the current admin ID or use the provided one
      final admin = adminId ?? _auth.currentUser?.uid;
      if (admin == null) {
        throw Exception('No admin ID provided and no current user');
      }

      // Get the claim
      final claim = await getClaimById(claimId);
      if (claim == null) {
        throw Exception('Claim not found');
      }

      // Update the claim status
      await _firestore.collection(_claimsCollection).doc(claimId).update({
        'status': 'rejected',
        'processedBy': admin,
        'processedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      });

      // Update the space's claim status back to unclaimed
      await _spacesRepository.updateClaimStatus(
        claim.spaceId,
        SpaceClaimStatus.unclaimed,
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting claim: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelClaim(String claimId) async {
    try {
      // Get the claim
      final claim = await getClaimById(claimId);
      if (claim == null) {
        throw Exception('Claim not found');
      }

      // Verify the current user is the claimant
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != claim.userId) {
        throw Exception('Only the claimant can cancel a claim');
      }

      // Update the claim status
      await _firestore.collection(_claimsCollection).doc(claimId).update({
        'status': 'canceled',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Update the space's claim status back to unclaimed
      await _spacesRepository.updateClaimStatus(
        claim.spaceId,
        SpaceClaimStatus.unclaimed,
      );

      return true;
    } catch (e) {
      debugPrint('Error canceling claim: $e');
      return false;
    }
  }
} 