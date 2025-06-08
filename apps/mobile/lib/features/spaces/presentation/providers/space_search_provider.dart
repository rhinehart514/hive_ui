import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

/// Provider for the search query string
final spaceSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for the search UI state (expanded/collapsed)
final spaceSearchActiveProvider = StateProvider<bool>((ref) => false);

/// Provider for searched spaces based on the query
final searchedSpacesProvider = FutureProvider<List<Space>>((ref) async {
  final query = ref.watch(spaceSearchQueryProvider);
  final isActive = ref.watch(spaceSearchActiveProvider);
  
  // Return empty list if query is empty or search is not active
  if (query.isEmpty || !isActive) {
    return [];
  }
  
  debugPrint('Searching spaces with query: $query');
  
  try {
    final List<Space> results = [];
    
    // Search for spaces by ID pattern
    if (query.length > 2) {
      final spacesByIdPartial = await SpaceService.searchSpacesById(query);
      if (spacesByIdPartial.isNotEmpty) {
        debugPrint('Found ${spacesByIdPartial.length} spaces with IDs containing: $query');
        results.addAll(spacesByIdPartial);
      }
    }
    
    // Search by name and other criteria (partial match)
    final searchResults = await SpaceService.searchSpacesByName(query);
    
    // Add name search results, avoiding duplicates
    for (final space in searchResults) {
      if (!results.any((s) => s.id == space.id)) {
        results.add(space);
      }
    }
    
    debugPrint('Found ${results.length} total spaces matching "$query"');
    return results;
  } catch (e) {
    debugPrint('Error searching spaces: $e');
    return [];
  }
});

/// Provider for searched spaces based on a query
final searchSpacesProvider = FutureProvider.family<List<SpaceEntity>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }
  
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.searchSpaces(query);
});

/// Provider for featured spaces
final featuredSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getFeaturedSpaces();
});

/// Provider for newest spaces
final newestSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getNewestSpaces();
});

/// Provider for trending spaces
final trendingSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getTrendingSpaces();
});

/// Provider for spaces with upcoming events
final spacesWithEventsProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getSpacesWithUpcomingEvents();
});

/// Provider for spaces joined by the current user
final joinedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getJoinedSpaces();
});

/// Provider for spaces where the user has pending invitations
final invitedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getInvitedSpaces();
});

/// Provider for recommended spaces for the current user
final recommendedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spaceRepositoryProvider);
  return repository.getRecommendedSpaces();
}); 