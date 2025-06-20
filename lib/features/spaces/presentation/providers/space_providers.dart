import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/spaces/utils/space_path_fixer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_controller.dart' show SpaceSearchNotifier;

/// Cache duration for space data
const spaceCacheDuration = Duration(minutes: 15);

/// Provider for space service
final spaceServiceProvider = Provider<SpaceService>((ref) => SpaceService());

/// Provider for spaces state (with loading, error handling)
final spacesProvider = StateNotifierProvider<SpacesNotifier, Map<String, SpaceEntity>>((ref) {
  return SpacesNotifier(ref);
});

/// Provider for spaces organized by type from hierarchical Firestore structure
/// Uses the format spaces/[type]/spaces for better organization
final hierarchicalSpacesProvider =
    FutureProvider<Map<String, List<Space>>>((ref) async {
  try {
    // Get current user to determine joined spaces
    final userData = ref.watch(userProvider);
    final List<String> joinedSpaceIds = userData?.joinedClubs ?? [];

    debugPrint('\n========== STARTING HIERARCHICAL SPACES FETCH ==========');
    debugPrint('User has ${joinedSpaceIds.length} joined spaces');

    // Define the type collections to fetch from
    final Map<String, String> typeCollections = {
      'Student Organizations': 'student_organizations',
      'University Groups': 'university_organizations',
      'Campus Living': 'campus_living',
      'Greek Life': 'fraternity_and_sorority',
      'Other Spaces': 'other'
    };

    debugPrint(
        'Fetching spaces from collections: ${typeCollections.values.join(', ')}');

    // Result will be grouped by human-readable category
    final Map<String, List<Space>> result = {};

    // Initialize categories with empty lists
    for (final category in typeCollections.keys) {
      result[category] = [];
    }

    // Fetch spaces for each type collection in parallel
    final futures = typeCollections.entries.map((entry) async {
      final displayName = entry.key;
      final collectionPath = entry.value;

      debugPrint(
          '\n--- Processing collection: $collectionPath ($displayName) ---');

      try {
        // Try using our new path detector to get spaces from the correct structure
        debugPrint('Using SpacePathFixer for $collectionPath...');
        final List<Space> spaces = [];
        final pathFixerSpaces =
            await SpacePathFixer.getSpacesWithPathDetection(
              collectionPath,
              includePrivate: false, // Don't include private spaces in explore
            );
        spaces.addAll(pathFixerSpaces);

        // If we didn't find enough spaces, try the regular method with a higher limit
        if (spaces.isEmpty || spaces.length < 10) {
          debugPrint(
              'Found only ${spaces.length} spaces with path detection, trying regular service...');
          final regularSpaces = await SpaceService.getSpacesByTypePath(
            collectionPath: collectionPath,
            limit: 40, // Increased limit to ensure we get enough spaces
            useCache: true,
            includePrivate: false, // Don't include private spaces in explore
          );

          // Add spaces from regular method, avoiding duplicates
          final existingIds = spaces.map((s) => s.id).toSet();
          for (final space in regularSpaces) {
            if (!existingIds.contains(space.id)) {
              spaces.add(space);
              existingIds.add(space.id);
            }
          }
        }

        debugPrint(
            'Retrieved ${spaces.length} total spaces from collection: $collectionPath');

        // Log details about each space for debugging
        if (spaces.isNotEmpty) {
          debugPrint('Sample spaces from $collectionPath:');
          for (final space in spaces.take(5)) {
            debugPrint('  - ${space.id}: ${space.name} (${space.spaceType})');
          }
        } else {
          debugPrint('WARNING: No spaces found in collection: $collectionPath');
        }

        // First mark spaces as joined based on user data
        final updatedSpaces = spaces.map((space) {
          if (joinedSpaceIds.contains(space.id)) {
            return space.copyWith(isJoined: true);
          }
          return space;
        }).toList();
        
        // Then filter out spaces that the user has already joined
        // for the explore section (we want to show only spaces they haven't joined)
        final exploreSpaces = updatedSpaces.where((space) => 
          !joinedSpaceIds.contains(space.id)).toList();

        debugPrint('After filtering joined spaces, showing ${exploreSpaces.length}/${updatedSpaces.length} spaces');

        return MapEntry(displayName, exploreSpaces);
      } catch (e, stack) {
        debugPrint('Error loading spaces for type $collectionPath: $e');
        debugPrint('Stack trace: $stack');
        // Return empty list for this category but don't fail the whole fetch
        return MapEntry(displayName, <Space>[]);
      }
    });

    // Wait for all fetches to complete
    final results = await Future.wait(futures);

    // Combine results
    for (final entry in results) {
      result[entry.key] = entry.value;
      debugPrint('${entry.key}: ${entry.value.length} spaces');
    }

    final totalSpaces =
        result.values.fold<int>(0, (total, list) => total + list.length);
    debugPrint('\nTotal spaces retrieved: $totalSpaces');
    debugPrint('========== COMPLETED HIERARCHICAL SPACES FETCH ==========\n');

    return result;
  } catch (e, stack) {
    debugPrint('ERROR loading hierarchical spaces: $e');
    debugPrint('Stack trace: $stack');
    rethrow;
  }
});

