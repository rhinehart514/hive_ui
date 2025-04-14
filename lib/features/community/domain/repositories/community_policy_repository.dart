import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/community/domain/entities/community_policy.dart';
import 'package:hive_ui/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Repository interface for managing community policies and guidelines
abstract class CommunityPolicyRepository {
  /// Get the current community policy
  Future<Either<Failure, CommunityPolicy>> getCurrentPolicy();

  /// Get policy history with version tracking
  Future<Either<Failure, List<CommunityPolicy>>> getPolicyHistory();

  /// Check if a user has accepted the latest policy
  Future<Either<Failure, bool>> hasUserAcceptedLatestPolicy(String userId);

  /// Record user's acceptance of the current policy
  Future<Either<Failure, void>> recordPolicyAcceptance(String userId);

  /// Get specific policy version
  Future<Either<Failure, CommunityPolicy>> getPolicyVersion(String versionId);

  /// Get list of users who haven't accepted latest policy
  Future<Either<Failure, List<String>>> getUsersPendingAcceptance();

  /// Check if content complies with community policy
  Future<Either<Failure, bool>> checkContentCompliance({
    required String contentId,
    required String contentType,
    @required String? spaceId,
  });

  /// Report policy violation
  Future<Either<Failure, void>> reportViolation({
    required String contentId,
    required String contentType,
    required String reporterId,
    required String violationType,
    String? description,
  });

  /// Get active policy rules for a specific space
  Future<Either<Failure, List<PolicyRule>>> getSpacePolicyRules(String spaceId);

  /// Stream of policy updates
  Stream<Either<Failure, CommunityPolicy>> policyUpdates();
} 