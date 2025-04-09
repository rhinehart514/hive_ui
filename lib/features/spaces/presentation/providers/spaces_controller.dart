import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/user_spaces_providers.dart' as user_spaces;
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart' 
  show spaceSearchQueryProvider, spaceSearchActiveProvider, searchedSpacesProvider;

/// State class for spaces page
class SpacesPageState {
  final int currentTabIndex;
  final bool isSearching;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const SpacesPageState({
    this.currentTabIndex = 1,
    this.isSearching = false,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  SpacesPageState copyWith({
    int? currentTabIndex,
    bool? isSearching,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return SpacesPageState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Controller for spaces page
class SpacesController extends StateNotifier<SpacesPageState> {
  final Ref _ref;

  SpacesController(this._ref) : super(const SpacesPageState());

  /// Change tab index
  void changeTab(int index) {
    // Provide haptic feedback for tab change
    HapticFeedback.selectionClick();

    // Update state with new tab index
    state = state.copyWith(currentTabIndex: index);

    // Log analytics event
    AnalyticsService.logEvent(
      'space_tab_changed',
      parameters: {'tab_index': index},
    );
  }

  /// Update search query
  void updateSearchQuery(String query) {
    if (state.searchQuery == query) return;

    state = state.copyWith(
      searchQuery: query,
      isSearching: query.isNotEmpty,
    );

    // Update the search query state provider
    _ref.read(spaceSearchQueryProvider.notifier).state = query;
    // Also update the search active state provider
    _ref.read(spaceSearchActiveProvider.notifier).state = query.isNotEmpty;

    // If query is empty, clear search results
    if (query.isEmpty) {
      _ref.read(spaceSearchProvider.notifier).clear();
      return;
    }

    // Otherwise, search for spaces
    _ref.read(spaceSearchProvider.notifier).search(query);

    // Log search event after a short delay (to avoid logging rapid typing)
    if (query.length > 2) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state.searchQuery == query) {
          AnalyticsService.logEvent(
            'space_search',
            parameters: {'query': query},
          );
        }
      });
    }
  }

  /// Clear search query
  void clearSearch() {
    // Haptic feedback for button press
    HapticFeedback.lightImpact();

    // Clear search state
    state = state.copyWith(searchQuery: '', isSearching: false);

    // Clear the search query state provider
    _ref.read(spaceSearchQueryProvider.notifier).state = '';
    // Update the search active state provider
    _ref.read(spaceSearchActiveProvider.notifier).state = false;

    // Clear search results
    _ref.read(spaceSearchProvider.notifier).clear();
  }

  /// Join a space
  Future<void> joinSpace(Space space) async {
    if (state.isLoading) return;

    // Update loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Haptic feedback for join action
      HapticFeedback.mediumImpact();

      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to join a space');
      }

      // Use the join space provider
      await _ref.read(user_spaces.joinSpaceProvider(space.id))();

      // We need to make sure all providers are synchronized
      debugPrint('Space joined successfully, refreshing all providers');
      
      // Update UserData model for backward compatibility (should already be done via joinSpaceProvider)
      final userData = _ref.read(userProvider);
      if (userData != null && !userData.joinedClubs.contains(space.id)) {
        _ref.read(userProvider.notifier).state = userData.joinClub(space.id);
        debugPrint('Updated UserData.joinedClubs with space ${space.id}');
      }

      // Log analytics event
      AnalyticsService.logEvent(
        'space_joined',
        parameters: {'space_id': space.id, 'space_name': space.name},
      );

      // Reset loading state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error joining space: $e');

      // Update error state
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join space: ${e.toString()}',
      );
    }
  }

  /// Leave a space
  Future<void> leaveSpace(Space space) async {
    if (state.isLoading) return;

    // Update loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Haptic feedback for leave action
      HapticFeedback.mediumImpact();

      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to leave a space');
      }

      // Use the new leave space provider
      await _ref.read(user_spaces.leaveSpaceProvider(space.id))();

      // Log analytics event
      AnalyticsService.logEvent(
        'space_left',
        parameters: {'space_id': space.id, 'space_name': space.name},
      );

      // Reset loading state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error leaving space: $e');

      // Update error state
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to leave space: ${e.toString()}',
      );
    }
  }

  /// Refresh spaces data
  Future<void> refreshSpaces() async {
    // Invalidate providers to trigger refetch
    _ref.invalidate(allSpacesProvider);      // Refresh discoverable spaces
    _ref.invalidate(joinedSpacesProvider);    // Refresh joined spaces
    _ref.invalidate(user_spaces.userSpacesProvider); // User-specific spaces
    // Refresh search results if needed
    _ref.invalidate(searchedSpacesProvider);

    // Log analytics event
    AnalyticsService.logEvent('spaces_refreshed');
  }

  /// Load more spaces
  Future<void> loadMoreSpaces(int page, int limit) async {
    try {
      // Load more spaces from the Firestore collection
      Query query = FirebaseFirestore.instance
          .collectionGroup('spaces')
          .orderBy('metrics.memberCount', descending: true)
          .limit(limit)
          .startAfter([page * limit]);
          
      // Execute the query
      final queryResult = await query.get();
      
      // Process results as needed
      debugPrint('Loaded ${queryResult.docs.length} more spaces');
    } catch (e) {
      debugPrint('Error loading more spaces: $e');
    }
  }

  /// Join a space by code
  Future<bool> joinSpaceByCode(String code) async {
    if (state.isLoading || code.trim().isEmpty) return false;

    // Update loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Haptic feedback for join action
      HapticFeedback.mediumImpact();

      // Validate code format (basic validation)
      if (code.length < 5) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid space code. Please try again.',
        );
        return false;
      }

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to join a space');
      }

      // Find space by code
      final spaceQuery = await FirebaseFirestore.instance
          .collectionGroup('spaces')
          .where('joinCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (spaceQuery.docs.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Space not found. Please check the code and try again.',
        );
        return false;
      }

      // Get space ID from query result
      final spaceDoc = spaceQuery.docs.first;
      final spaceId = spaceDoc.data()['id'] as String? ?? spaceDoc.id;

      // Use the join space provider
      await _ref.read(user_spaces.joinSpaceProvider(spaceId))();

      // Log analytics event
      AnalyticsService.logEvent(
        'space_joined_by_code',
        parameters: {'code': code, 'space_id': spaceId},
      );

      // Reset loading state
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error joining space by code: $e');

      // Update error state
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join space: ${e.toString()}',
      );
      return false;
    }
  }

  /// Create an event in a space
  Future<bool> createEventInSpace(Event event, Space space) async {
    if (state.isLoading) return false;

    // Update loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Haptic feedback for create action
      HapticFeedback.mediumImpact();

      // Save event to Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get user ID from Auth service
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'user123';

      // Create updated attendees list with creator included
      final List<String> attendees = [
        ...event.attendees,
        if (!event.attendees.contains(userId)) userId,
      ];

      // Create event document with all fields
      final Map<String, dynamic> eventData = {
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'startDate': event.startDate.toIso8601String(),
        'endDate': event.endDate.toIso8601String(),
        'organizerEmail': event.organizerEmail,
        'organizerName': event.organizerName,
        'category': event.category,
        'status': event.status,
        'link': event.link,
        'imageUrl': event.imageUrl,
        'tags': event.tags,
        'source': 'club',
        'createdBy': userId,
        'lastModified': DateTime.now().toIso8601String(),
        'visibility': event.visibility,
        'attendees': attendees,
        'spaceId': space.id, // Link to space
        'rsvpCount': attendees.length, // Initialize RSVP count
      };

      // Save event to events collection
      await firestore.collection('events').doc(event.id).set(eventData);

      // Add event ID to space document (root level)
       final collectionPath = _getSpaceCollectionPathByType(space.spaceType);
       if (collectionPath != null) {
          await firestore.collection(collectionPath).doc(space.id).update({
            'eventIds': FieldValue.arrayUnion([event.id]),
            'updatedAt': FieldValue.serverTimestamp(), // Use server timestamp
            'lastActivityAt': FieldValue.serverTimestamp(), // Update last activity
          });
       } else {
         debugPrint("Warning: Could not determine collection path for space type: ${space.spaceType}");
       }

      // Also add to the separate events subcollection in the space (if used)
      // Consider if this duplication is necessary
      // await firestore
      //     .collection(collectionPath)
      //     .doc(space.id)
      //     .collection('events')
      //     .doc(event.id)
      //     .set(eventData);
          
      // Also update the user's rsvpedEvents list since they are the creator
      await firestore.collection('users').doc(userId).update({
        'rsvpedEvents': FieldValue.arrayUnion([event.id]),
      });

      // Log analytics event
      AnalyticsService.logEvent(
        'event_created',
        parameters: {'event_id': event.id, 'space_id': space.id},
      );

      // Refresh relevant providers after event creation
      _ref.invalidate(user_spaces.userSpacesProvider);
      // Potentially invalidate specific space provider if it holds event list
      // _ref.invalidate(spaceProvider(space.id)); 

      // Reset loading state
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error creating event in space: $e');

      // Update error state
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create event: ${e.toString()}',
      );
      return false;
    }
  }

  // Helper to get Firestore collection path (consider moving to a utility class)
  String? _getSpaceCollectionPathByType(SpaceType spaceType) {
    switch (spaceType) {
      case SpaceType.studentOrg:
        return 'spaces/student_organizations/spaces';
      case SpaceType.universityOrg:
        return 'spaces/university/spaces';
      case SpaceType.campusLiving:
        return 'spaces/campus_living/spaces';
      case SpaceType.fraternityAndSorority:
        return 'spaces/greek_life/spaces';
      case SpaceType.hiveExclusive:
        return 'spaces/hive_exclusive/spaces';
      case SpaceType.other:
        return 'spaces/other/spaces';
    }
    // Return null for any unexpected values (though this should never happen)
    return null;
  }
}

