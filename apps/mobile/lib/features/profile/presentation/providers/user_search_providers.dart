import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Provider for the current search filters
final userSearchFiltersProvider = StateProvider<UserSearchFilters>((ref) {
  return const UserSearchFilters();
});

/// Provider for the search results
final userSearchResultsProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final filters = ref.watch(userSearchFiltersProvider);
  
  // Get the query parameters
  final queryParams = filters.toQueryParams();
  
  try {
    // TODO: Implement actual search using Firebase
    // For now return mock data
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    
    // Filter mock data based on activity level and shared metrics
    final mockUsers = [
      UserProfile(
        id: '1',
        username: 'johndoe',
        displayName: 'John Doe',
        bio: 'Computer Science student',
        major: 'Computer Science',
        year: 'Junior',
        residence: 'North Campus',
        eventCount: 5,
        spaceCount: 3,
        friendCount: 12,
        activityLevel: 85,
        sharedSpaces: 2,
        sharedEvents: 3,
        createdAt: now,
        updatedAt: now,
        interests: const ['Programming', 'AI', 'Mobile Apps'],
        isVerified: true,
        profileImageUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      UserProfile(
        id: '2',
        username: 'janesmith',
        displayName: 'Jane Smith',
        bio: 'Psychology major',
        major: 'Psychology',
        year: 'Senior',
        residence: 'South Campus',
        eventCount: 8,
        spaceCount: 4,
        friendCount: 20,
        activityLevel: 92,
        sharedSpaces: 1,
        sharedEvents: 2,
        createdAt: now,
        updatedAt: now,
        interests: const ['Research', 'Mental Health', 'Neuroscience'],
        isVerified: false,
        profileImageUrl: 'https://i.pravatar.cc/150?img=2',
      ),
    ];

    return mockUsers.where((user) {
      // Apply activity level filter
      if (filters.minActivityLevel != null &&
          user.activityLevel < filters.minActivityLevel!) {
        return false;
      }

      // Apply shared spaces filter
      if (filters.minSharedSpaces != null &&
          user.sharedSpaces < filters.minSharedSpaces!) {
        return false;
      }

      // Apply shared events filter
      if (filters.minSharedEvents != null &&
          user.sharedEvents < filters.minSharedEvents!) {
        return false;
      }

      return true;
    }).toList();
  } catch (e) {
    return [];
  }
});

/// Provider for the loading state
final isSearchingProvider = StateProvider<bool>((ref) => false);

/// Provider for any search errors
final searchErrorProvider = StateProvider<String?>((ref) => null); 