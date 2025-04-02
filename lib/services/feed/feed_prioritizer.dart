import 'dart:math';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/feed_inspirational_message.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/models/repost_content_type.dart';

/// Service for prioritizing and distributing feed items
class FeedPrioritizer {
  /// Distribute feed items for optimal engagement
  ///
  /// This method takes all available content and mixes it to create
  /// an engaging feed with a variety of content types
  static List<dynamic> distributeFeedItems({
    required List<Event> events,
    List<RepostItem> reposts = const [],
    List<SpaceRecommendation> spaceRecommendations = const [],
    List<HiveLabItem> hiveLabItems = const [],
    List<InspirationalMessage> inspirationalMessages = const [],
  }) {
    if (events.isEmpty &&
        reposts.isEmpty &&
        spaceRecommendations.isEmpty &&
        hiveLabItems.isEmpty &&
        inspirationalMessages.isEmpty) {
      return [];
    }

    final List<dynamic> distributedItems = [];

    // Add a HiveLab item at the top if available
    if (hiveLabItems.isNotEmpty) {
      distributedItems.add(hiveLabItems.first);
    }

    // Add first inspirational message near the top
    if (inspirationalMessages.isNotEmpty) {
      distributedItems.add(inspirationalMessages.first);
    }

    // Add first few events (1-3)
    final firstEventsBatch = events.take(3).toList();
    distributedItems.addAll(firstEventsBatch);

    // Add first space recommendation
    if (spaceRecommendations.isNotEmpty) {
      distributedItems.add(spaceRecommendations.first);
    }

    // Add some reposts if available
    if (reposts.isNotEmpty) {
      final repostBatch = reposts.take(reposts.length > 3 ? 2 : 1).toList();
      distributedItems.addAll(repostBatch);
    }

    // Add more events
    if (events.length > 3) {
      final secondEventsBatch = events.skip(3).take(3).toList();
      distributedItems.addAll(secondEventsBatch);
    }

    // Add another inspirational message if available
    if (inspirationalMessages.length > 1) {
      distributedItems.add(inspirationalMessages[1]);
    }

    // Add more space recommendations
    if (spaceRecommendations.length > 1) {
      distributedItems.addAll(spaceRecommendations.skip(1).take(1));
    }

    // Add more reposts
    if (reposts.length > 2) {
      distributedItems.addAll(reposts.skip(2).take(2));
    }

    // Add remaining events in batches, interspersed with other content
    if (events.length > 6) {
      int remainingEventsCount = events.length - 6;
      int currentIndex = 6;

      // Distribute remaining events in batches of 4
      while (currentIndex < events.length) {
        final batchSize = remainingEventsCount > 4 ? 4 : remainingEventsCount;
        final batch = events.skip(currentIndex).take(batchSize).toList();
        distributedItems.addAll(batch);
        currentIndex += batchSize;
        remainingEventsCount -= batchSize;

        // Add an inspirational message every 8 items if available
        if (currentIndex < events.length &&
            inspirationalMessages.length > distributedItems.length ~/ 8 + 2) {
          distributedItems
              .add(inspirationalMessages[distributedItems.length ~/ 8 + 2]);
        }

        // Add remaining reposts
        if (reposts.length > 4 && currentIndex < events.length) {
          final repostsToAdd = reposts.skip(4).take(1).toList();
          if (repostsToAdd.isNotEmpty) {
            distributedItems.addAll(repostsToAdd);
          }
        }

        // Add remaining space recommendations
        if (spaceRecommendations.length > 2 && currentIndex < events.length) {
          final spacesToAdd = spaceRecommendations.skip(2).take(1).toList();
          if (spacesToAdd.isNotEmpty) {
            distributedItems.addAll(spacesToAdd);
          }
        }
      }
    }

    // Add remaining HiveLab items at the end
    if (hiveLabItems.length > 1) {
      distributedItems.addAll(hiveLabItems.skip(1));
    }

    return distributedItems;
  }

