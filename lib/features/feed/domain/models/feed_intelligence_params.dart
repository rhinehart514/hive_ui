import 'package:flutter/foundation.dart';

/// Parameters used by the Feed Intelligence Layer to score and sort content
@immutable
class FeedIntelligenceParams {
  /// Base recency weight (0-1)
  final double recencyWeight;
  
  /// Base relevance weight (0-1)
  final double relevanceWeight;
  
  /// Base engagement weight (0-1)
  final double engagementWeight;
  
  /// Creator influence weight (0-1)
  final double creatorWeight;
  
  /// Weight for personalization based on user Trail (0-1)
  final double personalizedWeight;
  
  /// Weight for time-sensitive content (0-1)
  final double timeSensitiveWeight;

  /// Diversity injection percentage (0-1)
  /// Ensures some content outside user's direct network
  final double diversityPercentage;
  
  /// Builder amplification factor
  final double builderAmplificationFactor;
  
  /// Minimum content age in hours to consider "fresh"
  final int freshContentThresholdHours;

  /// Constructor with default values based on optimal system behavior
  const FeedIntelligenceParams({
    this.recencyWeight = 0.4,
    this.relevanceWeight = 0.3,
    this.engagementWeight = 0.2, 
    this.creatorWeight = 0.1,
    this.personalizedWeight = 0.3,
    this.timeSensitiveWeight = 0.2,
    this.diversityPercentage = 0.2,
    this.builderAmplificationFactor = 1.3,
    this.freshContentThresholdHours = 48,
  });

  /// Creates a copy of this configuration with specific values replaced
  FeedIntelligenceParams copyWith({
    double? recencyWeight,
    double? relevanceWeight,
    double? engagementWeight,
    double? creatorWeight,
    double? personalizedWeight,
    double? timeSensitiveWeight,
    double? diversityPercentage,
    double? builderAmplificationFactor,
    int? freshContentThresholdHours,
  }) {
    return FeedIntelligenceParams(
      recencyWeight: recencyWeight ?? this.recencyWeight,
      relevanceWeight: relevanceWeight ?? this.relevanceWeight,
      engagementWeight: engagementWeight ?? this.engagementWeight,
      creatorWeight: creatorWeight ?? this.creatorWeight,
      personalizedWeight: personalizedWeight ?? this.personalizedWeight,
      timeSensitiveWeight: timeSensitiveWeight ?? this.timeSensitiveWeight,
      diversityPercentage: diversityPercentage ?? this.diversityPercentage,
      builderAmplificationFactor: builderAmplificationFactor ?? this.builderAmplificationFactor,
      freshContentThresholdHours: freshContentThresholdHours ?? this.freshContentThresholdHours,
    );
  }

  /// Default configuration optimized for new users with no Trail data
  static FeedIntelligenceParams get newUserConfig => const FeedIntelligenceParams(
    recencyWeight: 0.5,
    relevanceWeight: 0.2,
    engagementWeight: 0.3,
    creatorWeight: 0.0,
    personalizedWeight: 0.1,
    timeSensitiveWeight: 0.3,
    diversityPercentage: 0.4,
    builderAmplificationFactor: 1.1,
    freshContentThresholdHours: 72,
  );

  /// Configuration optimized for Seekers (browsing, low interaction)
  static FeedIntelligenceParams get seekerConfig => const FeedIntelligenceParams(
    recencyWeight: 0.4,
    relevanceWeight: 0.3,
    engagementWeight: 0.2,
    creatorWeight: 0.1,
    personalizedWeight: 0.2,
    timeSensitiveWeight: 0.2,
    diversityPercentage: 0.3,
    builderAmplificationFactor: 1.2,
    freshContentThresholdHours: 60,
  );

  /// Configuration optimized for Builders (content creators)
  static FeedIntelligenceParams get builderConfig => const FeedIntelligenceParams(
    recencyWeight: 0.3,
    relevanceWeight: 0.2,
    engagementWeight: 0.3,
    creatorWeight: 0.2,
    personalizedWeight: 0.4,
    timeSensitiveWeight: 0.2,
    diversityPercentage: 0.1,
    builderAmplificationFactor: 1.5,
    freshContentThresholdHours: 48,
  );

  /// Configuration optimized for campus-wide trending content
  static FeedIntelligenceParams get pulseConfig => const FeedIntelligenceParams(
    recencyWeight: 0.5,
    relevanceWeight: 0.1,
    engagementWeight: 0.4,
    creatorWeight: 0.0,
    personalizedWeight: 0.1,
    timeSensitiveWeight: 0.3,
    diversityPercentage: 0.2,
    builderAmplificationFactor: 1.3,
    freshContentThresholdHours: 24,
  );
}

/// Models the state of user content consumption behavior
/// Used to adapt feed parameters based on user archetype
enum UserArchetype {
  /// New user, low data
  newUser,
  
  /// Browser, exploring content
  seeker,
  
  /// Actively reacts but rarely creates
  reactor,
  
  /// Joins spaces, minimal creation
  joiner,
  
  /// Creates content and spaces
  builder,
  
  /// Started passive, now active
  lurkerTurnedLeader,
  
  /// Observes without much interaction
  skeptic
}

/// Contains scoring data for a feed item
class FeedItemScore {
  /// Unique ID of the content
  final String contentId;
  
  /// Type of content (event, repost, space, etc.)
  final String contentType;
  
  /// Base score from algorithm
  final double baseScore;
  
  /// Adjusted score after personalization
  final double personalizedScore;
  
  /// Final score after all adjustments
  final double finalScore;
  
  /// Whether this item was selected for diversity injection
  final bool isDiversityPick;
  
  /// Whether this item is time-sensitive
  final bool isTimeSensitive;
  
  /// Whether this item is from a builder
  final bool isFromBuilder;
  
  /// Timestamp for when this score was calculated
  final DateTime calculatedAt;

  /// Constructor
  FeedItemScore({
    required this.contentId,
    required this.contentType,
    required this.baseScore,
    required this.personalizedScore,
    required this.finalScore,
    this.isDiversityPick = false,
    this.isTimeSensitive = false,
    this.isFromBuilder = false,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();
} 