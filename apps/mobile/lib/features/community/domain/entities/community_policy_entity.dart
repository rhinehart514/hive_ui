/// Entity for community policies and guidelines
class CommunityPolicyEntity {
  /// Unique identifier for the policy
  final String id;
  
  /// The space or community ID this policy applies to
  final String communityId;
  
  /// Title of the policy
  final String title;
  
  /// Full description of the policy
  final String description;
  
  /// Short summary of the policy for display
  final String summary;
  
  /// Last updated timestamp
  final DateTime lastUpdated;
  
  /// Version number of the policy
  final String version;
  
  /// Rules that are part of this policy
  final List<CommunityRuleEntity> rules;
  
  /// Consequences for violating the policy
  final List<PolicyConsequenceEntity> consequences;
  
  /// Appeals process description
  final String? appealsProcess;
  
  /// Whether this policy is currently active
  final bool isActive;
  
  /// Constructor
  const CommunityPolicyEntity({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.summary,
    required this.lastUpdated,
    required this.version,
    required this.rules,
    required this.consequences,
    this.appealsProcess,
    required this.isActive,
  });
  
  /// Create a copy with modified fields
  CommunityPolicyEntity copyWith({
    String? id,
    String? communityId,
    String? title,
    String? description,
    String? summary,
    DateTime? lastUpdated,
    String? version,
    List<CommunityRuleEntity>? rules,
    List<PolicyConsequenceEntity>? consequences,
    String? appealsProcess,
    bool? isActive,
  }) {
    return CommunityPolicyEntity(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      title: title ?? this.title,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      rules: rules ?? this.rules,
      consequences: consequences ?? this.consequences,
      appealsProcess: appealsProcess ?? this.appealsProcess,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Entity for individual community rules
class CommunityRuleEntity {
  /// Unique identifier for the rule
  final String id;
  
  /// Title or name of the rule
  final String title;
  
  /// Description of the rule
  final String description;
  
  /// Examples of rule violations
  final List<String> examples;
  
  /// Severity level of this rule
  final RuleSeverity severity;
  
  /// Whether this rule is currently active
  final bool isActive;
  
  /// Tags for categorizing this rule
  final List<String> tags;
  
  /// Constructor
  const CommunityRuleEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.examples,
    required this.severity,
    required this.isActive,
    required this.tags,
  });
  
  /// Create a copy with modified fields
  CommunityRuleEntity copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? examples,
    RuleSeverity? severity,
    bool? isActive,
    List<String>? tags,
  }) {
    return CommunityRuleEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      examples: examples ?? this.examples,
      severity: severity ?? this.severity,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
    );
  }
}

/// Entity for consequences of violating community policies
class PolicyConsequenceEntity {
  /// Unique identifier for the consequence
  final String id;
  
  /// Title or name of the consequence
  final String title;
  
  /// Description of the consequence
  final String description;
  
  /// The severity level this consequence applies to
  final RuleSeverity severity;
  
  /// Number of violations before this consequence applies
  final int violationThreshold;
  
  /// Duration of the consequence (if applicable)
  final Duration? duration;
  
  /// Whether this is a permanent consequence
  final bool isPermanent;
  
  /// Is this consequence applied automatically
  final bool isAutomatic;
  
  /// Constructor
  const PolicyConsequenceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.violationThreshold,
    this.duration,
    required this.isPermanent,
    required this.isAutomatic,
  });
  
  /// Create a copy with modified fields
  PolicyConsequenceEntity copyWith({
    String? id,
    String? title,
    String? description,
    RuleSeverity? severity,
    int? violationThreshold,
    Duration? duration,
    bool? isPermanent,
    bool? isAutomatic,
  }) {
    return PolicyConsequenceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      violationThreshold: violationThreshold ?? this.violationThreshold,
      duration: duration ?? this.duration,
      isPermanent: isPermanent ?? this.isPermanent,
      isAutomatic: isAutomatic ?? this.isAutomatic,
    );
  }
}

/// Severity levels for community rules
enum RuleSeverity {
  /// Low severity - minor rule violation
  low,
  
  /// Medium severity - significant rule violation
  medium,
  
  /// High severity - serious rule violation
  high,
  
  /// Critical severity - extreme rule violation
  critical,
} 