  /// Advanced interleaving of content types optimized for student engagement
  /// 
  /// This improved algorithm focuses on prioritizing events while intelligently
  /// mixing in friend suggestions and space recommendations based on specific rules
  static List<dynamic> interleaveFeedContent({
    required List<Event> events,
    required List<SuggestedFriend> friendSuggestions,
    required List<RecommendedSpace> spaceRecommendations,
    required List<RepostItem> reposts,
    Map<String, dynamic>? userProfile,
    List<String>? friendIds,
  }) {
    // Initialize the final feed items list
    final List<dynamic> feedItems = [];
    
    // Early return if all content types are empty
    if (events.isEmpty && 
        friendSuggestions.isEmpty && 
        spaceRecommendations.isEmpty && 
        reposts.isEmpty) {
      return feedItems;
    }
    
    // Step 1: First process and separate reposts by type
    final friendReposts = <RepostItem>[];
    final publicReposts = <RepostItem>[];
    
    for (final repost in reposts) {
      if (repost.isQuote || repost.isPublic) {
        publicReposts.add(repost);
      } else if (friendIds != null && friendIds.contains(repost.reposterId)) {
        friendReposts.add(repost);
      }
    }
    
    // Step 2: Get prioritized versions of each content type
    final prioritizedEvents = List<Event>.from(events);
    final prioritizedFriendSuggestions = _prioritizeFriendSuggestions(
      friendSuggestions, 
      userProfile
    );
    final prioritizedSpaces = _prioritizeSpaceRecommendations(
      spaceRecommendations,
      userProfile
    );
    
    // Step 3: Begin adding to feed with a heavy focus on events at the top
    
    // Start with 2-3 top events
    final topEventCount = prioritizedEvents.length >= 3 ? 3 : prioritizedEvents.length;
    if (topEventCount > 0) {
      feedItems.addAll(prioritizedEvents.take(topEventCount));
    }
    
    // Add a friend suggestion near the top if available
    if (prioritizedFriendSuggestions.isNotEmpty) {
      feedItems.add(prioritizedFriendSuggestions.first);
    }
    
    // Add more events (next 2-3)
    if (prioritizedEvents.length > topEventCount) {
      final nextEventCount = prioritizedEvents.length >= topEventCount + 3 
          ? 3 
          : prioritizedEvents.length - topEventCount;
      
      feedItems.addAll(prioritizedEvents.skip(topEventCount).take(nextEventCount));
    }
    
    // Add a space recommendation
    if (prioritizedSpaces.isNotEmpty) {
      feedItems.add(prioritizedSpaces.first);
    }
    
    // Add some public reposts if available
    if (publicReposts.isNotEmpty) {
      feedItems.addAll(publicReposts.take(publicReposts.length > 2 ? 2 : publicReposts.length));
    }
    
    // Continue with more events
    final eventsAdded = topEventCount + (prioritizedEvents.length > topEventCount ? 
        (prioritizedEvents.length >= topEventCount + 3 ? 3 : prioritizedEvents.length - topEventCount) : 0);
    
    if (prioritizedEvents.length > eventsAdded) {
      final midEventCount = prioritizedEvents.length >= eventsAdded + 4 
          ? 4 
          : prioritizedEvents.length - eventsAdded;
      
      feedItems.addAll(prioritizedEvents.skip(eventsAdded).take(midEventCount));
    }
    
    // Add friend reposts for personalization
    if (friendReposts.isNotEmpty) {
      feedItems.addAll(friendReposts.take(friendReposts.length > 2 ? 2 : friendReposts.length));
    }
    
    // Add another friend suggestion if available
    if (prioritizedFriendSuggestions.length > 1) {
      feedItems.add(prioritizedFriendSuggestions[1]);
    }
    
    // Add another space recommendation if available
    if (prioritizedSpaces.length > 1) {
      feedItems.add(prioritizedSpaces[1]);
    }
    
    // Continue with remaining events in batches of 4-5
    int currentEventIndex = eventsAdded + (prioritizedEvents.length > eventsAdded ?
        (prioritizedEvents.length >= eventsAdded + 4 ? 4 : prioritizedEvents.length - eventsAdded) : 0);
    
    // Now interleave the remaining content
    while (currentEventIndex < prioritizedEvents.length) {
      // Add events batch
      final eventBatchSize = min(5, prioritizedEvents.length - currentEventIndex);
      feedItems.addAll(prioritizedEvents.skip(currentEventIndex).take(eventBatchSize));
      currentEventIndex += eventBatchSize;
      
      // Add remaining friend suggestions (1 at a time)
      final friendSuggestionIndex = feedItems.whereType<SuggestedFriend>().length;
      if (friendSuggestionIndex < prioritizedFriendSuggestions.length) {
        feedItems.add(prioritizedFriendSuggestions[friendSuggestionIndex]);
      }
      
      // Add remaining space recommendations (1 at a time)
      final spaceRecommendationIndex = feedItems.whereType<RecommendedSpace>().length;
      if (spaceRecommendationIndex < prioritizedSpaces.length) {
        feedItems.add(prioritizedSpaces[spaceRecommendationIndex]);
      }
      
      // Add remaining reposts (public then friends) alternating between them
      final publicRepostIndex = feedItems.where(
        (item) => item is RepostItem && (item.isQuote || item.isPublic)
      ).length;
      
      final friendRepostIndex = feedItems.where(
        (item) => item is RepostItem && !(item.isQuote || item.isPublic)
      ).length;
      
      if (publicRepostIndex < publicReposts.length) {
        feedItems.add(publicReposts[publicRepostIndex]);
      } else if (friendRepostIndex < friendReposts.length) {
        feedItems.add(friendReposts[friendRepostIndex]);
      }
    }
    
    // Add any remaining content in a balanced way
    _addRemainingContent(
      feedItems,
      prioritizedFriendSuggestions,
      prioritizedSpaces,
      publicReposts,
      friendReposts
    );
    
    return feedItems;
  }
  
