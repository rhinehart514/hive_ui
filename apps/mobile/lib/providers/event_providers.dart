import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/rss_service.dart';
import 'package:hive_ui/services/event_service.dart';

/// Provider for all events
final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  // Get current time
  final now = DateTime.now();

  // Load events from Firestore
  final events = await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 50,
  );

  // Filter out events that have already started
  return events.where((event) => event.startDate.isAfter(now)).toList();
});

/// Provider for refreshing events (force refresh)
final refreshEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  // Invalidate the regular provider
  ref.invalidate(eventsProvider);
  // Try to get from Firestore first
  return await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 100,
  );
});

/// Provider for getting events by category
final eventsByCategoryProvider = FutureProvider.family
    .autoDispose<List<Event>, String>((ref, category) async {
  final events = await ref.watch(eventsProvider.future);
  return events.where((event) => event.category == category).toList();
});

/// Provider for getting upcoming events (today or in the future)
final upcomingEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  // Use Firestore directly with query filters for better performance
  final now = DateTime.now();
  
  // Get events from now up to 7 days in the future, prioritizing the most imminent 
  final events = await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 100, // Increased limit to ensure we have enough upcoming events
    startDate: now,
    endDate: now.add(const Duration(days: 7)), // Focus on the next 7 days
  );
  
  // Sort by start date (most imminent first)
  events.sort((a, b) {
    // First prioritize events today
    final aIsToday = a.startDate.day == now.day && 
                     a.startDate.month == now.month && 
                     a.startDate.year == now.year;
    final bIsToday = b.startDate.day == now.day && 
                     b.startDate.month == now.month && 
                     b.startDate.year == now.year;
    
    if (aIsToday && !bIsToday) return -1;
    if (!aIsToday && bIsToday) return 1;
    
    // Then sort by start date
    return a.startDate.compareTo(b.startDate);
  });
  
  return events;
});

/// Provider for getting past events
final pastEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  // Use Firestore directly with query filters for better performance
  final now = DateTime.now();
  final pastEndDate = DateTime(now.year, now.month, now.day);

  return await RssService.loadEventsFromFirestore(
    includeExpired: true,
    limit: 50,
    endDate: pastEndDate,
  );
});

/// Provider for getting today's events
final todayEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 30,
    startDate: startOfDay,
    endDate: endOfDay,
  );
});

/// Provider for getting this week's events (next 7 days)
final thisWeekEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final now = DateTime.now();
  final weekEnd = DateTime(now.year, now.month, now.day + 7);

  final events = await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 50,
    startDate: now,
    endDate: weekEnd,
  );

  // Filter out events that have already started
  return events.where((event) => event.startDate.isAfter(now)).toList();
});

/// Provider for getting events in a date range
final eventsInRangeProvider = FutureProvider.family
    .autoDispose<List<Event>, DateTimeRange>((ref, dateRange) async {
  return await RssService.loadEventsFromFirestore(
    includeExpired: true,
    limit: 50,
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});

/// Provider for event categories
final eventCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  final categories = <String>{};

  for (final event in events) {
    if (event.category.isNotEmpty) {
      categories.add(event.category);
    }
  }

  final sortedCategories = categories.toList()..sort();
  return sortedCategories;
});

/// Provider for searching events
final searchEventsProvider =
    FutureProvider.family.autoDispose<List<Event>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }

  // For search, we need to get all recent events and filter in-memory
  // A proper full-text search would require a dedicated search service like Algolia
  final events = await RssService.loadEventsFromFirestore(
    includeExpired: false,
    limit: 200, // Get more events for better search results
  );

  final lowercaseQuery = query.toLowerCase();

  return events
      .where((event) =>
          event.title.toLowerCase().contains(lowercaseQuery) ||
          event.description.toLowerCase().contains(lowercaseQuery) ||
          event.category.toLowerCase().contains(lowercaseQuery))
      .toList();
});

/// Provider for getting events that a user has saved/RSVPed to
final userSavedEventsProvider = FutureProvider.family<List<Event>, String>((ref, userId) async {
  // Get both saved and RSVPed events since they are the same
  return await EventService.getRsvpedEvents();
});

// Selected event category state
final selectedEventCategoryProvider = StateProvider<String?>((ref) => null);
