import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/event.dart';

/// A class representing a segment of events with metadata
class EventSegment {
  final String title;
  final String description;
  final IconData icon;
  final List<Event> events;
  final bool isBundled;
  final double? interestScore; // Added interest score for personalization

  const EventSegment({
    required this.title,
    required this.description,
    required this.icon,
    required this.events,
    this.isBundled = false,
    this.interestScore,
  });
}

/// Service class for segmenting events based on various criteria
class EventSegmentationService {
  /// Segment events into meaningful groups
  /// - isClubMember: Whether the current user is a member of the club
  /// - userInterests: Optional list of user interests for personalization
  /// - pastAttendance: Optional map of past attendance counts for each organizer
  /// - enableTopicCategorization: Whether to enable topic-based categorization
  /// - enableLocationGrouping: Whether to enable location-based grouping
  static List<EventSegment> segmentEvents(
    List<Event> events, {
    bool isClubMember = false,
    List<String>? userInterests,
    Map<String, int>? pastAttendance,
    bool enableTopicCategorization = true,
    bool enableLocationGrouping = true,
  }) {
    if (events.isEmpty) {
      return [];
    }

    final List<EventSegment> segments = [];
    final Set<String> processedEventIds = {};
    final now = DateTime.now();

    // Weekly meetings (only shown to members)
    if (isClubMember) {
      final weeklyEvents = _identifyWeeklyMeetings(events);
      if (weeklyEvents.isNotEmpty) {
        processedEventIds.addAll(weeklyEvents.map((e) => e.id));

        // Calculate interest score if user interests are provided
        double? interestScore;
        if (userInterests != null && userInterests.isNotEmpty) {
          interestScore =
              _calculateAverageInterestScore(weeklyEvents, userInterests);
        }

        segments.add(EventSegment(
          title: 'Weekly Meetings',
          description: 'Regular club meetings',
          icon: Icons.calendar_view_week,
          events: weeklyEvents,
          isBundled: true,
          interestScore: interestScore,
        ));
      }
    }

    // Handle upcoming events (next 7 days)
    final upcomingEvents = events
        .where((e) => !processedEventIds.contains(e.id))
        .where((e) => e.startDate.difference(now).inDays <= 7)
        .toList();

    if (upcomingEvents.isNotEmpty) {
      processedEventIds.addAll(upcomingEvents.map((e) => e.id));
      segments.add(EventSegment(
        title: 'Coming Up This Week',
        description: '${upcomingEvents.length} events in the next 7 days',
        icon: Icons.upcoming,
        events: upcomingEvents,
        interestScore:
            _calculateAverageInterestScore(upcomingEvents, userInterests ?? []),
      ));
    }

    // Topic-based categorization
    if (enableTopicCategorization) {
      final remainingEvents =
          events.where((e) => !processedEventIds.contains(e.id)).toList();

      final topicCategories = _categorizeEventsByTopic(remainingEvents);

      for (final category in topicCategories.entries) {
        if (category.value.isNotEmpty) {
          processedEventIds.addAll(category.value.map((e) => e.id));
          segments.add(EventSegment(
            title: category.key,
            description:
                '${category.value.length} ${category.key.toLowerCase()} events',
            icon: _getIconForCategory(category.key),
            events: category.value,
            interestScore: _calculateAverageInterestScore(
                category.value, userInterests ?? []),
          ));
        }
      }
    }

    // Location-based grouping
    if (enableLocationGrouping) {
      final remainingEvents =
          events.where((e) => !processedEventIds.contains(e.id)).toList();

      final locationGroups = _groupEventsByLocation(remainingEvents);

      for (final location in locationGroups.entries) {
        if (location.value.length >= 2) {
          // Only create segments for locations with multiple events
          processedEventIds.addAll(location.value.map((e) => e.id));
          segments.add(EventSegment(
            title: 'Events at ${location.key}',
            description: '${location.value.length} events',
            icon: Icons.location_on,
            events: location.value,
            interestScore: _calculateAverageInterestScore(
                location.value, userInterests ?? []),
          ));
        }
      }
    }

    // Add any remaining events
    final otherEvents =
        events.where((e) => !processedEventIds.contains(e.id)).toList();

    if (otherEvents.isNotEmpty) {
      segments.add(EventSegment(
        title: 'More Events',
        description: '${otherEvents.length} additional events',
        icon: Icons.event,
        events: otherEvents,
        interestScore:
            _calculateAverageInterestScore(otherEvents, userInterests ?? []),
      ));
    }

    // Sort segments by relevance score
    segments.sort((a, b) {
      final scoreA = a.interestScore ?? 0.0;
      final scoreB = b.interestScore ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return segments;
  }

  /// Identify weekly meetings based on patterns
  static List<Event> _identifyWeeklyMeetings(List<Event> events) {
    // Logic to identify events that occur weekly
    final weeklyEvents = <Event>[];
    final Map<int, List<Event>> eventsByWeekday = {};

    // Group events by weekday
    for (final event in events) {
      final weekday = event.startDate.weekday;
      if (!eventsByWeekday.containsKey(weekday)) {
        eventsByWeekday[weekday] = [];
      }
      eventsByWeekday[weekday]!.add(event);
    }

    // Check if there are consistent events on the same weekday
    eventsByWeekday.forEach((weekday, eventsOnWeekday) {
      if (eventsOnWeekday.length >= 2) {
        // Check if events have similar titles
        final firstTitle = eventsOnWeekday.first.title.toLowerCase();

        // Check for consistent "weekly" pattern in titles/descriptions
        final hasWeeklyPatternInContent = eventsOnWeekday.any((e) {
          final combinedText = '${e.title} ${e.description}'.toLowerCase();
          return combinedText.contains('weekly') ||
              combinedText.contains('every week') ||
              combinedText.contains('each week');
        });

        // Check if events are roughly one week apart
        bool hasWeeklyTimePattern = false;
        if (eventsOnWeekday.length >= 2) {
          final sortedByDate = List<Event>.from(eventsOnWeekday)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          int consistentWeeklyGaps = 0;

          for (int i = 0; i < sortedByDate.length - 1; i++) {
            final currentDate = sortedByDate[i].startDate;
            final nextDate = sortedByDate[i + 1].startDate;
            final dayDifference = nextDate.difference(currentDate).inDays;

            // Consider it weekly if it's between 6-8 days apart (to account for slight variations)
            if (dayDifference >= 6 && dayDifference <= 8) {
              consistentWeeklyGaps++;
            }
          }

          // If at least 75% of gaps are weekly, consider it a weekly pattern
          hasWeeklyTimePattern =
              consistentWeeklyGaps >= (sortedByDate.length - 1) * 0.75;
        }

        // If events have consistent titles or weekly patterns, consider them weekly meetings
        if (hasWeeklyPatternInContent || hasWeeklyTimePattern) {
          weeklyEvents.addAll(eventsOnWeekday);
        }
      }
    });

    return weeklyEvents;
  }

  /// Identify series events from a list of events
  static Map<String, List<Event>> _identifySeriesEvents(List<Event> events) {
    if (events.isEmpty) return {};

    final Map<String, List<Event>> seriesMap = {};
    final Set<String> processedEvents = {};

    // First pass: Look for explicit part numbers
    for (final event in events) {
      if (processedEvents.contains(event.id)) continue;

      final seriesInfo = _extractSeriesInfo(event.title);
      if (seriesInfo != null) {
        final seriesTitle = seriesInfo.seriesTitle;

        // Find other events in the same series
        final seriesEvents = [event];
        for (final otherEvent in events) {
          if (otherEvent.id != event.id &&
              !processedEvents.contains(otherEvent.id)) {
            final otherSeriesInfo = _extractSeriesInfo(otherEvent.title);

            // Check if it's part of the same series
            if (otherSeriesInfo != null &&
                otherSeriesInfo.seriesTitle == seriesTitle) {
              seriesEvents.add(otherEvent);
              processedEvents.add(otherEvent.id);
            }
          }
        }

        if (seriesEvents.length > 1) {
          seriesMap[seriesTitle] = seriesEvents;
          processedEvents.addAll(seriesEvents.map((e) => e.id));
        }
      }
    }

    // Second pass: Look for title similarity
    for (final event in events) {
      if (processedEvents.contains(event.id)) continue;

      final baseTitle = _cleanPartNumberFromTitle(event.title);
      if (baseTitle.split(' ').length >= 3) {
        // Only consider substantial titles
        final similarEvents = [event];

        for (final otherEvent in events) {
          if (otherEvent.id != event.id &&
              !processedEvents.contains(otherEvent.id)) {
            final otherBaseTitle = _cleanPartNumberFromTitle(otherEvent.title);

            // Check if titles are similar
            if (_areTitlesSimilar(baseTitle, otherBaseTitle) &&
                event.organizerName == otherEvent.organizerName) {
              similarEvents.add(otherEvent);
              processedEvents.add(otherEvent.id);
            }
          }
        }

        if (similarEvents.length > 1) {
          final seriesTitle = baseTitle;
          seriesMap[seriesTitle] = similarEvents;
          processedEvents.addAll(similarEvents.map((e) => e.id));
        }
      }
    }

    return seriesMap;
  }

  /// Check if two titles are similar (shared words)
  static bool _areTitlesSimilar(String title1, String title2) {
    final words1 = title1
        .toLowerCase()
        .split(' ')
        .where((w) => w.length > 3) // Only consider significant words
        .toSet();
    final words2 =
        title2.toLowerCase().split(' ').where((w) => w.length > 3).toSet();

    // Find common words
    final commonWords = words1.intersection(words2);

    // Calculate similarity based on percentage of common words
    final totalUniqueWords = words1.union(words2).length;
    final similarity =
        totalUniqueWords > 0 ? commonWords.length / totalUniqueWords : 0.0;

    return similarity >
        0.5; // Titles are similar if they share more than 50% of words
  }

  /// Extract series information from a title
  static SeriesInfo? _extractSeriesInfo(String title) {
    // Pattern for "Part X", "Session Y", etc.
    var match = RegExp(r'(Part|Session|Vol|Episode|Week|Day)\s*(\d+)',
            caseSensitive: false)
        .firstMatch(title);

    if (match != null) {
      final partType = match.group(1)!;
      final partNumber = match.group(2)!;
      final seriesTitle = title
          .replaceFirst(
              RegExp('$partType\\s*$partNumber[:\\s]*',
                  caseSensitive: false),
              '')
          .trim();
      return SeriesInfo(seriesTitle, '$partType $partNumber');
    }

    // Pattern for "(X)" or "[X]"
    match = RegExp(r'[\(\[]\s*(\d+)\s*[\)\]]', caseSensitive: false)
        .firstMatch(title);

    if (match != null) {
      final partNumber = match.group(1)!;
      final seriesTitle = title
          .replaceFirst(
              RegExp('\\s*[\\(\\[]\\s*$partNumber\\s*[\\)\\]]\\s*'), '')
          .trim();
      return SeriesInfo(seriesTitle, 'Part $partNumber');
    }

    // Pattern for "X of Y" or "X/Y"
    match = RegExp(r'(\d+)(?:\s+of|\s*/)\s*(\d+)', caseSensitive: false)
        .firstMatch(title);

    if (match != null) {
      final partNumber = match.group(1)!;
      final totalParts = match.group(2)!;
      final seriesTitle = title
          .replaceFirst(
              RegExp('\\s+$partNumber(?:\\s+of|\\s*/)\\s*$totalParts\\s*'),
              '')
          .trim();
      return SeriesInfo(seriesTitle, '$partNumber of $totalParts');
    }

    return null;
  }

  /// Format the weekday as a string
  static String _formatWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1]; // Weekday is 1-based in DateTime
  }

