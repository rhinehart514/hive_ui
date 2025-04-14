import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/error/failures.dart';
import 'package:hive_ui/features/community/domain/entities/community_policy.dart';
import 'package:hive_ui/features/community/domain/repositories/community_policy_repository.dart';

/// Implementation of [CommunityPolicyRepository] using Firestore as data source
class CommunityPolicyRepositoryImpl implements CommunityPolicyRepository {
  final FirebaseFirestore _firestore;
  final String _policyCollection = 'community_policies';
  final String _acceptanceCollection = 'policy_acceptances';
  final String _violationsCollection = 'policy_violations';

  CommunityPolicyRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, CommunityPolicy>> getCurrentPolicy() async {
    try {
      final snapshot = await _firestore
          .collection(_policyCollection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return Left(PolicyVersionNotFoundFailure(
          message: 'No active policy found',
          code: 'NO_ACTIVE_POLICY',
        ));
      }

      return Right(_mapToCommunityPolicy(snapshot.docs.first));
    } catch (e) {
      debugPrint('Error getting current policy: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to get current policy',
        code: 'GET_POLICY_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<CommunityPolicy>>> getPolicyHistory() async {
    try {
      final snapshot = await _firestore
          .collection(_policyCollection)
          .orderBy('effectiveFrom', descending: true)
          .get();

      final policies = snapshot.docs.map(_mapToCommunityPolicy).toList();
      return Right(policies);
    } catch (e) {
      debugPrint('Error getting policy history: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to get policy history',
        code: 'GET_HISTORY_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUserAcceptedLatestPolicy(String userId) async {
    try {
      final currentPolicyResult = await getCurrentPolicy();
      if (currentPolicyResult.isLeft()) {
        return currentPolicyResult.fold(
          (failure) => Left(failure),
          (policy) => Right(false), // Unreachable
        );
      }

      final currentPolicy = currentPolicyResult.getOrElse(() => throw Exception());
      final acceptance = await _firestore
          .collection(_acceptanceCollection)
          .where('userId', isEqualTo: userId)
          .where('policyId', isEqualTo: currentPolicy.id)
          .limit(1)
          .get();

      return Right(acceptance.docs.isNotEmpty);
    } catch (e) {
      debugPrint('Error checking policy acceptance: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to check policy acceptance',
        code: 'CHECK_ACCEPTANCE_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> recordPolicyAcceptance(String userId) async {
    try {
      final currentPolicyResult = await getCurrentPolicy();
      if (currentPolicyResult.isLeft()) {
        return currentPolicyResult.fold(
          (failure) => Left(failure),
          (policy) => Right(null), // Unreachable
        );
      }

      final currentPolicy = currentPolicyResult.getOrElse(() => throw Exception());
      await _firestore.collection(_acceptanceCollection).add({
        'userId': userId,
        'policyId': currentPolicy.id,
        'acceptedAt': FieldValue.serverTimestamp(),
        'policyVersion': currentPolicy.version,
      });

      return const Right(null);
    } catch (e) {
      debugPrint('Error recording policy acceptance: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to record policy acceptance',
        code: 'RECORD_ACCEPTANCE_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, CommunityPolicy>> getPolicyVersion(String versionId) async {
    try {
      final doc = await _firestore.collection(_policyCollection).doc(versionId).get();
      if (!doc.exists) {
        return Left(PolicyVersionNotFoundFailure(
          message: 'Policy version not found',
          code: 'VERSION_NOT_FOUND',
        ));
      }

      return Right(_mapToCommunityPolicy(doc));
    } catch (e) {
      debugPrint('Error getting policy version: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to get policy version',
        code: 'GET_VERSION_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getUsersPendingAcceptance() async {
    try {
      final currentPolicyResult = await getCurrentPolicy();
      if (currentPolicyResult.isLeft()) {
        return currentPolicyResult.fold(
          (failure) => Left(failure),
          (policy) => Right([]), // Unreachable
        );
      }

      final currentPolicy = currentPolicyResult.getOrElse(() => throw Exception());
      final acceptances = await _firestore
          .collection(_acceptanceCollection)
          .where('policyId', isEqualTo: currentPolicy.id)
          .get();

      final acceptedUsers = acceptances.docs.map((doc) => doc['userId'] as String).toSet();
      
      // In a real implementation, you would query your users collection
      // and filter out the accepted users. This is a simplified version.
      return Right([]); // Return empty list for now
    } catch (e) {
      debugPrint('Error getting users pending acceptance: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to get users pending acceptance',
        code: 'GET_PENDING_USERS_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> checkContentCompliance({
    required String contentId,
    required String contentType,
    String? spaceId,
  }) async {
    try {
      // In a real implementation, this would use ML/AI or moderation APIs
      // For now, we'll just check if there are any violations recorded
      final violations = await _firestore
          .collection(_violationsCollection)
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .where('status', isEqualTo: 'confirmed')
          .limit(1)
          .get();

      return Right(violations.docs.isEmpty);
    } catch (e) {
      debugPrint('Error checking content compliance: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to check content compliance',
        code: 'CHECK_COMPLIANCE_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> reportViolation({
    required String contentId,
    required String contentType,
    required String reporterId,
    required String violationType,
    String? description,
  }) async {
    try {
      await _firestore.collection(_violationsCollection).add({
        'contentId': contentId,
        'contentType': contentType,
        'reporterId': reporterId,
        'violationType': violationType,
        'description': description,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return const Right(null);
    } catch (e) {
      debugPrint('Error reporting violation: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to report violation',
        code: 'REPORT_VIOLATION_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<PolicyRule>>> getSpacePolicyRules(String spaceId) async {
    try {
      final currentPolicyResult = await getCurrentPolicy();
      if (currentPolicyResult.isLeft()) {
        return currentPolicyResult.fold(
          (failure) => Left(failure),
          (policy) => Right([]), // Unreachable
        );
      }

      final currentPolicy = currentPolicyResult.getOrElse(() => throw Exception());
      
      // In a real implementation, you might have space-specific rules
      // For now, we'll just return the global policy rules
      return Right(currentPolicy.rules);
    } catch (e) {
      debugPrint('Error getting space policy rules: $e');
      return Left(CommunityPolicyFailure(
        message: 'Failed to get space policy rules',
        code: 'GET_SPACE_RULES_ERROR',
        details: e.toString(),
      ));
    }
  }

  @override
  Stream<Either<Failure, CommunityPolicy>> policyUpdates() {
    return _firestore
        .collection(_policyCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          return Left(PolicyVersionNotFoundFailure(
            message: 'No active policy found',
            code: 'NO_ACTIVE_POLICY',
          ));
        }

        return Right(_mapToCommunityPolicy(snapshot.docs.first));
      } catch (e) {
        debugPrint('Error in policy updates stream: $e');
        return Left(CommunityPolicyFailure(
          message: 'Failed to process policy update',
          code: 'POLICY_UPDATE_ERROR',
          details: e.toString(),
        ));
      }
    });
  }

  /// Maps a Firestore document to a [CommunityPolicy] entity
  CommunityPolicy _mapToCommunityPolicy(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPolicy(
      id: doc.id,
      version: data['version'] as String,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      effectiveFrom: (data['effectiveFrom'] as Timestamp).toDate(),
      rules: (data['rules'] as List<dynamic>)
          .map((rule) => _mapToPolicyRule(rule as Map<String, dynamic>))
          .toList(),
      isActive: data['isActive'] as bool? ?? false,
      changeLog: data['changeLog'] as String?,
    );
  }

  /// Maps a Firestore map to a [PolicyRule] entity
  PolicyRule _mapToPolicyRule(Map<String, dynamic> data) {
    return PolicyRule(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      severityLevel: data['severityLevel'] as int,
      consequences: (data['consequences'] as List<dynamic>)
          .map((consequence) =>
              _mapToPolicyConsequence(consequence as Map<String, dynamic>))
          .toList(),
      isEnforced: data['isEnforced'] as bool? ?? true,
      examples: (data['examples'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Maps a Firestore map to a [PolicyConsequence] entity
  PolicyConsequence _mapToPolicyConsequence(Map<String, dynamic> data) {
    return PolicyConsequence(
      id: data['id'] as String,
      type: data['type'] as String,
      description: data['description'] as String,
      duration: data['durationInSeconds'] != null
          ? Duration(seconds: data['durationInSeconds'] as int)
          : null,
      requiresModeratorReview: data['requiresModeratorReview'] as bool? ?? false,
      violationThreshold: data['violationThreshold'] as int?,
    );
  }
} 