/// Provider for spaces controller
final spacesControllerProvider =
    StateNotifierProvider<SpacesController, SpacesPageState>((ref) {
  return SpacesController(ref);
});

/// Helper function to navigate directly to create space page for debugging
void debugNavigateToCreateSpace(BuildContext context) {
  try {
    // Log attempt
    debugPrint('DEBUG: Attempting to navigate to create space page');
    
    // Direct navigation using routes constant
    GoRouter.of(context).push('/spaces/create');
    
    // Log success
    debugPrint('DEBUG: Navigation attempt completed');
  } catch (e) {
    // Log any errors
    debugPrint('DEBUG: Navigation failed with error: $e');
  }
}

// Add a StateNotifier for search functionality
class SpaceSearchNotifier extends StateNotifier<void> {
  final Ref _ref;
  
  SpaceSearchNotifier(this._ref) : super(null);
  
  void search(String query) {
    _ref.read(spaceSearchQueryProvider.notifier).state = query;
    _ref.read(spaceSearchActiveProvider.notifier).state = true;
    // Force a refresh of searchedSpacesProvider
    _ref.invalidate(searchedSpacesProvider);
  }
  
  void clear() {
    _ref.read(spaceSearchQueryProvider.notifier).state = '';
    _ref.read(spaceSearchActiveProvider.notifier).state = false;
    // Force a refresh of searchedSpacesProvider
    _ref.invalidate(searchedSpacesProvider);
  }
}

// Add the provider for our search notifier
final spaceSearchProvider = StateNotifierProvider<SpaceSearchNotifier, void>((ref) {
  return SpaceSearchNotifier(ref);
});
