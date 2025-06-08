import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart' as search_provider;

// Re-export the search provider
export 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart' show searchSpacesProvider;

/// Provider for all spaces by type
final spacesByTypeProvider =
    FutureProvider<Map<SpaceType, List<Space>>>((ref) async {
  try {
    return await SpaceService.getAllSpacesByType();
  } catch (e) {
    // In case of error, return empty map
    return {
      SpaceType.studentOrg: [],
      SpaceType.universityOrg: [],
      SpaceType.campusLiving: [],
      SpaceType.fraternityAndSorority: [],
      SpaceType.other: [],
    };
  }
});

/// Provider for spaces of a specific type
final spacesBySpecificTypeProvider =
    FutureProvider.family<List<Space>, SpaceType>((ref, type) async {
  try {
    return await SpaceService.getSpacesByType(type);
  } catch (e) {
    return [];
  }
});

/// Provider for spaces related to specific events
final spacesByEventsProvider =
    FutureProvider.family<List<Space>, List<String>>((ref, eventIds) async {
  try {
    return await SpaceService.getSpacesWithSpecificEvents(eventIds);
  } catch (e) {
    return [];
  }
});

/// Provider for searching spaces by name
final spacesByNameSearchProvider = search_provider.searchSpacesProvider;
