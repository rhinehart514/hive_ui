/// Types of moderation policies
enum ModerationPolicyType {
  global,
  spaceSpecific,
  eventSpecific,
  userSpecific,
}

/// Policy enforcement level
enum PolicyEnforcementLevel {
  suggestion,  // Just suggest to moderators
  warning,     // Warn but allow
  requireReview, // Require moderator review before publishing
  block,       // Block content
}

/// Domain entity for moderation policies
class ModerationPolicyEntity {
  /// Unique identifier for the policy
  final String id;
  
  /// Type of policy
  final ModerationPolicyType policyType;
  
  /// Display name of the policy
  final String name;
  
  /// Description of what the policy does
  final String description;
  
  /// Keywords and patterns this policy checks for
  final List<String> keywords;
  
  /// Regular expression patterns to match
  final List<String> regexPatterns;
  
  /// Whether this policy is currently active
  final bool isActive;
  
  /// Enforcement level for this policy
  final PolicyEnforcementLevel enforcementLevel;

  /// Scope ID (e.g., spaceId for space-specific policies)
  final String? scopeId;
  
  /// Whether to notify moderators when this policy is triggered
  final bool notifyModerators;
  
  /// Custom message to show when policy is triggered
  final String? warningMessage;
  
  /// When this policy was created
  final DateTime createdAt;
  
  /// When this policy was last updated
  final DateTime updatedAt;
  
  /// Constructor
  const ModerationPolicyEntity({
    required this.id,
    required this.policyType,
    required this.name,
    required this.description,
    required this.keywords,
    this.regexPatterns = const [],
    required this.isActive,
    required this.enforcementLevel,
    this.scopeId,
    this.notifyModerators = true,
    this.warningMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Create a copy with modified fields
  ModerationPolicyEntity copyWith({
    String? id,
    ModerationPolicyType? policyType,
    String? name,
    String? description,
    List<String>? keywords,
    List<String>? regexPatterns,
    bool? isActive,
    PolicyEnforcementLevel? enforcementLevel,
    String? scopeId,
    bool? notifyModerators,
    String? warningMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModerationPolicyEntity(
      id: id ?? this.id,
      policyType: policyType ?? this.policyType,
      name: name ?? this.name,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      regexPatterns: regexPatterns ?? this.regexPatterns,
      isActive: isActive ?? this.isActive,
      enforcementLevel: enforcementLevel ?? this.enforcementLevel,
      scopeId: scopeId ?? this.scopeId,
      notifyModerators: notifyModerators ?? this.notifyModerators,
      warningMessage: warningMessage ?? this.warningMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Check if the policy is global
  bool get isGlobal => policyType == ModerationPolicyType.global;
  
  /// Check if policy is space-specific
  bool get isSpaceSpecific => policyType == ModerationPolicyType.spaceSpecific;
  
  /// Create a default global policy
  factory ModerationPolicyEntity.defaultGlobal() {
    final now = DateTime.now();
    return ModerationPolicyEntity(
      id: 'default_global',
      policyType: ModerationPolicyType.global,
      name: 'Default Global Policy',
      description: 'Default policy applied to all content',
      keywords: [
        'spam',
        'scam',
        'offensive',
      ],
      isActive: true,
      enforcementLevel: PolicyEnforcementLevel.warning,
      notifyModerators: true,
      createdAt: now,
      updatedAt: now,
    );
  }
} 