/// Provider for user's joined spaces
final userSpacesProvider = FutureProvider<List<Space>>((ref) async {
  try {
    // Get current user's joined club/space IDs
    final userData = ref.watch(userProvider);
    final List<String> joinedSpaceIds = userData?.joinedClubs ?? [];

    debugPrint('🔎 userSpacesProvider - Looking for ${joinedSpaceIds.length} spaces: $joinedSpaceIds');
    
    if (joinedSpaceIds.isEmpty) {
      debugPrint('⚠️ userSpacesProvider - No joined spaces found in userData');
      return [];
    }

    // Try multiple approaches to ensure we get all user spaces
    List<Space> spaces = [];
    
    // First approach: Direct document lookup by IDs
    debugPrint('🔍 userSpacesProvider - Fetching spaces with SpaceService.getUserSpaces');
    spaces = await SpaceService.getUserSpaces(joinedSpaceIds);
    debugPrint('📊 userSpacesProvider - Got ${spaces.length}/${joinedSpaceIds.length} spaces from SpaceService.getUserSpaces');
    
    // If some spaces are missing, try collection group query
    if (spaces.length < joinedSpaceIds.length) {
      final firestore = FirebaseFirestore.instance;
      final missingIds = joinedSpaceIds.where(
        (id) => !spaces.any((space) => space.id == id)
      ).toList();
      
      debugPrint('🔎 userSpacesProvider - Still missing ${missingIds.length} spaces: $missingIds');
      
      if (missingIds.isNotEmpty) {
        // APPROACH 1: Try collection group query
        try {
          debugPrint('🔍 userSpacesProvider - Trying collectionGroup query for missing spaces');
          // Look for spaces using collection group (across all subcollections)
          final spaceQuery = await firestore
              .collectionGroup('spaces')
              .where('id', whereIn: missingIds.take(10).toList()) // Firestore limit of 10
              .get();
              
          debugPrint('📊 userSpacesProvider - collectionGroup query returned ${spaceQuery.docs.length} results');
              
          // Process results
          final List<Space> additionalSpaces = [];
          for (final doc in spaceQuery.docs) {
            try {
              // Try to fetch the actual space from the service using the ID
              final spaceId = doc.data()['id'] as String? ?? doc.id;
              debugPrint('🔍 userSpacesProvider - Getting space details for $spaceId');
              final space = await SpaceService.getSpace(spaceId);
              if (space != null) {
                additionalSpaces.add(space);
                debugPrint('✅ userSpacesProvider - Got space $spaceId: ${space.name}');
              }
            } catch (e) {
              debugPrint('❌ userSpacesProvider - Error retrieving space from document: $e');
            }
          }
              
          // Add to our spaces list
          if (additionalSpaces.isNotEmpty) {
            debugPrint('➕ userSpacesProvider - Adding ${additionalSpaces.length} spaces from collectionGroup query');
            spaces.addAll(additionalSpaces);
          }
        } catch (e) {
          debugPrint('❌ userSpacesProvider - Error finding additional spaces with collectionGroup: $e');
        }
        
        // APPROACH 2: Try direct path lookups in each space type collection
        if (spaces.length < joinedSpaceIds.length) {
          debugPrint('🔍 userSpacesProvider - Trying direct path lookups in each type collection');
          final stillMissingIds = joinedSpaceIds.where(
            (id) => !spaces.any((space) => space.id == id)
          ).toList();
          
          final spaceTypes = [
            'hive_exclusive', // Add HIVE exclusive collection
            'campus_living',
            'fraternity_and_sorority',
            'student_organizations',
            'university_organizations',
            'other',
          ];
          
          final List<Space> directLookupSpaces = [];
          
          for (final spaceId in stillMissingIds) {
            // Try HIVE exclusive collection first with special handling
            try {
              final hiveExclusiveRef = firestore
                  .collection('spaces/hive_exclusive/spaces')
                  .doc(spaceId);
              
              final hiveDoc = await hiveExclusiveRef.get();
              if (hiveDoc.exists && hiveDoc.data() != null) {
                debugPrint('✅ userSpacesProvider - Found space $spaceId in spaces/hive_exclusive/spaces');
                // Manually create Space object to avoid index errors
                final data = hiveDoc.data()!;
                // Ensure ID is set correctly
                data['id'] = spaceId;
                final space = Space.fromJson(data);
                directLookupSpaces.add(space);
                continue; // Skip checking other collections
              }
            } catch (e) {
              debugPrint('❌ userSpacesProvider - Error in hive_exclusive lookup: $e');
              // Continue to try other collections
            }
            
            // Check other space type collections
            for (final type in spaceTypes.skip(1)) { // Skip hive_exclusive as we already checked it
              try {
                final docRef = firestore
                    .collection('spaces')
                    .doc(type)
                    .collection('spaces')
                    .doc(spaceId);
                
                final doc = await docRef.get();
                if (doc.exists && doc.data() != null) {
                  debugPrint('✅ userSpacesProvider - Found space $spaceId in spaces/$type/spaces');
                  // Convert document to Space object
                  final space = Space.fromJson(doc.data()!);
                  directLookupSpaces.add(space);
                  break; // Found in this type, no need to check others
                }
              } catch (e) {
                // Continue to next type
              }
            }
          }
          
          if (directLookupSpaces.isNotEmpty) {
            debugPrint('➕ userSpacesProvider - Adding ${directLookupSpaces.length} spaces from direct lookups');
            spaces.addAll(directLookupSpaces);
          }
        }
      }
    }
    
    // Check if we need to look for additional spaces from user document
    if (spaces.length < joinedSpaceIds.length) {
      final firestore = FirebaseFirestore.instance;
      final userId = userData?.id ?? FirebaseAuth.instance.currentUser?.uid;
      
      debugPrint('🔎 userSpacesProvider - Still missing spaces, checking user document');
      
      if (userId != null) {
        try {
          // Query users collection for spaces in followedSpaces field
          final userDoc = await firestore
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            final userDocData = userDoc.data();
            if (userDocData != null && userDocData['followedSpaces'] is List) {
              final List<String> followedSpaceIds = List<String>.from(userDocData['followedSpaces']);
              
              debugPrint('📊 userSpacesProvider - User has ${followedSpaceIds.length} spaces in followedSpaces: $followedSpaceIds');
              
              // Find spaces from followedSpaces that weren't already loaded
              final loadedSpaceIds = spaces.map((space) => space.id).toSet();
              final missingSpaceIds = followedSpaceIds
                  .where((id) => !loadedSpaceIds.contains(id))
                  .toList();
              
              debugPrint('🔎 userSpacesProvider - Found ${missingSpaceIds.length} additional spaces in followedSpaces: $missingSpaceIds');
              
              // Fetch the missing spaces
              if (missingSpaceIds.isNotEmpty) {
                debugPrint('🔍 userSpacesProvider - Fetching missing spaces from followedSpaces');
                final fetchedSpaces = await SpaceService.getUserSpaces(missingSpaceIds);
                debugPrint('➕ userSpacesProvider - Adding ${fetchedSpaces.length} spaces from followedSpaces');
                spaces.addAll(fetchedSpaces);
              }
            }
          }
        } catch (e) {
          debugPrint('❌ userSpacesProvider - Error finding spaces from user document: $e');
        }
      }
    }

    // Final check: Are we missing any spaces?
    if (spaces.length < joinedSpaceIds.length) {
      debugPrint('⚠️ userSpacesProvider - After all attempts, still missing ${joinedSpaceIds.length - spaces.length} spaces');
      final foundIds = spaces.map((s) => s.id).toSet();
      final missingIds = joinedSpaceIds.where((id) => !foundIds.contains(id)).toList();
      debugPrint('⚠️ userSpacesProvider - Missing space IDs: $missingIds');
    } else {
      debugPrint('✅ userSpacesProvider - Successfully found all ${spaces.length} spaces');
    }

    // Get current user ID to identify spaces created by the user
    final String? userId = userData?.id ?? FirebaseAuth.instance.currentUser?.uid;

    // Ensure all spaces are marked as joined and identify spaces created by the user
    final finalSpaces = spaces.map((space) {
      // Check if this space was created by the current user (user is in the admins list)
      final bool isCreatedByUser = userId != null && space.admins.contains(userId);
      
      return space.copyWith(
        isJoined: true, 
        // Store whether the user created this space in the customData map
        customData: {
          ...space.customData,
          'isCreatedByUser': isCreatedByUser,
        }
      );
    }).toList();
    
    // Sort spaces to show user-created spaces first
    finalSpaces.sort((a, b) {
      final bool aCreatedByUser = a.customData['isCreatedByUser'] == true;
      final bool bCreatedByUser = b.customData['isCreatedByUser'] == true;
      
      if (aCreatedByUser && !bCreatedByUser) return -1; // a comes first
      if (!aCreatedByUser && bCreatedByUser) return 1;  // b comes first
      
      // If both are created by user or neither are, sort by name
      return a.name.compareTo(b.name);
    });

    debugPrint('📊 userSpacesProvider - Returning ${finalSpaces.length} spaces: ${finalSpaces.map((s) => s.id).toList()}');
    return finalSpaces;
  } catch (e, stack) {
    debugPrint('❌ Error loading user spaces: $e\n$stack');
    // Return empty list instead of throwing to avoid breaking the UI
    return [];
  }
});

