import 'package:flutter/material.dart'; // For Icons
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/club.dart';
import '../services/club_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for the currently selected category
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for accessing all clubs (automatically refreshes based on filtered events)
final clubsProvider = FutureProvider.autoDispose<List<Club>>((ref) async {
  // Get all clubs from the service
  return ClubService.getAllExtractedClubs();
});

/// Provider for refreshing clubs
final refreshClubsProvider =
    FutureProvider.autoDispose<List<Club>>((ref) async {
  // Invalidate the regular provider
  ref.invalidate(clubsProvider);
  // Force refresh from network
  return await ClubService.getRefreshedClubs(forceRefresh: true);
});

/// Provider for featured clubs (verified or with multiple events)
final featuredClubsProvider =
    FutureProvider.autoDispose<List<Club>>((ref) async {
  final clubs = await ref.watch(clubsProvider.future);
  return clubs.where((club) => club.isFeatured).toList();
});

/// Provider for getting clubs by category
final clubsByCategoryProvider = FutureProvider.family
    .autoDispose<List<Club>, String>((ref, category) async {
  final clubs = await ref.watch(clubsProvider.future);
  return clubs.where((club) => club.category == category).toList();
});

/// Provider for getting verified clubs (official + buffalo.edu email)
final verifiedClubsProvider =
    FutureProvider.autoDispose<List<Club>>((ref) async {
  final clubs = await ref.watch(clubsProvider.future);
  return clubs.where((club) => club.isVerified).toList();
});

/// Provider for searching clubs
final searchClubsProvider =
    FutureProvider.family.autoDispose<List<Club>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }

  final clubs = await ref.watch(clubsProvider.future);
  final lowercaseQuery = query.toLowerCase();

  return clubs
      .where((club) =>
          club.name.toLowerCase().contains(lowercaseQuery) ||
          club.description.toLowerCase().contains(lowercaseQuery) ||
          club.category.toLowerCase().contains(lowercaseQuery) ||
          club.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
          club.categories.any(
              (category) => category.toLowerCase().contains(lowercaseQuery)))
      .toList();
});

/// Selected club category state
final selectedClubCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for accessing all unique categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final clubsAsync = await ref.watch(clubsProvider.future);

  // Collect all primary categories and additional categories
  final Set<String> allCategories = {};

  for (final club in clubsAsync) {
    if (club.category.isNotEmpty) {
      allCategories.add(club.category);
    }
    allCategories.addAll(club.categories);
  }

  // Convert to sorted list
  final categoriesList = allCategories.toList()..sort();
  return categoriesList;
});

/// Track refresh attempts to prevent infinite loops
final Map<String, int> _clubRefreshAttempts = {};

/// Provider for a specific club by ID
final clubByIdProvider =
    FutureProvider.family<Club?, String>((ref, clubId) async {
  try {
    // Log the attempt to fetch
    debugPrint('Fetching club with ID: $clubId');

    // 1. First try to get the club from the in-memory cache
    final cachedClub = ClubService.getClubById(clubId);
    if (cachedClub != null) {
      debugPrint('Found club in memory cache: ${cachedClub.name}');
      return cachedClub;
    }

    // 2. If not in memory cache, try to get from Firestore directly using collectionGroup
    debugPrint(
        'Club not in memory cache, searching in Firestore using collectionGroup...');
    try {
      final firestore = FirebaseFirestore.instance;

      // Use collectionGroup to query across all spaces collections
      final spaceQuery = await firestore
          .collectionGroup('spaces')
          .where('id', isEqualTo: clubId)
          .limit(1)
          .get();

      if (spaceQuery.docs.isNotEmpty) {
        final spaceDoc = spaceQuery.docs.first;
        final spaceData = spaceDoc.data();

        debugPrint('Found club in spaces collection: ${spaceData['name']}');

        // Convert space data to Club format if needed
        final club = Club.fromSpace(spaceData);

        // Update memory cache with this club
        await ClubService.addClubToCache(club);

        return club;
      }

      debugPrint('Club not found in Firestore: $clubId');
      return null;
    } catch (e) {
      debugPrint('Error searching for club in Firestore: $e');

      // For now, still try the old paths for backward compatibility
      return _searchInLegacyPaths(clubId);
    }
  } catch (e) {
    debugPrint('Error in clubByIdProvider: $e');
    return null;
  }
});

/// Search for a club in legacy paths (temporary, for backward compatibility)
Future<Club?> _searchInLegacyPaths(String clubId) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Try known typed spaces paths
    final branches = [
      'student_organizations',
      'fraternity_sorority_life',
      'campus_living',
      'university_departments'
    ];

    // Try in spaces collection by branch
    for (final branch in branches) {
      final docRef = firestore
          .collection('spaces')
          .doc(branch)
          .collection('spaces')
          .doc(clubId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        debugPrint('Found club in legacy path spaces/$branch/spaces: $branch');
        final clubData = docSnapshot.data()!;

        // Convert space data to Club format if needed
        final club = clubData.containsKey('spaceType')
            ? Club.fromSpace(clubData)
            : Club.fromJson(clubData);

        // Update memory cache with this club
        await ClubService.addClubToCache(club);

        return club;
      }
    }

    // Try root spaces collection
    final rootSpaceRef = firestore.collection('spaces').doc(clubId);
    final rootSnapshot = await rootSpaceRef.get();

    if (rootSnapshot.exists && rootSnapshot.data() != null) {
      debugPrint('Found club in root spaces collection');
      final clubData = rootSnapshot.data()!;

      // Convert space data to Club format if needed
      final club = clubData.containsKey('spaceType')
          ? Club.fromSpace(clubData)
          : Club.fromJson(clubData);

      // Update memory cache with this club
      await ClubService.addClubToCache(club);

      return club;
    }

    return null;
  } catch (e) {
    debugPrint('Error searching in legacy paths: $e');
    return null;
  }
}

/// Provider for clubs by organizer name
final clubByOrganizerNameProvider =
    FutureProvider.family.autoDispose<Club?, String>((ref, name) async {
  // Try immediate lookup from cache
  final cachedClub = ClubService.getClubByOrganizerName(name);
  if (cachedClub != null) {
    return cachedClub;
  }

  // Create id from name
  final id = Club.createIdFromName(name);
  return ref.watch(clubByIdProvider(id).future);
});
