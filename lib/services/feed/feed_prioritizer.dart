import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/feed_inspirational_message.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/models/recommended_space.dart';

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

    // First, filter out past events that aren't relevant anymore
    final filteredEvents = events.where((event) {
      // Keep events that are happening today or in the future
      final endTimeHasPassed = event.endDate.isBefore(currentTime);
      
      // Only keep past events if they ended less than 3 hours ago (for immediate follow-up)
      if (endTimeHasPassed) {
        final hoursSinceEnd = currentTime.difference(event.endDate).inHours;
        return hoursSinceEnd < 3;
      }
      
      return true;
    }).toList();

    if (filteredEvents.isEmpty) return [];

    for (final event in filteredEvents) {
      double score = 0;
      final Map<String, double> scoreBreakdown = {};

      // ---- TIME RELEVANCE (0-20 points) - increased priority for upcoming events ----
      final daysUntil = event.startDate.difference(currentTime).inDays;
      final hoursUntil = event.startDate.difference(currentTime).inHours;
      double timeScore = 0;

      // Events happening within the next 3 hours get highest priority
      if (hoursUntil >= 0 && hoursUntil <= 3) {
        timeScore = 20.0;
      }
      // Events happening within the next 6 hours get very high priority
      else if (hoursUntil > 3 && hoursUntil <= 6) {
        timeScore = 18.0;
      }
      // Events today get high priority
      else if (daysUntil == 0) {
        timeScore = 15.0;
      }
      // Events tomorrow get good priority
      else if (daysUntil == 1) {
        timeScore = 12.0;
      }
      // Events in next 3 days get moderate priority
      else if (daysUntil > 1 && daysUntil <= 3) {
        timeScore = 10.0 - ((daysUntil - 1) * 1.0);
      }
      // Events in next 7 days get diminishing scores
      else if (daysUntil > 3 && daysUntil <= 7) {
        timeScore = 8.0 - ((daysUntil - 3) * 1.0);
      }
      // Events beyond 7 days get much lower scores
      else if (daysUntil > 7) {
        timeScore = 3.0 - (daysUntil / 30.0).clamp(0.0, 3.0);
      }
      // Events that just ended (within 3 hours) get minimal scores
      else {
        timeScore = 1.0;
      }

      score += timeScore;
      scoreBreakdown['time'] = timeScore;

      // ---- POPULARITY (0-5 points) ----
      final popularityScore = (event.attendees.length / 10.0).clamp(0.0, 5.0);
      score += popularityScore;
      scoreBreakdown['popularity'] = popularityScore;

      // ---- CATEGORY/INTEREST MATCH (0-8 points) ----
      double interestScore = 0;

      // From historical category interactions
      if (categoryScores != null &&
          categoryScores.containsKey(event.category)) {
        interestScore += categoryScores[event.category]! * 0.5;
      }

      // Explicit user interests
      if (userInterests != null && userInterests.isNotEmpty) {
        // Direct category match
        if (userInterests.any((interest) =>
            interest.toLowerCase() == event.category.toLowerCase())) {
          interestScore += 5.0;
        }

        // Tag matches
        int matchingTags = 0;
        for (final tag in event.tags) {
          if (userInterests
              .any((interest) => interest.toLowerCase() == tag.toLowerCase())) {
            matchingTags++;
          }
        }

        if (matchingTags > 0) {
          interestScore += matchingTags.toDouble().clamp(0.0, 3.0);
        }
      }

      score += interestScore;
      scoreBreakdown['interests'] = interestScore;

      // ---- ORGANIZER/SPACE MATCH (0-6 points) ----
      double organizerScore = 0;

      // From historical organizer interactions
      if (organizerScores != null &&
          organizerScores.containsKey(event.organizerName)) {
        organizerScore += organizerScores[event.organizerName]! * 0.5;
      }

      // User is member of the organizing space
      if (joinedSpaceIds != null && joinedSpaceIds.isNotEmpty) {
        // Check if event is from a space the user has joined
        // We assume event.organizerId or a similar field would match spaceId
        // If not exact match, try to find partial match or use organizer name
        final normalizedOrgName =
            event.organizerName.toLowerCase().replaceAll(' ', '_');
        final isFromJoinedSpace = joinedSpaceIds.any((spaceId) =>
            spaceId.contains(normalizedOrgName) ||
            normalizedOrgName.contains(spaceId.toLowerCase()));

        if (isFromJoinedSpace) {
          organizerScore += 6.0;
        }
      }

      score += organizerScore;
      scoreBreakdown['organizer'] = organizerScore;

      // ---- EDUCATIONAL RELEVANCE (0-4 points) ----
      double educationalScore = 0;

      if (userMajor != null && userMajor.isNotEmpty) {
        // Look for major-related keywords in the event
        final majorKeywords = userMajor.toLowerCase().split(' ');

        bool hasMajorRelevance = false;
        for (final keyword in majorKeywords) {
          if (keyword.length < 3) {
            continue; // Skip short words like "of", "and", etc.
          }

          if (event.title.toLowerCase().contains(keyword) ||
              event.description.toLowerCase().contains(keyword) ||
              event.tags.any((tag) => tag.toLowerCase().contains(keyword))) {
            hasMajorRelevance = true;
            break;
          }
        }

        if (hasMajorRelevance) {
          educationalScore += 2.0;
        }
      }

      // Year relevance (freshman events for freshmen, etc.)
      if (userYear != null && userYear > 0) {
        final yearKeywords = [
          if (userYear == 1) ['freshman', 'first-year', 'new student'],
          if (userYear == 2) ['sophomore', 'second-year'],
          if (userYear == 3) ['junior', 'third-year'],
          if (userYear == 4) ['senior', 'fourth-year', 'graduating'],
          if (userYear >= 5) ['graduate', 'grad student', 'phd', 'masters'],
        ].expand((i) => i).toList();

        bool hasYearRelevance = false;
        for (final keyword in yearKeywords) {
          if (event.title.toLowerCase().contains(keyword) ||
              event.description.toLowerCase().contains(keyword) ||
              event.tags.any((tag) => tag.toLowerCase().contains(keyword))) {
            hasYearRelevance = true;
            break;
          }
        }

        if (hasYearRelevance) {
          educationalScore += 2.0;
        }
      }

      score += educationalScore;
      scoreBreakdown['educational'] = educationalScore;

      // ---- LOCATION RELEVANCE (0-3 points) ----
      double locationScore = 0;

      if (userResidence != null && userResidence.isNotEmpty) {
        final userLocationLower = userResidence.toLowerCase();
        final eventLocationLower = event.location.toLowerCase();

        // Direct location match (same building or nearby)
        if (eventLocationLower.contains(userLocationLower) ||
            userLocationLower.contains(eventLocationLower)) {
          locationScore += 3.0;
        }
        // Same campus area
        else if (_isInSameArea(userLocationLower, eventLocationLower)) {
          locationScore += 1.5;
        }
      }

      score += locationScore;
      scoreBreakdown['location'] = locationScore;

      // ---- SOCIAL FACTORS (0-5 points) ----
      double socialScore = 0;

      // User has RSVPed to this event
      if (rsvpedEventIds != null && rsvpedEventIds.contains(event.id)) {
        socialScore += 5.0; // High priority for events user has RSVPed to
      }

      // Friends attending this event
      if (friendIds != null && friendIds.isNotEmpty) {
        int friendsAttending = 0;

        for (final attendeeId in event.attendees) {
          if (friendIds.contains(attendeeId)) {
            friendsAttending++;
          }
        }

        if (friendsAttending > 0) {
          // Scale social score based on number of friends attending
          socialScore += (friendsAttending * 0.75).toDouble().clamp(0.0, 3.0);
        }
      }

      score += socialScore;
      scoreBreakdown['social'] = socialScore;

      // ---- BOOSTED STATUS (0-3 points) ----
      double boostScore = 0;

      if (boostedEventIds != null && boostedEventIds.contains(event.id)) {
        boostScore += 3.0; // Significant boost for promoted events
      }

      score += boostScore;
      scoreBreakdown['boosted'] = boostScore;

      // Add a small random factor to avoid identical events always showing in same order
      final randomFactor = (event.id.hashCode % 100) / 1000;
      score += randomFactor;

      // Store the scored event with breakdown for debugging
      final scoredEvent = MapEntry(event, score);
      scoredEvents.add(scoredEvent);

      // Uncomment for debugging
      // print('Event: ${event.title} - Score: $score - Breakdown: $scoreBreakdown');
    }

    // Sort by score (descending)
    scoredEvents.sort((a, b) => b.value.compareTo(a.value));

    return scoredEvents.map((e) => e.key).toList();
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

      reposts.add(
        RepostItem(
          event: event,
          comment: comment,
          reposterName: reposterName,
          repostTime: repostTime,
          reposterImageUrl: 'https://picsum.photos/200?random=${i + 100}',
        ),
      );
    }

    return reposts;
  }
}

/// Helper function for min that works with generic types
int min(int a, int b) => a < b ? a : b;

/// Extension for RepostItem to support content interleaving
extension RepostItemExtension on RepostItem {
  bool get isQuote => comment != null && comment!.isNotEmpty;
  
  /// ID of the user who reposted the content
  String get reposterId => reposterName.hashCode.toString(); // Fallback using name hash
  
  /// Whether the repost is public (visible to everyone)
  /// Default is true - override with actual implementation if available
  bool get isPublic => true;
}
