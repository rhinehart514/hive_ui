import 'package:hive_ui/features/community/domain/entities/community_policy_entity.dart';

/// Repository interface for community policies
abstract class CommunityPolicyRepository {
  /// Get a community policy by ID
  Future<CommunityPolicyEntity?> getPolicyById(String policyId);
  
  /// Get the active policy for a community
  Future<CommunityPolicyEntity?> getActivePolicyForCommunity(String communityId);
  
  /// Get all policies for a community (including inactive)
  Future<List<CommunityPolicyEntity>> getAllPoliciesForCommunity(String communityId);
  
  /// Create a new community policy
  Future<String> createPolicy(CommunityPolicyEntity policy);
  
  /// Update an existing community policy
  Future<void> updatePolicy(CommunityPolicyEntity policy);
  
  /// Delete a community policy
  Future<void> deletePolicy(String policyId);
  
  /// Set a policy as active for a community
  Future<void> setActivePolicyForCommunity({
    required String communityId,
    required String policyId,
  });
  
  /// Add a rule to a policy
  Future<void> addRuleToPolicy({
    required String policyId,
    required CommunityRuleEntity rule,
  });
  
  /// Update a rule in a policy
  Future<void> updateRule({
    required String policyId,
    required CommunityRuleEntity rule,
  });
  
  /// Remove a rule from a policy
  Future<void> removeRuleFromPolicy({
    required String policyId,
    required String ruleId,
  });
  
  /// Add a consequence to a policy
  Future<void> addConsequenceToPolicy({
    required String policyId,
    required PolicyConsequenceEntity consequence,
  });
  
  /// Update a consequence in a policy
  Future<void> updateConsequence({
    required String policyId,
    required PolicyConsequenceEntity consequence,
  });
  
  /// Remove a consequence from a policy
  Future<void> removeConsequenceFromPolicy({
    required String policyId,
    required String consequenceId,
  });
  
  /// Get rule violations for a user in a community
  Future<List<RuleViolationRecord>> getUserViolations({
    required String userId,
    required String communityId,
  });
  
  /// Record a rule violation for a user
  Future<String> recordRuleViolation({
    required String userId,
    required String communityId,
    required String ruleId,
    required String moderatorId,
    String? notes,
  });
}

/// Record of a rule violation by a user
class RuleViolationRecord {
  /// Unique identifier for the violation
  final String id;
  
  /// User ID of the violator
  final String userId;
  
  /// Community ID where the violation occurred
  final String communityId;
  
  /// Rule ID that was violated
  final String ruleId;
  
  /// Rule that was violated
  final CommunityRuleEntity rule;
  
  /// Moderator who recorded the violation
  final String moderatorId;
  
  /// Timestamp of the violation
  final DateTime timestamp;
  
  /// Optional notes about the violation
  final String? notes;
  
  /// ID of the consequence applied (if any)
  final String? consequenceId;
  
  /// Constructor
  const RuleViolationRecord({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.ruleId,
    required this.rule,
    required this.moderatorId,
    required this.timestamp,
    this.notes,
    this.consequenceId,
  });
} 