/// Provider for spaces with upcoming events
final upcomingEventsSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getSpacesWithUpcomingEvents();
});

/// Provider for trending spaces 
/// Renamed to avoid conflict with space_search_provider.dart
final allTrendingSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getTrendingSpaces();
});

/// Provider for a specific space by ID
final spaceByIdProvider = FutureProvider.family<SpaceEntity?, String>((ref, id) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getSpaceById(id);
});

/// Provider for spaces by category
final spacesByCategoryProvider =
    FutureProvider.family<List<Space>, String>((ref, category) async {
  try {
    return SpaceService.getSpacesByCategory(category);
  } catch (e) {
    debugPrint('Error loading spaces by category: $e');
    return [];
  }
});

/// Provider for HIVE exclusive spaces
final hiveExclusiveSpacesProvider = FutureProvider<List<Space>>((ref) async {
  try {
    debugPrint('🔍 Loading HIVE exclusive spaces...');
    final spaces = await SpaceService.getSpacesByTypePath(
      collectionPath: 'hive_exclusive',
      limit: 50,
    );
    debugPrint('✅ Found ${spaces.length} HIVE exclusive spaces');
    return spaces;
  } catch (e) {
    debugPrint('❌ Error loading HIVE exclusive spaces: $e');
    return [];
  }
});

