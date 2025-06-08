import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/application/analytics_service.dart';
import 'package:hive_ui/features/spaces/application/providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart' as async_providers;
import 'package:hive_ui/features/spaces/presentation/providers/user_spaces_providers.dart' as user_providers;

/// Controller for the Spaces feature to handle UI logic and user interactions
class SpacesController extends StateNotifier<AsyncValue<List<SpaceEntity>>> {
  final Ref _ref;
  final TextEditingController searchController = TextEditingController();
  final List<String> categories = [
    'All',
    'Student Organizations',
    'University',
    'Campus Living',
    'Fraternities & Sororities',
    'Academic',
    'Sports',
    'Arts',
    'Social',
    'Professional',
  ];

  // Add the analytics service
  late final SpacesAnalyticsService _analyticsService;

  SpacesController(this._ref) : super(const AsyncValue.loading()) {
    // Get the analytics service
    _analyticsService = _ref.read(spacesAnalyticsServiceProvider);

    // Track screen view
    _analyticsService.trackSpacesScreenView();

    // Initialize with joined spaces
    loadJoinedSpaces();
  }

  /// Dispose of resources
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Load all spaces
  Future<void> loadAllSpaces({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final useCase = _ref.read(getAllSpacesUseCaseProvider);
      final spaces = await useCase.execute(forceRefresh: forceRefresh);
      state = AsyncValue.data(spaces);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh spaces after an update
  Future<void> refreshAfterUpdate(String spaceId) async {
    try {
      // Invalidate any cached state
      _ref.invalidate(spacesProvider);
      _ref.invalidate(user_providers.userSpacesProvider);
      _ref.invalidate(async_providers.spaceByIdProvider(spaceId));
      
      // Force a refresh of all spaces
      await loadAllSpaces(forceRefresh: true);
      
      // Track analytics
      _analyticsService.trackSpaceUpdate(spaceId);
    } catch (e) {
      debugPrint('Error refreshing spaces after update: $e');
    }
  }

  /// Load joined spaces
  Future<void> loadJoinedSpaces() async {
    state = const AsyncValue.loading();
    try {
      final useCase = _ref.read(getJoinedSpacesUseCaseProvider);
      final spaces = await useCase.execute();
      state = AsyncValue.data(spaces);

      // Track tab change to "My Spaces"
      _analyticsService.trackTabChange("My Spaces");
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Join a space
  Future<bool> joinSpace(String spaceId) async {
    try {
      final useCase = _ref.read(joinSpaceUseCaseProvider);
      final success = await useCase.execute(spaceId);
      
      if (!success) {
        debugPrint('Failed to join space: operation returned false');
        return false;
      }

      // Refresh spaces after joining
      if (state.hasValue) {
        final currentSpaces = state.value ?? [];
        final updatedSpaces = currentSpaces.map((space) {
          if (space.id == spaceId) {
            // Return a copy with isJoined set to true
            final updatedSpace = SpaceEntity(
              id: space.id,
              name: space.name,
              description: space.description,
              iconCodePoint: space.iconCodePoint,
              imageUrl: space.imageUrl,
              bannerUrl: space.bannerUrl,
              metrics: space.metrics,
              tags: space.tags,
              isJoined: true,
              isPrivate: space.isPrivate,
              moderators: space.moderators,
              admins: space.admins,
              quickActions: space.quickActions,
              relatedSpaceIds: space.relatedSpaceIds,
              createdAt: space.createdAt,
              updatedAt: DateTime.now(),
              spaceType: space.spaceType,
              eventIds: space.eventIds,
              hiveExclusive: space.hiveExclusive,
            );

            // Track space join in analytics
            _analyticsService.trackSpaceJoin(updatedSpace);

            return updatedSpace;
          }
          return space;
        }).toList();

        state = AsyncValue.data(updatedSpaces);
      }
      
      return true;
    } catch (e) {
      // Log error and return false
      debugPrint('Error joining space: $e');
      return false;
    }
  }

  /// Leave a space
  Future<bool> leaveSpace(String spaceId) async {
    try {
      // Find the space before updating to track analytics
      SpaceEntity? spaceToLeave;
      if (state.hasValue) {
        final currentSpaces = state.value ?? [];
        spaceToLeave = currentSpaces.firstWhere(
          (space) => space.id == spaceId,
          orElse: () => throw Exception('Space not found'),
        );
      }

      final useCase = _ref.read(leaveSpaceUseCaseProvider);
      final success = await useCase.execute(spaceId);
      
      if (!success) {
        debugPrint('Failed to leave space: operation returned false');
        return false;
      }

      // Track space leave in analytics
      if (spaceToLeave != null) {
        _analyticsService.trackSpaceLeave(spaceToLeave);
      }

      // Refresh spaces after leaving
      if (state.hasValue) {
        final currentSpaces = state.value ?? [];
        state = AsyncValue.data(
          currentSpaces.map((space) {
            if (space.id == spaceId) {
              // Return a copy with isJoined set to false
              return SpaceEntity(
                id: space.id,
                name: space.name,
                description: space.description,
                iconCodePoint: space.iconCodePoint,
                imageUrl: space.imageUrl,
                bannerUrl: space.bannerUrl,
                metrics: space.metrics,
                tags: space.tags,
                isJoined: false,
                isPrivate: space.isPrivate,
                moderators: space.moderators,
                admins: space.admins,
                quickActions: space.quickActions,
                relatedSpaceIds: space.relatedSpaceIds,
                createdAt: space.createdAt,
                updatedAt: DateTime.now(),
                spaceType: space.spaceType,
                eventIds: space.eventIds,
                hiveExclusive: space.hiveExclusive,
              );
            }
            return space;
          }).toList(),
        );
      }
      
      return true;
    } catch (e) {
      // Log error and return false
      debugPrint('Error leaving space: $e');
      return false;
    }
  }

  /// Search spaces
  Future<void> searchSpaces(String query) async {
    if (query.isEmpty) {
      // If query is empty, revert to showing all spaces
      await loadAllSpaces();
      return;
    }

    state = const AsyncValue.loading();
    try {
      final useCase = _ref.read(searchSpacesUseCaseProvider);
      final spaces = await useCase.execute(query);
      state = AsyncValue.data(spaces);

      // Track search analytics
      _analyticsService.trackSpaceSearch(query, spaces.length);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Filter spaces by category
  void filterByCategory(String? category) {
    if (category == null || category == 'All') {
      // No filtering needed
      loadAllSpaces();
      return;
    }

    // Special handling for Hive Exclusive
    if (category == 'Hive Exclusive') {
      final allSpaces = state.value ?? [];
      debugPrint('📊 Total spaces before filtering: ${allSpaces.length}');
      
      // Add debugging to check how many spaces have the hiveExclusive flag
      int hiveExclusiveCount = 0;
      for (var space in allSpaces) {
        if (space.hiveExclusive) {
          debugPrint('🔍 Found Hive Exclusive space: ${space.name}');
          hiveExclusiveCount++;
        }
      }
      debugPrint('✅ Found $hiveExclusiveCount spaces with hiveExclusive flag');
      
      final hiveExclusiveSpaces = allSpaces.where((space) => space.hiveExclusive).toList();
      state = AsyncValue.data(hiveExclusiveSpaces);
      
      // Track filter analytics
      _analyticsService.trackSpaceFilter(category, hiveExclusiveSpaces.length);
      return;
    }

    final allSpaces = state.value ?? [];
    final filteredSpaces = allSpaces.where((space) {
      // Convert category to match with SpaceType or tags
      final lowerCategory = category.toLowerCase();

      // Check against space type
      if (lowerCategory.contains('student') &&
          space.spaceType == SpaceType.studentOrg) {
        return true;
      }
      if (lowerCategory.contains('universit') &&
          space.spaceType == SpaceType.universityOrg) {
        return true;
      }
      if (lowerCategory.contains('living') &&
          space.spaceType == SpaceType.campusLiving) {
        return true;
      }
      if ((lowerCategory.contains('frat') || lowerCategory.contains('soror') || lowerCategory.contains('greek')) &&
          space.spaceType == SpaceType.fraternityAndSorority) {
        return true;
      }

      // Check against tags
      final categoryWords = lowerCategory.split(' ');
      for (final word in categoryWords) {
        if (word.length > 3 &&
            space.tags.any((tag) => tag.toLowerCase().contains(word))) {
          return true;
        }
      }

      return false;
    }).toList();

    state = AsyncValue.data(filteredSpaces);

    // Track filter analytics
    _analyticsService.trackSpaceFilter(category, filteredSpaces.length);
  }

  /// View a specific space
  void viewSpace(SpaceEntity space) {
    // Track space view in analytics
    _analyticsService.trackSpaceView(space);
  }

  /// Switch to discover tab
  void switchToDiscoverTab() {
    loadAllSpaces();
    // Track tab change to "Discover"
    _analyticsService.trackTabChange("Discover");
  }

  /// Get category for a space
  String getCategoryForSpace(SpaceEntity space) {
    switch (space.spaceType) {
      case SpaceType.studentOrg:
        return 'Student Organization';
      case SpaceType.universityOrg:
        return 'University';
      case SpaceType.campusLiving:
        return 'Campus Living';
      case SpaceType.fraternityAndSorority:
        return 'Fraternity & Sorority';
      case SpaceType.hiveExclusive:
        return 'HIVE Exclusive';
      case SpaceType.organization:
        return 'Organization';
      case SpaceType.project:
        return 'Project';
      case SpaceType.event:
        return 'Event';
      case SpaceType.community:
        return 'Community';
      case SpaceType.other:
        // Try to determine from tags
        if (space.tags.any((tag) => tag.toLowerCase().contains('academic'))) {
          return 'Academic';
        }
        if (space.tags.any((tag) => tag.toLowerCase().contains('sport'))) {
          return 'Sports';
        }
        if (space.tags.any((tag) =>
            tag.toLowerCase().contains('art') ||
            tag.toLowerCase().contains('music') ||
            tag.toLowerCase().contains('culture'))) {
          return 'Arts';
        }
        if (space.tags.any((tag) => tag.toLowerCase().contains('social'))) {
          return 'Social';
        }
        if (space.tags
            .any((tag) => tag.toLowerCase().contains('professional'))) {
          return 'Professional';
        }
        return 'Other';
    }
  }
}

/// Provider for the SpacesController
final spacesControllerProvider =
    StateNotifierProvider<SpacesController, AsyncValue<List<SpaceEntity>>>(
        (ref) {
  return SpacesController(ref);
});
