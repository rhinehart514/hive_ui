import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/spaces/data/models/leadership_claim_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/leadership_claim_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/leadership_claim_repository.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of LeadershipClaimRepository
class LeadershipClaimRepositoryImpl implements LeadershipClaimRepository {
  /// Firestore instance
  final FirebaseFirestore _firestore;
  
  /// Auth instance
  final FirebaseAuth _auth;
  
  /// Spaces repository to check space types
  final SpacesRepository _spacesRepository;
  
  /// Collection reference for leadership claims
  late final CollectionReference _claimsCollection;
  
  /// Constructor
  LeadershipClaimRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required SpacesRepository spacesRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _spacesRepository = spacesRepository {
    _claimsCollection = _firestore.collection('leadership_claims');
  }
  
  @override
  Future<LeadershipClaimEntity?> getClaimForSpace(String spaceId) async {
    try {
      final querySnapshot = await _claimsCollection
          .where('spaceId', isEqualTo: spaceId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final model = LeadershipClaimModel.fromFirestore(doc);
      return model.toEntity();
    } catch (e) {
      debugPrint('Error getting claim for space: $e');
      return null;
    }
  }

  @override
  Future<List<LeadershipClaimEntity>> getClaimsByStatus(LeadershipClaimStatus status) async {
    try {
      final statusString = _convertStatusToString(status);
      final querySnapshot = await _claimsCollection
          .where('status', isEqualTo: statusString)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LeadershipClaimModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting claims by status: $e');
      return [];
    }
  }

  @override
  Future<List<LeadershipClaimEntity>> getClaimsByUser(String userId) async {
    try {
      final querySnapshot = await _claimsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LeadershipClaimModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting claims by user: $e');
      return [];
    }
  }

  @override
  Future<LeadershipClaimEntity> createClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String role,
    required VerificationDocumentType documentType,
    String? documentUrl,
    required String notes,
  }) async {
    try {
      // Check if space exists and requires claim
      final requiresClaim = await spaceRequiresClaim(spaceId);
      if (!requiresClaim) {
        throw LeadershipClaimException('This space does not require a leadership claim');
      }
      
      // Check if claim already exists
      final existingClaim = await getClaimForSpace(spaceId);
      if (existingClaim != null && existingClaim.status != LeadershipClaimStatus.unclaimed) {
        throw LeadershipClaimException('A claim already exists for this space');
      }
      
      // Generate a new ID if no claim exists
      final claimId = existingClaim?.id ?? const Uuid().v4();
      
      // Create the claim entity
      final claim = LeadershipClaimEntity.pending(
        id: claimId,
        spaceId: spaceId,
        userId: userId,
        userName: userName,
        email: email,
        role: role,
        documentType: documentType,
        documentUrl: documentUrl,
        notes: notes,
      );
      
      // Convert to model and save to Firestore
      final model = LeadershipClaimModel.fromEntity(claim);
      await _claimsCollection.doc(claimId).set(model.toFirestore());
      
      return claim;
    } catch (e) {
      if (e is LeadershipClaimException) {
        rethrow;
      }
      debugPrint('Error creating claim: $e');
      throw LeadershipClaimException('Failed to create leadership claim: $e');
    }
  }

  @override
  Future<LeadershipClaimEntity> updateClaim(LeadershipClaimEntity claim) async {
    try {
      final model = LeadershipClaimModel.fromEntity(claim);
      await _claimsCollection.doc(claim.id).update(model.toFirestore());
      return claim;
    } catch (e) {
      debugPrint('Error updating claim: $e');
      throw LeadershipClaimException('Failed to update leadership claim: $e');
    }
  }

  @override
  Future<LeadershipClaimEntity> approveClaim({
    required String claimId,
    required String reviewerId,
    String? reviewNotes,
  }) async {
    try {
      // Get the claim
      final docSnapshot = await _claimsCollection.doc(claimId).get();
      if (!docSnapshot.exists) {
        throw LeadershipClaimException('Claim not found');
      }
      
      final claim = LeadershipClaimModel.fromFirestore(docSnapshot).toEntity();
      
      // Check if claim is pending
      if (claim.status != LeadershipClaimStatus.pending) {
        throw LeadershipClaimException('Only pending claims can be approved');
      }
      
      // Update the claim
      final updatedClaim = claim.withStatus(
        LeadershipClaimStatus.approved,
        reviewerId: reviewerId,
        reviewNotes: reviewNotes,
      );
      
      // Save the updated claim
      await updateClaim(updatedClaim);
      
      return updatedClaim;
    } catch (e) {
      if (e is LeadershipClaimException) {
        rethrow;
      }
      debugPrint('Error approving claim: $e');
      throw LeadershipClaimException('Failed to approve claim: $e');
    }
  }

  @override
  Future<LeadershipClaimEntity> rejectClaim({
    required String claimId,
    required String reviewerId,
    required String reviewNotes,
  }) async {
    try {
      // Get the claim
      final docSnapshot = await _claimsCollection.doc(claimId).get();
      if (!docSnapshot.exists) {
        throw LeadershipClaimException('Claim not found');
      }
      
      final claim = LeadershipClaimModel.fromFirestore(docSnapshot).toEntity();
      
      // Check if claim is pending
      if (claim.status != LeadershipClaimStatus.pending) {
        throw LeadershipClaimException('Only pending claims can be rejected');
      }
      
      // Update the claim
      final updatedClaim = claim.withStatus(
        LeadershipClaimStatus.rejected,
        reviewerId: reviewerId,
        reviewNotes: reviewNotes,
      );
      
      // Save the updated claim
      await updateClaim(updatedClaim);
      
      return updatedClaim;
    } catch (e) {
      if (e is LeadershipClaimException) {
        rethrow;
      }
      debugPrint('Error rejecting claim: $e');
      throw LeadershipClaimException('Failed to reject claim: $e');
    }
  }

  @override
  Future<bool> cancelClaim({
    required String claimId,
    required String userId,
  }) async {
    try {
      // Get the claim
      final docSnapshot = await _claimsCollection.doc(claimId).get();
      if (!docSnapshot.exists) {
        throw LeadershipClaimException('Claim not found');
      }
      
      final claim = LeadershipClaimModel.fromFirestore(docSnapshot).toEntity();
      
      // Check if the user is the original claimant
      if (claim.userId != userId) {
        throw LeadershipClaimException('Only the original claimant can cancel a claim');
      }
      
      // Check if claim is pending (only pending claims can be canceled)
      if (claim.status != LeadershipClaimStatus.pending) {
        throw LeadershipClaimException('Only pending claims can be canceled');
      }
      
      // For spaces that must have a claim, we set status back to unclaimed
      // otherwise we can delete the claim document
      if (await spaceRequiresClaim(claim.spaceId)) {
        // Create unclaimed entity
        final unclaimedEntity = LeadershipClaimEntity.unclaimed(
          id: claim.id,
          spaceId: claim.spaceId,
        );
        
        // Update the claim
        await updateClaim(unclaimedEntity);
      } else {
        // Delete the claim
        await _claimsCollection.doc(claimId).delete();
      }
      
      return true;
    } catch (e) {
      if (e is LeadershipClaimException) {
        rethrow;
      }
      debugPrint('Error canceling claim: $e');
      throw LeadershipClaimException('Failed to cancel claim: $e');
    }
  }

  @override
  Future<bool> spaceRequiresClaim(String spaceId) async {
    try {
      // Get the space
      final space = await _spacesRepository.getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Check if space is pre-seeded (i.e., not HIVE-exclusive)
      return _isPreSeededSpace(space);
    } catch (e) {
      debugPrint('Error checking if space requires claim: $e');
      return false;
    }
  }

  @override
  Future<List<LeadershipClaimEntity>> getAllPendingClaims() async {
    return getClaimsByStatus(LeadershipClaimStatus.pending);
  }

  @override
  Future<List<LeadershipClaimEntity>> getAllClaims() async {
    try {
      final querySnapshot = await _claimsCollection.get();
      
      return querySnapshot.docs
          .map((doc) => LeadershipClaimModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Error getting all claims: $e');
      return [];
    }
  }
  
  /// Check if a space is pre-seeded (not HIVE-exclusive)
  bool _isPreSeededSpace(SpaceEntity space) {
    // Pre-seeded spaces are those that aren't HIVE-exclusive
    // They include student orgs, university orgs, campus living, and fraternities/sororities
    return !space.hiveExclusive && space.spaceType != SpaceType.hiveExclusive;
  }
  
  /// Convert status enum to string for Firestore
  String _convertStatusToString(LeadershipClaimStatus status) {
    switch (status) {
      case LeadershipClaimStatus.unclaimed:
        return 'unclaimed';
      case LeadershipClaimStatus.pending:
        return 'pending';
      case LeadershipClaimStatus.approved:
        return 'approved';
      case LeadershipClaimStatus.rejected:
        return 'rejected';
    }
  }
} 