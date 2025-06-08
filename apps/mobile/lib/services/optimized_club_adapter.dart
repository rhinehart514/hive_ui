import 'package:flutter/material.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/services/optimized_data_service.dart';
import 'package:hive_ui/services/firebase_monitor.dart';

/// Adapter service that provides the same interface as ClubService
/// but uses the optimized data service internally to reduce Firebase reads
class OptimizedClubAdapter {
  static bool _isInitialized = false;

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize the underlying optimized service
    await OptimizedDataService.initialize();
    _isInitialized = true;

    debugPrint('OptimizedClubAdapter initialized');
  }

  /// Get a club by ID with immediate return from cache
  static Club? getClubById(String id) {
    // Use the compatibility method from optimized service
    final club = OptimizedDataService.getClubFromSpace(id);

    // Record the cache access
    if (club != null) {
      FirebaseMonitor.recordRead(count: 1, cached: true);
    }

    return club;
  }

  /// Get all clubs with optimized caching
  static Future<List<Club>> getAllClubs({bool forceRefresh = false}) async {
    // Get spaces from optimized service and convert to clubs
    final spaces =
        await OptimizedDataService.getAllSpaces(forceRefresh: forceRefresh);
    final clubs =
        spaces.map((space) => Club.fromSpace(space.toJson())).toList();

    debugPrint(
        'OptimizedClubAdapter: Converted ${spaces.length} spaces to clubs');
    return clubs;
  }

  /// Get clubs by category with optimized caching
  static Future<List<Club>> getClubsByCategory(String category,
      {bool forceRefresh = false}) async {
    // Get spaces from optimized service and convert to clubs
    final spaces = await OptimizedDataService.getSpacesByCategory(category,
        forceRefresh: forceRefresh);
    final clubs =
        spaces.map((space) => Club.fromSpace(space.toJson())).toList();

    debugPrint(
        'OptimizedClubAdapter: Converted ${spaces.length} spaces to clubs for category $category');
    return clubs;
  }

  /// Get cached clubs without making network requests
  static List<Club> getCachedClubs() {
    // Get spaces from in-memory cache only
    final spaces = OptimizedDataService.getCachedSpaces();
    final clubs =
        spaces.map((space) => Club.fromSpace(space.toJson())).toList();

    // Record cache usage
    FirebaseMonitor.recordRead(count: clubs.length, cached: true);

    debugPrint(
        'OptimizedClubAdapter: Retrieved ${clubs.length} clubs from cache');
    return clubs;
  }

  /// Get events for a club with optimized caching
  static Future<List<Event>> getClubEvents(String clubId,
      {int limit = 10, bool forceRefresh = false}) async {
    // Use the optimized service to get events for a space
    final events =
        await OptimizedDataService.getEventsForSpace(clubId, limit: limit);

    debugPrint(
        'OptimizedClubAdapter: Retrieved ${events.length} events for club $clubId');
    return events;
  }

  /// Clear caches (for testing or logout)
  static Future<void> clearCache() async {
    await OptimizedDataService.clearCache();
    debugPrint('OptimizedClubAdapter: Cache cleared');
  }
}
