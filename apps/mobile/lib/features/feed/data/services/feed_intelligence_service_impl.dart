import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/feed/domain/models/feed_intelligence_params.dart';
import 'package:hive_ui/features/feed/domain/models/user_trail.dart';
import 'package:hive_ui/features/feed/domain/services/feed_intelligence_service.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';
import 'package:hive_ui/features/feed/domain/failures/feed_failures.dart';

/// Unknown feed failure for generic errors
class FeedFailureUnknown extends FeedFailure {
  /// Constructor
  const FeedFailureUnknown({
    String message = 'An unexpected error occurred',
    Object? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );
}

/// Implementation of the FeedIntelligenceService
class FeedIntelligenceServiceImpl implements FeedIntelligenceService {
  final FirebaseFirestore _firestore;

  /// Constants for content types
  static const String kContentTypeEvent = 'event';
  static const String kContentTypeRepost = 'repost';
  static const String kContentTypeQuote = 'quote';
  static const String kContentTypeSpace = 'space';
  static const String kContentTypeRitual = 'ritual';
  
  /// Constructor
  FeedIntelligenceServiceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  double calculateBaseScore(Map<String, dynamic> content, FeedIntelligenceParams params) {
    double score = 0.0;
    
    // Get content type
    final contentType = content['type'] as String? ?? '';
    
    // 1. Recency factor (logarithmic decay)
    final DateTime createdAt = _getContentTimestamp(content);
    final int ageInHours = DateTime.now().difference(createdAt).inHours;
    final double recencyScore = max(0, 10 - log(ageInHours + 1));
    
    // 2. Relevance factor (if we have space information)
    double relevanceScore = 1.0;
    if (content.containsKey('spaceId')) {
      // Base relevance is neutral
      relevanceScore = 5.0;
    }
    
    // 3. Engagement factor
    final int engagementCount = _getEngagementCount(content);
    final double engagementScore = min(5.0, engagementCount / 10);
    
    // 4. Creator factor (boost content from verified creators/builders)
    double creatorScore = 1.0;
    final bool isCreatorVerifiedPlus = content['isCreatorVerifiedPlus'] as bool? ?? false;
    if (isCreatorVerifiedPlus) {
      creatorScore = 2.0;
    }
    
    // 5. Content type specific boost
    double contentTypeBoost = 1.0;
    switch (contentType) {
      case kContentTypeEvent:
        // Events get a slight boost as they're action-oriented
        contentTypeBoost = 1.2;
        break;
      case kContentTypeRitual:
        // Rituals get a significant boost as they drive participation
        contentTypeBoost = 1.5;
        break;
      default:
        contentTypeBoost = 1.0;
    }
    
    // Calculate final base score using weighted parameters
    score = (recencyScore * params.recencyWeight) +
            (relevanceScore * params.relevanceWeight) +
            (engagementScore * params.engagementWeight) +
            (creatorScore * params.creatorWeight) +
            contentTypeBoost;
    
    return score;
  }

  @override
  double applyPersonalization(double baseScore, Map<String, dynamic> content, UserTrail trail, FeedIntelligenceParams params) {
    double personalizedScore = baseScore;
    final String contentId = content['id'] as String? ?? '';
    final String contentType = content['type'] as String? ?? '';
    final String? spaceId = content['spaceId'] as String?;
    final String creatorId = content['creatorId'] as String? ?? '';
    
    // 1. Space affinity boost
    if (spaceId != null && trail.hasHighEngagementWithSpace(spaceId)) {
      personalizedScore *= 1.3;
    }
    
    // 2. Content type preference
    if (trail.preferredContentTypes.contains(contentType)) {
      personalizedScore *= 1.2;
    }
    
    // 3. Social graph connection
    if (trail.hasInteractedWith(creatorId)) {
      personalizedScore *= 1.25;
    }
    
    // 4. Already viewed this content
    final bool hasViewedContent = trail.content
        .any((activity) => activity.contentId == contentId && activity.viewCount > 0);
    if (hasViewedContent) {
      // Reduce score for already viewed content
      personalizedScore *= 0.7;
    }
    
    // Apply personalization weight
    return baseScore * (1 - params.personalizedWeight) + personalizedScore * params.personalizedWeight;
  }

  @override
  double applyTimeSensitivity(double score, Map<String, dynamic> content, FeedIntelligenceParams params) {
    final String contentType = content['type'] as String? ?? '';
    
    // Event time-sensitivity
    if (contentType == kContentTypeEvent) {
      final DateTime? eventTime = _getEventTime(content);
      if (eventTime != null) {
        final int hoursUntilEvent = eventTime.difference(DateTime.now()).inHours;
        
        // Boost events happening soon (within 48 hours)
        if (hoursUntilEvent > 0 && hoursUntilEvent < 48) {
          double urgencyBoost = 1.0 + (1.0 - hoursUntilEvent / 48) * params.timeSensitiveWeight;
          return score * urgencyBoost;
        }
      }
    }
    
    // Ritual time-sensitivity
    if (contentType == kContentTypeRitual) {
      final bool isActive = content['isActive'] as bool? ?? false;
      if (isActive) {
        return score * (1 + params.timeSensitiveWeight);
      }
    }
    
    return score;
  }

