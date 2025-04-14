import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a community policy with its rules and guidelines
class CommunityPolicy extends Equatable {
  /// Unique identifier for the policy
  final String id;

  /// Version of the policy (e.g., "1.0.0")
  final String version;

  /// When this policy version was published
  final DateTime publishedAt;

  /// When this policy version becomes effective
  final DateTime effectiveFrom;

  /// List of rules in this policy
  final List<PolicyRule> rules;

  /// Whether this is the currently active policy
  final bool isActive;

  /// Optional summary of changes from previous version
  final String? changeLog;

  const CommunityPolicy({
    required this.id,
    required this.version,
    required this.publishedAt,
    required this.effectiveFrom,
    required this.rules,
    this.isActive = false,
    this.changeLog,
  });

  @override
  List<Object?> get props => [
        id,
        version,
        publishedAt,
        effectiveFrom,
        rules,
        isActive,
        changeLog,
      ];
}

/// Represents a single rule in the community policy
class PolicyRule extends Equatable {
  /// Unique identifier for the rule
  final String id;

  /// Title of the rule
  final String title;

  /// Detailed description of the rule
  final String description;

  /// Category of the rule (e.g., "content", "behavior", "safety")
  final String category;

  /// Severity level of violating this rule (1-5)
  final int severityLevel;

  /// List of consequences for violating this rule
  final List<PolicyConsequence> consequences;

  /// Whether this rule is currently enforced
  final bool isEnforced;

  /// Examples of violations (for clarity)
  final List<String>? examples;

  const PolicyRule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severityLevel,
    required this.consequences,
    this.isEnforced = true,
    this.examples,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        severityLevel,
        consequences,
        isEnforced,
        examples,
      ];
}

/// Represents a consequence for violating a policy rule
class PolicyConsequence extends Equatable {
  /// Unique identifier for the consequence
  final String id;

  /// Type of consequence (e.g., "warning", "temporary_ban", "permanent_ban")
  final String type;

  /// Description of the consequence
  final String description;

  /// Duration of the consequence (if applicable)
  final Duration? duration;

  /// Whether this requires moderator review
  final bool requiresModeratorReview;

  /// Number of violations before this consequence is applied
  final int? violationThreshold;

  const PolicyConsequence({
    required this.id,
    required this.type,
    required this.description,
    this.duration,
    this.requiresModeratorReview = false,
    this.violationThreshold,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        description,
        duration,
        requiresModeratorReview,
        violationThreshold,
      ];
}

/// Represents a violation of a policy rule
class PolicyViolation extends Equatable {
  /// Unique identifier for the violation
  final String id;

  /// ID of the rule that was violated
  final String ruleId;

  /// ID of the user who violated the rule
  final String userId;

  /// ID of the content that violated the rule (if applicable)
  final String? contentId;

  /// Type of content that violated the rule (if applicable)
  final String? contentType;

  /// When the violation occurred
  final DateTime timestamp;

  /// ID of the moderator who reviewed the violation (if applicable)
  final String? moderatorId;

  /// Status of the violation (e.g., "pending", "reviewed", "appealed")
  final String status;

  /// Notes about the violation
  final String? notes;

  /// ID of the consequence applied
  final String? appliedConsequenceId;

  const PolicyViolation({
    required this.id,
    required this.ruleId,
    required this.userId,
    required this.timestamp,
    required this.status,
    this.contentId,
    this.contentType,
    this.moderatorId,
    this.notes,
    this.appliedConsequenceId,
  });

  @override
  List<Object?> get props => [
        id,
        ruleId,
        userId,
        contentId,
        contentType,
        timestamp,
        moderatorId,
        status,
        notes,
        appliedConsequenceId,
      ];
} 