import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:flutter/material.dart';

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