  /// Prioritize friend suggestions based on matching criteria
  ///
  /// Places higher priority on matches by major, year, and residence
  static List<SuggestedFriend> _prioritizeFriendSuggestions(
    List<SuggestedFriend> suggestions,
    Map<String, dynamic>? userProfile,
  ) {
    if (suggestions.isEmpty) return [];
    
    final List<MapEntry<SuggestedFriend, int>> scoredSuggestions = [];
    
    for (final suggestion in suggestions) {
      int score = 0;
      
      // Give higher priority to suggestions based on major, year, and residence
      if (suggestion.matchCriteria == MatchCriteria.major) {
        score += 5;
      } else if (suggestion.matchCriteria == MatchCriteria.residence) {
        score += 4;
      } else if (suggestion.matchCriteria == MatchCriteria.interest) {
        score += 3;
      }
      
      // Add extra points if the user is in same year (derived from status)
      if (userProfile != null && 
          userProfile.containsKey('year') && 
          suggestion.status.toLowerCase().contains(userProfile['year'].toString().toLowerCase())) {
        score += 3;
      }
      
      // Add random factor to avoid identical ordering
      score += suggestion.id.hashCode % 3;
      
      scoredSuggestions.add(MapEntry(suggestion, score));
    }
    
    // Sort by score (descending)
    scoredSuggestions.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredSuggestions.map((entry) => entry.key).toList();
  }
  
  /// Prioritize space recommendations
  static List<RecommendedSpace> _prioritizeSpaceRecommendations(
    List<RecommendedSpace> spaces,
    Map<String, dynamic>? userProfile,
  ) {
    if (spaces.isEmpty) return [];
    
    final List<MapEntry<RecommendedSpace, int>> scoredSpaces = [];
    
    for (final space in spaces) {
      int score = 0;
      
      // Check if space tags match user interests
      if (userProfile != null && 
          userProfile.containsKey('interests') && 
          userProfile['interests'] is List<String>) {
        
        final userInterests = userProfile['interests'] as List<String>;
        int matchingTagCount = 0;
        
        for (final tag in space.space.tags) {
          // Note: Interests might not directly match - need to check for partial matches
          for (final interest in userInterests) {
            if (tag.toLowerCase().contains(interest.toLowerCase()) || 
                interest.toLowerCase().contains(tag.toLowerCase())) {
              matchingTagCount++;
              break;
            }
          }
        }
        
        score += matchingTagCount * 2;
      }
      
      // Add points for metrics
      score += space.space.metrics.memberCount ~/ 10;
      
      // Add random factor
      score += space.space.id.hashCode % 3;
      
      scoredSpaces.add(MapEntry(space, score));
    }
    
    // Sort by score (descending)
    scoredSpaces.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredSpaces.map((entry) => entry.key).toList();
  }
  