/// Provider for the selected space
final selectedSpaceProvider = StateProvider<Space?>((ref) => null);

/// Provider for space search results - properly using the SpaceSearchNotifier from spaces_controller
final spaceSearchResultsProvider =
    Provider<SpaceSearchNotifier>((ref) {
  return SpaceSearchNotifier(ref);
});

/// Provider to check if current user is a manager of any spaces
final isCurrentUserManagerProvider = StateProvider<bool>((ref) => false);

/// State class for paginated spaces
class PaginatedSpacesState {
  final List<Space> spaces;
  final bool isLoading;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final String? error;
  final String sortBy;
  final bool sortDescending;
  final Map<String, bool> userJoinedSpaces;

  const PaginatedSpacesState({
    required this.spaces,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.lastDocument,
    this.hasMore = true,
    this.error,
    this.sortBy = 'memberCount',
    this.sortDescending = true,
    this.userJoinedSpaces = const {},
  });

  /// Create initial state
  factory PaginatedSpacesState.initial() {
    return const PaginatedSpacesState(
      spaces: [],
      isLoading: true,
      hasMore: true,
    );
  }

  /// Create a copy of this state with the specified fields updated
  PaginatedSpacesState copyWith({
    List<Space>? spaces,
    bool? isLoading,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    String? error,
    String? sortBy,
    bool? sortDescending,
    Map<String, bool>? userJoinedSpaces,
  }) {
    return PaginatedSpacesState(
      spaces: spaces ?? this.spaces,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      error: error, // Always replace error (null means no error)
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      userJoinedSpaces: userJoinedSpaces ?? this.userJoinedSpaces,
    );
  }