  @override
  UserArchetype determineUserArchetype(UserTrail trail) {
    // Default for brand new users
    if (trail.spaces.isEmpty && trail.events.isEmpty && trail.content.isEmpty) {
      return UserArchetype.newUser;
    }
    
    // Count different behaviors
    final int spaceCreationCount = trail.spaces.where((s) => s.spaceId.startsWith('created_')).length;
    final int eventCreationCount = trail.events.where((e) => e.eventId.startsWith('created_')).length;
    final int totalContentCreated = trail.content.where((c) => c.isCreator).length;
    final int totalReactions = trail.content.where((c) => !c.isCreator && c.hasReposted).length;
    final int totalSpacesJoined = trail.spaces.where((s) => s.isJoined).length;
    final int totalRsvps = trail.events.where((e) => e.hasRsvped).length;
    final int viewOnlyCount = trail.content.where((c) => c.viewCount > 0 && !c.hasReposted && !c.isCreator).length;
    
    // Identify Builder pattern
    if (spaceCreationCount > 0 || eventCreationCount > 2 || totalContentCreated > 5) {
      return UserArchetype.builder;
    }
    
    // Identify Reactor pattern (high reactions, low creation)
    if (totalReactions > 10 && totalContentCreated < 3) {
      return UserArchetype.reactor;
    }
    
    // Identify Joiner pattern (joins spaces, RSVPs)
    if (totalSpacesJoined > 3 || totalRsvps > 5) {
      return UserArchetype.joiner;
    }
    
    // Identify Skeptic pattern (mostly viewing, minimal interaction)
    if (viewOnlyCount > 20 && totalReactions < 3 && totalRsvps < 2) {
      return UserArchetype.skeptic;
    }
    
    // Identify Lurker-turned-Leader (started passive, now more active)
    final bool hasRecentlyIncreased = 
        trail.content.where((c) => c.isCreator && 
            DateTime.now().difference(c.firstActivityAt).inDays < 14).length > 2;
    
    if (hasRecentlyIncreased && viewOnlyCount > 10) {
      return UserArchetype.lurkerTurnedLeader;
    }
    
    // Default to Seeker (browsing behavior)
    return UserArchetype.seeker;
  }

  @override
  FeedIntelligenceParams getConfigForArchetype(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.newUser:
        return FeedIntelligenceParams.newUserConfig;
      case UserArchetype.seeker:
        return FeedIntelligenceParams.seekerConfig;
      case UserArchetype.builder:
        return FeedIntelligenceParams.builderConfig;
      case UserArchetype.reactor:
        // Reactors get a blend of seeker and builder
        return const FeedIntelligenceParams(
          recencyWeight: 0.4,
          relevanceWeight: 0.3,
          engagementWeight: 0.3, 
          creatorWeight: 0.0,
          personalizedWeight: 0.3,
          timeSensitiveWeight: 0.2,
          diversityPercentage: 0.2,
          builderAmplificationFactor: 1.2,
        );
      case UserArchetype.joiner:
        // Joiners care about relevance and time-sensitivity
        return const FeedIntelligenceParams(
          recencyWeight: 0.3,
          relevanceWeight: 0.4,
          engagementWeight: 0.2, 
          creatorWeight: 0.1,
          personalizedWeight: 0.3,
          timeSensitiveWeight: 0.3,
          diversityPercentage: 0.2,
          builderAmplificationFactor: 1.2,
        );
      case UserArchetype.lurkerTurnedLeader:
        // Give them builder-like amplification
        return const FeedIntelligenceParams(
          recencyWeight: 0.3,
          relevanceWeight: 0.3,
          engagementWeight: 0.3, 
          creatorWeight: 0.1,
          personalizedWeight: 0.4,
          timeSensitiveWeight: 0.2,
          diversityPercentage: 0.1,
          builderAmplificationFactor: 1.4,
        );
      case UserArchetype.skeptic:
        // Skeptics get high diversity and engagement weighting
        return const FeedIntelligenceParams(
          recencyWeight: 0.3,
          relevanceWeight: 0.2,
          engagementWeight: 0.4, 
          creatorWeight: 0.1,
          personalizedWeight: 0.2,
          timeSensitiveWeight: 0.2,
          diversityPercentage: 0.4,
          builderAmplificationFactor: 1.0,
        );
      default:
        return const FeedIntelligenceParams();
    }
  }

