/// Entity for the feed scoring system
class FeedScoringEntity {
  /// Unique identifier for the scoring instance
  final String id;
  
  /// The item being scored (event, space, etc.)
  final String itemId;
  
  /// Type of content being scored
  final FeedContentType contentType;
  
  /// The final calculated score
  final double score;
  
  /// The components that make up the final score
  final ScoringComponents components;
  
  /// When the score was calculated
  final DateTime calculatedAt;
  
  /// Constructor
  const FeedScoringEntity({
    required this.id,
    required this.itemId,
    required this.contentType,
    required this.score,
    required this.components,
    required this.calculatedAt,
  });
  
  /// Create from map data
  factory FeedScoringEntity.fromMap(Map<String, dynamic> map) {
    return FeedScoringEntity(
      id: map['id'] as String,
      itemId: map['itemId'] as String,
      contentType: FeedContentType.values.firstWhere(
        (type) => type.name == map['contentType'],
        orElse: () => FeedContentType.event,
      ),
      score: (map['score'] as num).toDouble(),
      components: ScoringComponents.fromMap(map['components'] as Map<String, dynamic>),
      calculatedAt: DateTime.parse(map['calculatedAt'] as String),
    );
  }
  
  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'contentType': contentType.name,
      'score': score,
      'components': components.toMap(),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

/// The components that contribute to a feed item's score
class ScoringComponents {
  /// Engagement score (RSVPs, reposts, etc.)
  final double engagementScore;
  
  /// Time relevance (recency, proximity to event time)
  final double temporalScore;
  
  /// User relevance (interests, joined spaces)
  final double personalRelevanceScore;
  
  /// Creator/space reputation score
  final double reputationScore;
  
  /// Boost applied manually
  final double boostScore;
  
  /// Content quality and enrichment score
  final double qualityScore;
  
  /// Cold start bonus for new content
  final double coldStartBonus;
  
  /// Fairness adjustment to ensure visibility
  final double fairnessAdjustment;
  
  /// Extra weight from honey mode or admin promotion
  final double promotionWeight;
  
  /// Constructor
  const ScoringComponents({
    required this.engagementScore,
    required this.temporalScore,
    required this.personalRelevanceScore,
    required this.reputationScore,
    required this.boostScore,
    required this.qualityScore,
    required this.coldStartBonus,
    required this.fairnessAdjustment,
    required this.promotionWeight,
  });
  
  /// Create from map data
  factory ScoringComponents.fromMap(Map<String, dynamic> map) {
    return ScoringComponents(
      engagementScore: (map['engagementScore'] as num).toDouble(),
      temporalScore: (map['temporalScore'] as num).toDouble(),
      personalRelevanceScore: (map['personalRelevanceScore'] as num).toDouble(),
      reputationScore: (map['reputationScore'] as num).toDouble(),
      boostScore: (map['boostScore'] as num).toDouble(),
      qualityScore: (map['qualityScore'] as num).toDouble(),
      coldStartBonus: (map['coldStartBonus'] as num).toDouble(),
      fairnessAdjustment: (map['fairnessAdjustment'] as num).toDouble(),
      promotionWeight: (map['promotionWeight'] as num).toDouble(),
    );
  }
  
  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'engagementScore': engagementScore,
      'temporalScore': temporalScore,
      'personalRelevanceScore': personalRelevanceScore,
      'reputationScore': reputationScore,
      'boostScore': boostScore,
      'qualityScore': qualityScore,
      'coldStartBonus': coldStartBonus,
      'fairnessAdjustment': fairnessAdjustment,
      'promotionWeight': promotionWeight,
    };
  }
  
  /// Get a breakdown of score components by percentage
  Map<String, double> getPercentageBreakdown() {
    final total = engagementScore + temporalScore + personalRelevanceScore + 
                 reputationScore + boostScore + qualityScore + 
                 coldStartBonus + fairnessAdjustment + promotionWeight;
    
    if (total <= 0) return {};
    
    return {
      'engagement': (engagementScore / total) * 100,
      'temporal': (temporalScore / total) * 100,
      'personalRelevance': (personalRelevanceScore / total) * 100,
      'reputation': (reputationScore / total) * 100,
      'boost': (boostScore / total) * 100,
      'quality': (qualityScore / total) * 100,
      'coldStart': (coldStartBonus / total) * 100,
      'fairness': (fairnessAdjustment / total) * 100,
      'promotion': (promotionWeight / total) * 100,
    };
  }
}

/// Entity for tracking feed item engagement that contributes to scoring
class FeedItemEngagementEntity {
  /// Unique identifier
  final String id;
  
  /// The item being tracked
  final String itemId;
  
  /// Type of content
  final FeedContentType contentType;
  
  /// RSVP count
  final int rsvpCount;
  
  /// Repost/share count
  final int repostCount;
  
  /// View count
  final int viewCount;
  
  /// Click/tap count
  final int clickCount;
  
  /// Comments or interactions
  final int commentCount;
  
  /// Unique users who interacted
  final int uniqueUserCount;
  
  /// Verified+ users who interacted (weighted higher)
  final int verifiedPlusInteractions;
  
  /// Last updated timestamp
  final DateTime updatedAt;
  
  /// Constructor
  const FeedItemEngagementEntity({
    required this.id,
    required this.itemId,
    required this.contentType,
    required this.rsvpCount,
    required this.repostCount,
    required this.viewCount,
    required this.clickCount,
    required this.commentCount,
    required this.uniqueUserCount,
    required this.verifiedPlusInteractions,
    required this.updatedAt,
  });
  
  /// Calculate total engagement score
  double calculateEngagementScore() {
    // Apply weights according to business rules
    const rsvpWeight = 5.0;
    const repostWeight = 4.0;
    const commentWeight = 3.0;
    const clickWeight = 2.0;
    const viewWeight = 1.0;
    const verifiedPlusMultiplier = 1.5;
    
    final baseScore = 
      (rsvpCount * rsvpWeight) +
      (repostCount * repostWeight) +
      (commentCount * commentWeight) +
      (clickCount * clickWeight) +
      (viewCount * viewWeight);
    
    // Apply verified+ multiplier only to the portion of interactions from verified+ users
    final verifiedPlusRatio = uniqueUserCount > 0 
        ? (verifiedPlusInteractions / uniqueUserCount) 
        : 0.0;
    
    final verifiedPlusBoost = baseScore * verifiedPlusRatio * (verifiedPlusMultiplier - 1.0);
    
    return baseScore + verifiedPlusBoost;
  }
  
  /// Calculate engagement rate (interactions per view)
  double calculateEngagementRate() {
    if (viewCount == 0) return 0.0;
    
    return (rsvpCount + repostCount + commentCount + clickCount) / viewCount.toDouble();
  }
}

/// Types of content in the feed
enum FeedContentType {
  /// Event content
  event,
  
  /// Space recommendation
  spaceRecommendation,
  
  /// Reposted content
  repost,
  
  /// Quote post
  quote,
  
  /// HiveLab content
  hiveLab,
}

/// Feed mode/filter for content display
enum FeedMode {
  /// Personalized feed (default)
  forYou,
  
  /// Trending content
  trending,
  
  /// Nearby/location-based content
  nearby,
  
  /// Recently added content
  recent,
  
  /// Content from followed spaces
  following,
} 