  PaginatedSpacesState withUserJoinedStatus(List<String> joinedSpaceIds) {
    final updatedSpaces = spaces.map((space) {
      final isJoined = joinedSpaceIds.contains(space.id);
      if (space.isJoined != isJoined) {
        return space.copyWith(isJoined: isJoined);
      }
      return space;
    }).toList();

    return copyWith(spaces: updatedSpaces);
  }
}

// NotifierProvider for paginated spaces
class PaginatedSpacesNotifier extends StateNotifier<PaginatedSpacesState> {
  final Ref ref;

  PaginatedSpacesNotifier(this.ref) : super(PaginatedSpacesState.initial()) {
    // Initialize with default values
    loadInitial();
  }

  // Set sort options and reload
  void setSortOptions(String sortBy, bool descending) {
    state = state.copyWith(
      sortBy: sortBy,
      sortDescending: descending,
    );
    refresh();
  }

  // Initial load
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await SpaceService.getSpacesPaginated(
        limit: 20,
        sortBy: state.sortBy,
        sortDescending: state.sortDescending,
      );

      // Fall back to local data if no spaces returned
      if (result.items.isEmpty) {
        final localSpaces = await SpaceService.getSpaces();

        state = state.copyWith(
          spaces: localSpaces,
          isLoading: false,
          hasMore: false, // Don't attempt pagination with fallback
          lastDocument: null,
          error: null,
        );
        return;
      }