  /// Add remaining content to the feed in a balanced manner
  static void _addRemainingContent(
    List<dynamic> feedItems,
    List<SuggestedFriend> friendSuggestions,
    List<RecommendedSpace> spaces,
    List<RepostItem> publicReposts,
    List<RepostItem> friendReposts,
  ) {
    // Count how many of each type are already in the feed
    final friendCount = feedItems.whereType<SuggestedFriend>().length;
    final spaceCount = feedItems.whereType<RecommendedSpace>().length;
    final publicRepostCount = feedItems.where(
      (item) => item is RepostItem && (item.isQuote || item.isPublic)
    ).length;
    final friendRepostCount = feedItems.where(
      (item) => item is RepostItem && !(item.isQuote || item.isPublic)
    ).length;
    
    // Add remaining friend suggestions
    if (friendCount < friendSuggestions.length) {
      feedItems.addAll(friendSuggestions.skip(friendCount));
    }
    
    // Add remaining space recommendations
    if (spaceCount < spaces.length) {
      feedItems.addAll(spaces.skip(spaceCount));
    }
    
    // Add remaining reposts (public then friends)
    if (publicRepostCount < publicReposts.length) {
      feedItems.addAll(publicReposts.skip(publicRepostCount));
    }
    
    if (friendRepostCount < friendReposts.length) {
      feedItems.addAll(friendReposts.skip(friendRepostCount));
    }
  }