  @override
  Future<Either<FeedFailure, List<Map<String, dynamic>>>> scoreAndSortFeedItems(
    List<Map<String, dynamic>> items,
    UserTrail trail,
    FeedIntelligenceParams params,
  ) async {
    try {
      final List<Map<String, dynamic>> scoredItems = [];
      
      // Score each item
      for (final item in items) {
        // Calculate all scores
        final double baseScore = calculateBaseScore(item, params);
        final double personalizedScore = applyPersonalization(baseScore, item, trail, params);
        final double finalScore = applyTimeSensitivity(personalizedScore, item, params);
        
        // Add score data to item
        final Map<String, dynamic> scoredItem = Map<String, dynamic>.from(item);
        scoredItem['baseScore'] = baseScore;
        scoredItem['personalizedScore'] = personalizedScore;
        scoredItem['finalScore'] = finalScore;
        
        // Add additional flag for builder content
        final bool isFromBuilder = item['isCreatorVerifiedPlus'] as bool? ?? false;
        scoredItem['isFromBuilder'] = isFromBuilder;
        
        // Add time-sensitive flag
        bool isTimeSensitive = false;
        if (item['type'] == kContentTypeEvent) {
          final DateTime? eventTime = _getEventTime(item);
          if (eventTime != null) {
            final int hoursUntilEvent = eventTime.difference(DateTime.now()).inHours;
            isTimeSensitive = hoursUntilEvent > 0 && hoursUntilEvent < 48;
          }
        } else if (item['type'] == kContentTypeRitual) {
          isTimeSensitive = item['isActive'] as bool? ?? false;
        }
        scoredItem['isTimeSensitive'] = isTimeSensitive;
        
        scoredItems.add(scoredItem);
      }
      
      // Sort by final score (descending)
      scoredItems.sort((a, b) {
        final double scoreA = a['finalScore'] as double? ?? 0.0;
        final double scoreB = b['finalScore'] as double? ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      return Either.right(scoredItems);
    } catch (e) {
      debugPrint('Error scoring feed items: $e');
      return Either.left(FeedFailureUnknown(message: 'Failed to score feed items: $e'));
    }
  }

  @override
  Future<Either<FeedFailure, List<Map<String, dynamic>>>> applyDiversityInjection(
    List<Map<String, dynamic>> items,
    UserTrail trail,
    FeedIntelligenceParams params,
  ) async {
    try {
      if (items.isEmpty) {
        return Either.right(items);
      }
      
      // Get the joined space IDs from the trail
      final joinedSpaceIds = trail.spaces
          .where((space) => space.isJoined)
          .map((space) => space.spaceId)
          .toList();
      
      // Separate into "network" and "diverse" content
      final networkItems = <Map<String, dynamic>>[];
      final diverseItems = <Map<String, dynamic>>[];
      
      for (final item in items) {
        final String? spaceId = item['spaceId'] as String?;
        
        // If content is from a joined space, it's network content
        // Otherwise, it's diversity content
        if (spaceId != null && joinedSpaceIds.contains(spaceId)) {
          networkItems.add(item);
        } else {
          diverseItems.add(item);
        }
      }
      
      if (diverseItems.isEmpty) {
        return Either.right(items); // No diversity items available
      }
      
      // Calculate how many diversity items we need
      final int totalItems = items.length;
      final int diversityCount = (totalItems * params.diversityPercentage).round();
      
      // If we need more diversity items than available, use all we have
      final int actualDiversityCount = min(diversityCount, diverseItems.length);
      
      if (actualDiversityCount == 0) {
        return Either.right(items); // No diversity needed or available
      }
      
      // Select top diverse items
      final selectedDiverseItems = diverseItems.take(actualDiversityCount).toList();
      
      // Mark them as diversity picks
      for (final item in selectedDiverseItems) {
        item['isDiversityPick'] = true;
      }
      
      // Take the top network items to fill remaining slots
      final int networkItemsNeeded = totalItems - actualDiversityCount;
      final selectedNetworkItems = networkItems.take(networkItemsNeeded).toList();
      
      // Combine and re-sort by score
      final result = [...selectedNetworkItems, ...selectedDiverseItems];
      result.sort((a, b) {
        final double scoreA = a['finalScore'] as double? ?? 0.0;
        final double scoreB = b['finalScore'] as double? ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      return Either.right(result);
    } catch (e) {
      debugPrint('Error applying diversity injection: $e');
      return Either.left(FeedFailureUnknown(message: 'Failed to apply diversity injection: $e'));
    }
  }

  @override
  Future<Either<FeedFailure, FeedIntelligenceParams>> getIntelligenceParams(
    String userId, 
    UserTrail? trail,
  ) async {
    try {
      // If we have trail data, determine archetype and return appropriate params
      if (trail != null) {
        final archetype = determineUserArchetype(trail);
        return Either.right(getConfigForArchetype(archetype));
      }
      
      // Otherwise, try to get trail data from Firestore
      try {
        final trailData = await _firestore
            .collection('user_trails')
            .doc(userId)
            .get();
            
        if (trailData.exists) {
          // In a real implementation, we would parse the trail data
          // For now, we'll use newUserConfig as fallback
          return Either.right(FeedIntelligenceParams.newUserConfig);
        } else {
          // No trail data found, use default new user config
          return Either.right(FeedIntelligenceParams.newUserConfig);
        }
      } catch (e) {
        // Error accessing Firestore, use default
        debugPrint('Error accessing user trail: $e');
        return Either.right(const FeedIntelligenceParams());
      }
    } catch (e) {
      debugPrint('Error getting intelligence params: $e');
      return Either.left(FeedFailureUnknown(message: 'Failed to get intelligence parameters: $e'));
    }
  }

  @override
  Future<Either<FeedFailure, UserTrail>> getUserTrail(String userId) async {
    try {
      final trailData = await _firestore
          .collection('user_trails')
          .doc(userId)
          .get();
          
      if (trailData.exists) {
        // In a real implementation, parse the trail data from Firestore
        // For now, return an empty trail
        return Either.right(UserTrail.empty());
      } else {
        // No trail found, create empty one
        return Either.right(UserTrail.empty());
      }
    } catch (e) {
      debugPrint('Error getting user trail: $e');
      return Either.left(FeedFailureUnknown(message: 'Failed to get user trail: $e'));
    }
  }

  @override
  Future<Either<FeedFailure, List<Map<String, dynamic>>>> applyFeedIntelligence(
    List<Map<String, dynamic>> feedItems,
    String userId,
  ) async {
    try {
      // 1. Get user trail
      final trailResult = await getUserTrail(userId);
      if (trailResult.isLeft) {
        return Either.left(
          const FeedFailureUnknown(message: 'Failed to get user trail')
        );
      }
      
      // Use guard clause to avoid explicit isRight check
      final UserTrail trail = trailResult.isRight ? trailResult.right : UserTrail.empty();
      
      // 2. Get intelligence parameters based on user archetype
      final paramsResult = await getIntelligenceParams(userId, trail);
      if (paramsResult.isLeft) {
        return Either.left(
          const FeedFailureUnknown(message: 'Failed to get intelligence parameters')
        );
      }
      
      // Use guard clause to avoid explicit isRight check
      final params = paramsResult.isRight ? paramsResult.right : const FeedIntelligenceParams();
      
      // 3. Score and sort items
      final scoredResult = await scoreAndSortFeedItems(feedItems, trail, params);
      if (scoredResult.isLeft) {
        return Either.left(
          const FeedFailureUnknown(message: 'Failed to score feed items')
        );
      }
      
      // Use guard clause to avoid explicit isRight check
      final scoredItems = scoredResult.isRight ? scoredResult.right : <Map<String, dynamic>>[];
      
      // 4. Apply diversity injection
      final diverseResult = await applyDiversityInjection(scoredItems, trail, params);
      if (diverseResult.isLeft) {
        return Either.left(
          const FeedFailureUnknown(message: 'Failed to apply diversity injection')
        );
      }
      
      return diverseResult;
    } catch (e) {
      debugPrint('Error applying feed intelligence: $e');
      return Either.left(FeedFailureUnknown(message: 'Failed to apply feed intelligence: $e'));
    }
  }

  // Helper methods
  
  /// Get timestamp from content item
  DateTime _getContentTimestamp(Map<String, dynamic> content) {
    // Try to get timestamp from content
    if (content.containsKey('createdAt')) {
      final dynamic timestamp = content['createdAt'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      } else if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          // Invalid string format
        }
      }
    }
    
    // Fallback
    return DateTime.now();
  }
  
  /// Get engagement count from content
  int _getEngagementCount(Map<String, dynamic> content) {
    int count = 0;
    
    // Sum different engagement types
    count += content['rsvpCount'] as int? ?? 0;
    count += content['repostCount'] as int? ?? 0;
    count += content['quoteCount'] as int? ?? 0;
    count += content['viewCount'] as int? ?? 0;
    count += content['likeCount'] as int? ?? 0;
    
    return count;
  }
  
  /// Get event time from event content
  DateTime? _getEventTime(Map<String, dynamic> content) {
    if (content.containsKey('eventTime') || content.containsKey('startTime')) {
      final dynamic timestamp = content['eventTime'] ?? content['startTime'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      } else if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          // Invalid string format
        }
      }
    }
    
    return null;
  }
} 