  /// Clean part numbers from a title
  static String _cleanPartNumberFromTitle(String title) {
    // Clean various part number formats
    return title
        .replaceFirst(
            RegExp(r'(Part|Session|Vol|Episode|Week|Day)\s*\d+[:\s]*',
                caseSensitive: false),
            '')
        .replaceFirst(RegExp(r'\s*[\(\[]\s*\d+\s*[\)\]]\s*'), '')
        .replaceFirst(RegExp(r'\s+\d+(?:\s+of|\s*/)\s*\d+\s*'), '')
        .trim();
  }

  /// Calculate the average interest score for a list of events
  static double _calculateAverageInterestScore(
      List<Event> events, List<String> userInterests) {
    if (events.isEmpty || userInterests.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (final event in events) {
      // Get event tags (could be empty if not available)
      final eventTags = event.tags;

      // Combine all event text for matching
      final eventText = "${event.title} ${event.description}".toLowerCase();

      // Count matching interests
      int matchCount = 0;
      for (final interest in userInterests) {
        if (eventText.contains(interest.toLowerCase()) ||
            eventTags.any(
                (tag) => tag.toLowerCase().contains(interest.toLowerCase()))) {
          matchCount++;
        }
      }

      // Calculate individual event score
      final eventScore =
          userInterests.isNotEmpty ? matchCount / userInterests.length : 0.0;
      totalScore += eventScore;
    }

    // Return average score across all events
    return totalScore / events.length;
  }

  /// Calculate relevance score for an event based on multiple factors
  static double _calculateRelevanceScore(
    Event event, {
    List<String>? userInterests,
    Map<String, int>? pastAttendance,
    DateTime? now,
  }) {
    double score = 0.0;
    now ??= DateTime.now();

    // Time proximity score (events closer to current date get higher scores)
    final daysUntilEvent = event.startDate.difference(now).inDays;
    if (daysUntilEvent >= 0) {
      // Score decreases as days increase, max score for events today
      score += math.max(0, 10 - (daysUntilEvent * 0.5));
    }

    // Interest matching score
    if (userInterests != null && userInterests.isNotEmpty) {
      final eventText = '${event.title} ${event.description}'.toLowerCase();
      final matchingInterests = userInterests
          .where((interest) => eventText.contains(interest.toLowerCase()))
          .length;
      score += matchingInterests * 2.0;
    }

    // Past attendance score
    if (pastAttendance != null) {
      final organizerScore = pastAttendance[event.organizerName] ?? 0;
      score += math.min(5, organizerScore * 0.5); // Cap at 5 points
    }

    // Time of day preference score (assuming working hours are preferred)
    final hour = event.startDate.hour;
    if (hour >= 9 && hour <= 18) {
      // During typical working/class hours
      score += 2.0;
    } else if (hour >= 19 && hour <= 22) {
      // Evening events
      score += 1.0;
    }

    return score;
  }

  /// Categorize events by topic using keyword matching
  static Map<String, List<Event>> _categorizeEventsByTopic(List<Event> events) {
    final Map<String, List<String>> topicKeywords = {
      'Academic': [
        'lecture',
        'seminar',
        'workshop',
        'research',
        'study',
        'academic'
      ],
      'Social': ['party', 'meetup', 'social', 'gathering', 'networking'],
      'Career': ['career', 'job', 'internship', 'professional', 'resume'],
      'Arts & Culture': [
        'art',
        'music',
        'performance',
        'exhibition',
        'cultural'
      ],
      'Sports & Wellness': [
        'sports',
        'fitness',
        'health',
        'wellness',
        'workout'
      ],
      'Technology': ['tech', 'coding', 'programming', 'software', 'hardware'],
      'Leadership': ['leadership', 'volunteer', 'community', 'service'],
    };

    final Map<String, List<Event>> categorizedEvents = {};

    for (final event in events) {
      final eventText = '${event.title} ${event.description}'.toLowerCase();
      bool categorized = false;

      for (final topic in topicKeywords.entries) {
        if (topic.value.any((keyword) => eventText.contains(keyword))) {
          categorizedEvents.putIfAbsent(topic.key, () => []).add(event);
          categorized = true;
          break;
        }
      }

      if (!categorized) {
        categorizedEvents.putIfAbsent('Other', () => []).add(event);
      }
    }

    return categorizedEvents;
  }

  /// Group events by location proximity
  static Map<String, List<Event>> _groupEventsByLocation(List<Event> events) {
    final Map<String, List<Event>> locationGroups = {};

    for (final event in events) {
      final location = _normalizeLocation(event.location);
      locationGroups.putIfAbsent(location, () => []).add(event);
    }

    return locationGroups;
  }

  /// Normalize location string to group similar locations
  static String _normalizeLocation(String location) {
    final normalized = location.toLowerCase();

    // Define common building/area patterns
    final buildings = {
      'student union': 'Student Union',
      'commons': 'Commons',
      'center': 'Center',
      'hall': 'Hall',
      'library': 'Library',
    };

    for (final building in buildings.entries) {
      if (normalized.contains(building.key)) {
        return building.value;
      }
    }

    return location;
  }

  /// Get appropriate icon for category
  static IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Icons.school;
      case 'social':
        return Icons.people;
      case 'career':
        return Icons.work;
      case 'arts & culture':
        return Icons.palette;
      case 'sports & wellness':
        return Icons.fitness_center;
      case 'technology':
        return Icons.computer;
      case 'leadership':
        return Icons.star;
      default:
        return Icons.event;
    }
  }
}

/// Helper class to store series information
class SeriesInfo {
  final String seriesTitle;
  final String partInfo;

  SeriesInfo(this.seriesTitle, this.partInfo);
}