  /// Score events based on relevance and recency with enhanced personalization
  ///
  /// This method calculates a relevance score for each event based on multiple factors:
  /// - Time relevance (events happening soon score higher)
  /// - Popularity (attendance count)
  /// - User interests
  /// - Joined spaces matching the event organizer
  /// - Educational relevance (matching major/year)
  /// - Location relevance (residential proximity)
  /// - Social factors (friends attending)
  /// - Boosted status
  static List<Event> prioritizeEvents(
    List<Event> events, {
    Map<String, int>? categoryScores,
    Map<String, int>? organizerScores,
    DateTime? now,

    // New personalization factors
    List<String>? userInterests,
    List<String>? joinedSpaceIds,
    String? userMajor,
    int? userYear,
    String? userResidence,
    List<String>? rsvpedEventIds,
    List<String>? friendIds,
    List<String>? boostedEventIds,
  }) {
    if (events.isEmpty) return [];

    final currentTime = now ?? DateTime.now();
    final scoredEvents = <MapEntry<Event, double>>[];

    // First, strictly filter out all past events
    final filteredEvents = events.where((event) {
      // Only keep events that haven't ended yet
      return event.endDate.isAfter(currentTime);
    }).toList();

    if (filteredEvents.isEmpty) return [];

    // Score each event based on various factors to generate a personalized order
    for (final event in filteredEvents) {
      double score = 0;
      
      // TIME RELEVANCE SCORE (0-10 points) - Highest priority factor
      // Events happening very soon get highest priority
      final daysUntilStart = event.startDate.difference(currentTime).inHours / 24;
      
      if (daysUntilStart < 0) {
        // Event has started but not ended
        // Events currently happening get highest priority
        score += 10;
      } else if (daysUntilStart < 1) {
        // Event is today (less than 24 hours away)
        score += 9;
      } else if (daysUntilStart < 2) {
        // Event is tomorrow
        score += 8;
      } else if (daysUntilStart < 3) {
        // Event is in 2 days
        score += 7;
      } else if (daysUntilStart < 5) {
        // Event is in 3-4 days
        score += 6;
      } else if (daysUntilStart < 7) {
        // Event is in 5-6 days
        score += 5;
      } else if (daysUntilStart < 14) {
        // Event is in the next week
        score += 4;
      } else if (daysUntilStart < 21) {
        // Event is in the next 2 weeks
        score += 3;
      } else if (daysUntilStart < 30) {
        // Event is in the next month
        score += 2;
      } else {
        // Event is more than a month away
        score += 1;
      }

      // POPULARITY SCORE (0-5 points)
      final attendeeCount = event.attendees.length;
      if (attendeeCount > 100) {
        score += 5;
      } else if (attendeeCount > 50) {
        score += 4;
      } else if (attendeeCount > 20) {
        score += 3;
      } else if (attendeeCount > 10) {
        score += 2;
      } else if (attendeeCount > 0) {
        score += 1;
      }

      // INTEREST MATCH SCORE (0-8 points)
      if (userInterests != null && userInterests.isNotEmpty) {
        // Category match (0-5 points)
        if (userInterests.any((interest) => 
            interest.toLowerCase() == event.category.toLowerCase())) {
          score += 5;
        }
        
        // Tag match (0-3 points)
        int tagMatchCount = 0;
        for (final tag in event.tags) {
          if (userInterests.any((interest) => 
              interest.toLowerCase() == tag.toLowerCase() ||
              tag.toLowerCase().contains(interest.toLowerCase()))) {
            tagMatchCount++;
          }
        }
        
        score += min(3, tagMatchCount);
      }
      
      // Historical category preference
      if (categoryScores != null && categoryScores.containsKey(event.category)) {
        final catScore = categoryScores[event.category] ?? 0;
        score += min(3, catScore / 2); // Max 3 points from category history
      }
      
      // ORGANIZER/SPACE MATCH SCORE (0-6 points)
      if (joinedSpaceIds != null && joinedSpaceIds.isNotEmpty) {
        // Check if event is from a space the user has joined
        if (joinedSpaceIds.contains(event.organizerName)) {
          score += 6;
        }
      }
      
      // Historical organizer preference
      if (organizerScores != null && organizerScores.containsKey(event.organizerName)) {
        final orgScore = organizerScores[event.organizerName] ?? 0;
        score += min(4, orgScore / 2); // Max 4 points from organizer history
      }
      
      // EDUCATIONAL RELEVANCE SCORE (0-4 points)
      if (userMajor != null && userMajor.isNotEmpty && 
          (event.description.toLowerCase().contains(userMajor.toLowerCase()) ||
           event.tags.any((tag) => tag.toLowerCase().contains(userMajor.toLowerCase())))) {
        score += 2; // Event is relevant to user's field of study
      }
      
      if (userYear != null && 
          (event.description.toLowerCase().contains('year $userYear') ||
           event.description.toLowerCase().contains('${_getYearString(userYear)}') ||
           event.title.toLowerCase().contains('year $userYear') ||
           event.title.toLowerCase().contains('${_getYearString(userYear)}'))) {
        score += 2; // Event is targeted at user's academic year
      }
      
      // LOCATION RELEVANCE SCORE (0-3 points)
      if (userResidence != null && userResidence.isNotEmpty &&
          event.location.toLowerCase().contains(userResidence.toLowerCase())) {
        score += 3; // Event is in user's building/area
      }
      
      // SOCIAL FACTORS SCORE (0-5 points)
      if (rsvpedEventIds != null && rsvpedEventIds.contains(event.id)) {
        score += 5; // User has RSVPed to this event
      }
      
      // Friends attending
      if (friendIds != null && friendIds.isNotEmpty) {
        int friendsAttending = 0;
        for (final attendee in event.attendees) {
          if (friendIds.contains(attendee)) {
            friendsAttending++;
          }
        }
        
        // 0-3 points based on number of friends attending
        score += min(3, friendsAttending);
      }
      
      // BOOSTED STATUS SCORE (0-3 points)
      if (boostedEventIds != null && boostedEventIds.contains(event.id)) {
        score += 3; // Event is officially promoted
      }
      
      scoredEvents.add(MapEntry(event, score));
    }
    
    // Sort by score (highest to lowest)
    scoredEvents.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      
      // If scores are equal, sort by start date (soonest first)
      return a.key.startDate.compareTo(b.key.startDate);
    });
    
    return scoredEvents.map((entry) => entry.key).toList();
  }

  /// Helper method to determine if two locations are in the same area
  static bool _isInSameArea(String location1, String location2) {
    // Define areas/zones of campus (this would be customized for your specific campus)
    final areas = {
      'north': [
        'north campus',
        'ellicott',
        'greiner',
        'red jacket',
        'richmond',
        'spaulding'
      ],
      'south': ['south campus', 'main street', 'goodyear', 'clement'],
      'central': [
        'student union',
        'capen',
        'norton',
        'talbert',
        'knox',
        'commons'
      ],
      'downtown': ['downtown', 'medical campus', 'jacobs'],
    };

    String area1 = 'unknown';
    String area2 = 'unknown';

    // Determine area of location1
    for (final entry in areas.entries) {
      if (entry.value.any((keyword) => location1.contains(keyword))) {
        area1 = entry.key;
        break;
      }
    }

    // Determine area of location2
    for (final entry in areas.entries) {
      if (entry.value.any((keyword) => location2.contains(keyword))) {
        area2 = entry.key;
        break;
      }
    }

    return area1 == area2 && area1 != 'unknown';
  }

  /// Generate personalized reposts based on user interests and event popularity
  static List<RepostItem> generateReposts(
      List<Event> events, List<String> reposterNames, List<String> comments) {
    if (events.isEmpty || reposterNames.isEmpty || comments.isEmpty) {
      return [];
    }

    final reposts = <RepostItem>[];
    final now = DateTime.now();

    // Prioritize events to repost - choose best events based on popularity
    final eventsToRepost = List<Event>.from(events)
      ..sort((a, b) => b.attendees.length.compareTo(a.attendees.length));

    // Get top 20% of events
    final topEventCount = (eventsToRepost.length * 0.2).ceil();
    final topEvents = eventsToRepost.take(topEventCount).toList();

    // Create reposts for top events
    for (int i = 0; i < topEvents.length; i++) {
      if (i >= reposterNames.length || i >= comments.length) break;

      final event = topEvents[i];
      final reposterName = reposterNames[i % reposterNames.length];
      final comment = comments[i % comments.length];

      // Repost time between 1-4 days ago
      final daysAgo = (i % 4) + 1;
      final hoursAgo = (i * 3) % 24;
      final minutesAgo = (i * 7) % 60;

      final repostTime = now.subtract(
        Duration(
          days: daysAgo,
          hours: hoursAgo,
          minutes: minutesAgo,
        ),
      );

      // Create a mock user profile for the reposter
      final mockProfile = UserProfile(
        id: 'user_${i + 1}',
        displayName: reposterName,
        username: 'user_${i + 1}',
        email: 'user${i + 1}@example.com',
        year: '',
        major: '',
        residence: '',
        eventCount: 0,
        clubCount: 0,
        friendCount: 0,
        profileImageUrl: null,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      );

      reposts.add(
        RepostItem(
          event: event,
          reposterProfile: mockProfile,
          comment: comment,
          repostTime: repostTime,
          contentType: comment.isNotEmpty ? RepostContentType.quote : RepostContentType.standard,
        ),
      );
    }

    return reposts;
  }

  /// Helper method to convert numeric year to string representation
  static String _getYearString(int year) {
    switch (year) {
      case 1:
        return 'freshman';
      case 2:
        return 'sophomore';
      case 3:
        return 'junior';
      case 4:
        return 'senior';
      default:
        return 'graduate';
    }
  }
}

/// Extension for RepostItem to support content interleaving
extension RepostItemExtension on RepostItem {
  bool get isQuote => comment != null && comment!.isNotEmpty;
  
  /// ID of the user who reposted the content
  String get reposterId => reposterProfile.id;
  
  /// Whether the repost is public (visible to everyone)
  /// Default is true - override with actual implementation if available
  bool get isPublic => true;
}
