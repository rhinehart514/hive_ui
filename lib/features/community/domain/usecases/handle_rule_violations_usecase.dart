import 'package:dartz/dartz.dart';
import 'package:hive_ui/core/error/failures.dart';
import 'package:hive_ui/features/community/domain/entities/community_policy.dart';
import 'package:hive_ui/features/community/domain/repositories/community_policy_repository.dart';

/// Use case for handling community rule violations
class HandleRuleViolationsUseCase {
  /// The community policy repository
  final CommunityPolicyRepository _repository;
  
  /// Constructor
  HandleRuleViolationsUseCase(this._repository);
  
  /// Report a violation of community policy
  Future<Either<Failure, void>> reportViolation({
    required String contentId,
    required String contentType,
    required String reporterId,
    required String violationType,
    String? description,
  }) async {
    try {
      // Report the violation
      final result = await _repository.reportViolation(
        contentId: contentId,
        contentType: contentType,
        reporterId: reporterId,
        violationType: violationType,
        description: description,
      );

      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to report violation',
        code: 'REPORT_VIOLATION_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Check if content complies with community policy
  Future<Either<Failure, bool>> checkContentCompliance({
    required String contentId,
    required String contentType,
    String? spaceId,
  }) async {
    try {
      // Check content compliance
      final result = await _repository.checkContentCompliance(
        contentId: contentId,
        contentType: contentType,
        spaceId: spaceId,
      );

      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to check content compliance',
        code: 'CHECK_COMPLIANCE_ERROR',
        details: e.toString(),
      ));
    }
  }
  
  /// Get active policy rules for a space
  Future<Either<Failure, List<PolicyRule>>> getSpaceRules(String spaceId) async {
    try {
      // Get space-specific rules
      final result = await _repository.getSpacePolicyRules(spaceId);

      return result;
    } catch (e) {
      return Left(CommunityPolicyFailure(
        message: 'Failed to get space rules',
        code: 'GET_SPACE_RULES_ERROR',
        details: e.toString(),
      ));
    }
  }
} 