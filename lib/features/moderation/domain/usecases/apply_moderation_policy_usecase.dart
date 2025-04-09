import 'package:hive_ui/features/moderation/domain/entities/moderation_policy_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Result of applying a moderation policy
class ModerationResult {
  /// Whether the content violates any policies
  final bool hasPolicyViolation;
  
  /// The policies that were violated
  final List<ModerationPolicyEntity> violatedPolicies;
  
  /// Most severe enforcement level from violated policies
  final PolicyEnforcementLevel? enforcementLevel;
  
  /// Messages to display to the user
  final List<String> warningMessages;
  
  /// Matched keywords found in content
  final Map<String, List<String>> matches;
  
  /// Constructor
  ModerationResult({
    required this.hasPolicyViolation,
    required this.violatedPolicies,
    this.enforcementLevel,
    required this.warningMessages,
    required this.matches,
  });
  
  /// Create an empty result (no violations)
  factory ModerationResult.noViolations() {
    return ModerationResult(
      hasPolicyViolation: false,
      violatedPolicies: const [],
      warningMessages: const [],
      matches: const {},
    );
  }
}

/// Use case for applying moderation policies to content
class ApplyModerationPolicyUseCase {
  final ModerationRepository _repository;
  
  /// Constructor
  ApplyModerationPolicyUseCase(this._repository);
  
  /// Apply moderation policies to a piece of content
  /// Returns a ModerationResult with any policy violations
  Future<ModerationResult> call({
    required String content,
    String? spaceId,
    String? eventId,
    String? userId,
  }) async {
    // This is just a basic implementation - a real implementation would:
    // 1. Fetch relevant policies (global + any space/event/user specific ones)
    // 2. Apply each policy to the content (check keywords, regex patterns)
    // 3. Aggregate results and determine the highest enforcement level
    
    // Simulate policy checking with basic keyword matching
    bool hasViolation = false;
    final violatedPolicies = <ModerationPolicyEntity>[];
    final warningMessages = <String>[];
    final matches = <String, List<String>>{};
    PolicyEnforcementLevel? highestLevel;
    
    try {
      // Get relevant policies
      // For V1, we're keeping it simple with just a scan of the content
      final contentLower = content.toLowerCase();
      final result = await _repository.scanContent(
        content: content,
        spaceId: spaceId ?? 'global',
      );
      
      if (result) {
        // Simulated violation for demo purposes
        hasViolation = true;
        
        // In a real implementation, we'd have the actual policies and matched terms
        // This is just a placeholder that returns a basic result
        final defaultPolicy = ModerationPolicyEntity.defaultGlobal();
        violatedPolicies.add(defaultPolicy);
        
        warningMessages.add(
          defaultPolicy.warningMessage ?? 
          'This content may violate our community guidelines.'
        );
        
        // Find which keywords matched (simplified)
        for (final keyword in defaultPolicy.keywords) {
          if (contentLower.contains(keyword.toLowerCase())) {
            if (matches.containsKey(defaultPolicy.id)) {
              matches[defaultPolicy.id]!.add(keyword);
            } else {
              matches[defaultPolicy.id] = [keyword];
            }
          }
        }
        
        highestLevel = defaultPolicy.enforcementLevel;
      }
      
      return ModerationResult(
        hasPolicyViolation: hasViolation,
        violatedPolicies: violatedPolicies,
        enforcementLevel: highestLevel,
        warningMessages: warningMessages,
        matches: matches,
      );
      
    } catch (e) {
      print('Error applying moderation policies: $e');
      // Default to allowing content if there's an error
      return ModerationResult.noViolations();
    }
  }
} 