import 'package:hive_ui/features/community/domain/repositories/community_policy_repository.dart';

/// Use case for handling community rule violations
class HandleRuleViolationsUseCase {
  /// The community policy repository
  final CommunityPolicyRepository _repository;
  
  /// Constructor
  HandleRuleViolationsUseCase(this._repository);
  
  /// Get all rule violations for a user in a community
  Future<List<RuleViolationRecord>> getUserViolations({
    required String userId,
    required String communityId,
  }) async {
    return _repository.getUserViolations(
      userId: userId,
      communityId: communityId,
    );
  }
  
  /// Record a new rule violation for a user
  Future<String> recordViolation({
    required String userId,
    required String communityId,
    required String ruleId,
    required String moderatorId,
    String? notes,
  }) async {
    // Record the violation
    final violationId = await _repository.recordRuleViolation(
      userId: userId,
      communityId: communityId,
      ruleId: ruleId,
      moderatorId: moderatorId,
      notes: notes,
    );
    
    // Get the active policy to check if automatic consequences should be applied
    final policy = await _repository.getActivePolicyForCommunity(communityId);
    if (policy != null) {
      // Count existing violations for this user and rule
      final violations = await _repository.getUserViolations(
        userId: userId,
        communityId: communityId,
      );
      
      final violationsForThisRule = violations.where((v) => v.ruleId == ruleId).length;
      
      // Find the rule to get its severity
      final rule = policy.rules.firstWhere(
        (r) => r.id == ruleId,
        orElse: () => throw Exception('Rule not found in policy'),
      );
      
      // Check if any automatic consequences should be applied
      final applicableConsequences = policy.consequences.where((c) => 
        c.isAutomatic && 
        c.severity == rule.severity &&
        c.violationThreshold <= violationsForThisRule
      ).toList();
      
      if (applicableConsequences.isNotEmpty) {
        // In a real implementation, this would apply the consequences
        // This could involve calling other repositories or services
        
        // Just logging for now
        print('Automatic consequences would be applied: ${applicableConsequences.map((c) => c.title).join(', ')}');
      }
    }
    
    return violationId;
  }
} 