      state = state.copyWith(
        spaces: result.items,
        isLoading: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
        error: null,
      );
    } catch (e) {
      debugPrint('Error loading initial spaces: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load spaces: ${e.toString()}',
      );
    }
  }

  // Load more spaces for infinite scrolling
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await SpaceService.getSpacesPaginated(
        limit: 10,
        startAfter: state.lastDocument,
        sortBy: state.sortBy,
        sortDescending: state.sortDescending,
      );

      if (result.items.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasMore: false,
        );
        return;
      }

      state = state.copyWith(
        spaces: [...state.spaces, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
      debugPrint('Error loading more spaces: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more spaces: ${e.toString()}',
      );
    }
  }

  // Refresh spaces
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      lastDocument: null,
      hasMore: true,
      error: null,
    );

    await loadInitial();
  }

  // Filter spaces by search query
  void filterBySearch(String query) {
    if (query.isEmpty) {
      refresh();
      return;
    }

    state = state.copyWith(isLoading: true);

    // Filter spaces locally first
    final lowercaseQuery = query.toLowerCase();
    final filteredSpaces = state.spaces.where((space) {
      return space.name.toLowerCase().contains(lowercaseQuery) ||
          space.description.toLowerCase().contains(lowercaseQuery);
    }).toList();

    state = state.copyWith(
      spaces: filteredSpaces,
      isLoading: false,
      hasMore: false, // Prevent pagination during search
    );
  }
}

/// Provider for paginated spaces with infinite scrolling and sorting
final paginatedSpacesProvider =
    StateNotifierProvider<PaginatedSpacesNotifier, PaginatedSpacesState>((ref) {
  return PaginatedSpacesNotifier(ref);
});

/// Provider for recommended spaces filtered to show only public unjoined spaces
final filteredRecommendedSpacesProvider = FutureProvider<List<Space>>((ref) async {
  try {
    // Get current user to determine joined spaces
    final userData = ref.watch(userProvider);
    final List<String> joinedSpaceIds = userData?.joinedClubs ?? [];
    
    debugPrint('Filtering recommended spaces - user has ${joinedSpaceIds.length} joined spaces');
    if (joinedSpaceIds.isNotEmpty) {
      debugPrint('Joined space IDs: ${joinedSpaceIds.join(', ')}');
    }
    
    // Get all public spaces (no private spaces)
    final spaces = await SpaceService.getSpacesPaginated(
      limit: 50, 
      includePrivate: false,
    );
    
    debugPrint('Retrieved ${spaces.items.length} public spaces for recommendation filtering');
    
    // Filter out joined spaces
    final filteredSpaces = spaces.items.where((space) => 
      !joinedSpaceIds.contains(space.id)).toList();
    
    debugPrint('After filtering joined spaces: ${filteredSpaces.length} spaces remain');
    
    // Sort by recommendation algorithm (popularity + relevance)
    filteredSpaces.sort((a, b) => 
      (b.metrics.memberCount + b.metrics.activeMembers) - 
      (a.metrics.memberCount + a.metrics.activeMembers));
    
    // Log some of the filtered spaces for debugging
    if (filteredSpaces.isNotEmpty) {
      final sampleSpaces = filteredSpaces.take(5).toList();
      debugPrint('Sample recommended spaces after filtering:');
      for (final space in sampleSpaces) {
        debugPrint('  - ${space.id}: ${space.name} (joined: ${joinedSpaceIds.contains(space.id)})');
      }
    }
    
    return filteredSpaces;
  } catch (e, stack) {
    debugPrint('Error loading filtered recommended spaces: $e\n$stack');
    return [];
  }
});

/// Provider for a single space by ID
final spaceProvider = Provider.family<AsyncValue<SpaceEntity?>, String>((ref, spaceId) {
  // Watch the spaces map
  final spaces = ref.watch(spacesProvider);
  
  // Check if space is in the cache
  if (spaces.containsKey(spaceId)) {
    return AsyncValue.data(spaces[spaceId]);
  }
  
  // Trigger a refresh and return a loading state
  ref.read(spacesProvider.notifier).refreshSpace(spaceId);
  return const AsyncValue.loading();
});

/// Provider for space metrics with caching
final spaceMetricsProvider = StateNotifierProvider<SpaceMetricsNotifier, Map<String, SpaceMetricsEntity>>((ref) {
  return SpaceMetricsNotifier(ref);
});

