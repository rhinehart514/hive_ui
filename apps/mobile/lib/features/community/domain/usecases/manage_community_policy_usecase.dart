import 'package:dartz/dartz.dart';
import 'package:hive_ui/core/error/failures.dart';
import 'package:hive_ui/features/community/domain/entities/community_policy.dart';
import 'package:hive_ui/features/community/domain/repositories/community_policy_repository.dart';

/// Use case for managing community policies
class ManageCommunityPolicyUseCase {
  /// The community policy repository
  final CommunityPolicyRepository _repository;
  
  /// Constructor
  ManageCommunityPolicyUseCase(this._repository);
  
  /// Get the current active community policy
  Future<Either<Failure, CommunityPolicy>> getCurrentPolicy() async {
    try {
      final result = await _repository.getCurrentPolicy();
      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to get current policy',
        code: 'GET_POLICY_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Get the history of community policies
  Future<Either<Failure, List<CommunityPolicy>>> getPolicyHistory() async {
    try {
      final result = await _repository.getPolicyHistory();
      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to get policy history',
        code: 'GET_HISTORY_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Check if a user has accepted the latest policy
  Future<Either<Failure, bool>> hasUserAcceptedLatestPolicy(String userId) async {
    try {
      final result = await _repository.hasUserAcceptedLatestPolicy(userId);
      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to check policy acceptance',
        code: 'CHECK_ACCEPTANCE_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Record a user's acceptance of the current policy
  Future<Either<Failure, void>> recordPolicyAcceptance(String userId) async {
    try {
      final result = await _repository.recordPolicyAcceptance(userId);
      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to record policy acceptance',
        code: 'RECORD_ACCEPTANCE_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Get a specific version of the policy
  Future<Either<Failure, CommunityPolicy>> getPolicyVersion(String versionId) async {
    try {
      final result = await _repository.getPolicyVersion(versionId);
      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to get policy version',
        code: 'GET_VERSION_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Get users who haven't accepted the latest policy
  Future<Either<Failure, List<String>>> getUsersPendingAcceptance() async {
    try {
      final result = await _repository.getUsersPendingAcceptance();
      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to get pending users',
        code: 'GET_PENDING_USERS_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Stream updates for the current policy
  Stream<Either<Failure, CommunityPolicy>> policyUpdates() {
    try {
      return _repository.policyUpdates();
    } catch (e) {
      return Stream.value(Left(CommunityPolicyFailure(
        message: 'Failed to initialize policy updates stream',
        code: 'POLICY_UPDATES_INIT_ERROR',
        details: e.toString(),
      )));
    }
  }
} 