/// Provider to get metrics for a specific space with caching
final spaceMetricsByIdProvider = Provider.family<AsyncValue<SpaceMetricsEntity>, String>((ref, spaceId) {
  final metricsNotifier = ref.watch(spaceMetricsProvider.notifier);
  final metrics = ref.watch(spaceMetricsProvider);
  
  // If metrics are already in cache and not expired, return them
  if (metrics.containsKey(spaceId) && !metricsNotifier.isExpired(spaceId)) {
    return AsyncValue.data(metrics[spaceId]!);
  }
  
  // Otherwise, fetch them
  return ref.watch(_fetchSpaceMetricsProvider(spaceId));
});

/// Internal provider to fetch space metrics from the repository
final _fetchSpaceMetricsProvider = FutureProvider.family<SpaceMetricsEntity, String>((ref, spaceId) async {
  // Just create initial metrics since we don't use repository
  final metrics = SpaceMetricsEntity.initial(spaceId);
  
  // Add metrics to cache
  ref.read(spaceMetricsProvider.notifier).addMetrics(metrics);
  
  return metrics;
});

/// Notifier to manage the spaces cache
class SpacesNotifier extends StateNotifier<Map<String, SpaceEntity>> {
  final Ref _ref;
  final Map<String, DateTime> _cacheTimestamps = {};
  
  SpacesNotifier(this._ref) : super({});
  
  /// Add a space to the cache
  void addSpace(SpaceEntity space) {
    _cacheTimestamps[space.id] = DateTime.now();
    state = {...state, space.id: space};
  }
  
  /// Remove a space from the cache
  void removeSpace(String spaceId) {
    _cacheTimestamps.remove(spaceId);
    final newState = Map<String, SpaceEntity>.from(state);
    newState.remove(spaceId);
    state = newState;
  }
  
  /// Refresh a space in the cache
  Future<void> refreshSpace(String spaceId) async {
    removeSpace(spaceId);
    final repository = _ref.read(spaceRepositoryProvider);
    final space = await repository.getSpaceById(spaceId);
    if (space != null) {
      addSpace(space);
    }
  }
  
  /// Check if a cached space has expired
  bool isExpired(String spaceId) {
    final timestamp = _cacheTimestamps[spaceId];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp) > spaceCacheDuration;
  }
  
  /// Clear all spaces from the cache
  void clearCache() {
    _cacheTimestamps.clear();
    state = {};
  }
}

/// Notifier to manage the space metrics cache
class SpaceMetricsNotifier extends StateNotifier<Map<String, SpaceMetricsEntity>> {
  final Ref _ref;
  final Map<String, DateTime> _cacheTimestamps = {};
  
  SpaceMetricsNotifier(this._ref) : super({});
  
  /// Add metrics to the cache
  void addMetrics(SpaceMetricsEntity metrics) {
    _cacheTimestamps[metrics.spaceId] = DateTime.now();
    state = {...state, metrics.spaceId: metrics};
  }
  
  /// Remove metrics from the cache
  void removeMetrics(String spaceId) {
    _cacheTimestamps.remove(spaceId);
    final newState = Map<String, SpaceMetricsEntity>.from(state);
    newState.remove(spaceId);
    state = newState;
  }
  
  /// Refresh metrics in the cache
  Future<void> refreshMetrics(String spaceId) async {
    removeMetrics(spaceId);
    final metrics = SpaceMetricsEntity.initial(spaceId);
    addMetrics(metrics);
  }
  
  /// Check if cached metrics have expired
  bool isExpired(String spaceId) {
    final timestamp = _cacheTimestamps[spaceId];
    if (timestamp == null) return true;
    
    return DateTime.now().difference(timestamp) > spaceCacheDuration;
  }
  
  /// Clear all metrics from the cache
  void clearCache() {
    _cacheTimestamps.clear();
    state = {};
  }
}
