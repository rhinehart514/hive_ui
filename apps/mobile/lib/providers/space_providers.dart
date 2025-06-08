import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/organization.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/providers/organization_providers.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

// State class for pagination
class SpacesState {
  final List<Space> spaces;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String? error;

  const SpacesState({
    this.spaces = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });

  SpacesState copyWith({
    List<Space>? spaces,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? error,
  }) {
    return SpacesState(
      spaces: spaces ?? this.spaces,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      error: error ?? this.error,
    );
  }
}

// StateNotifier for paginated spaces
class SpacesNotifier extends StateNotifier<SpacesState> {
  SpacesNotifier() : super(const SpacesState());

  // Load initial spaces batch
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final spaces = await SpaceService.getSpaces();
      final lastDoc = spaces.isNotEmpty
          ? await FirebaseFirestore.instance
              .collection('spaces')
              .doc(spaces.last.id)
              .get()
          : null;

      state = SpacesState(
        spaces: spaces,
        isLoading: false,
        hasMore: spaces.length >= 10,
        lastDocument: lastDoc,
      );
    } catch (e) {
      debugPrint('Error loading spaces: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load spaces: $e',
      );
    }
  }

  // Load more spaces for pagination
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextSpaces = await SpaceService.getSpacesPaginated(
        limit: 10,
        startAfter: state.lastDocument,
      ).then((result) => result.items);

      final lastDoc = nextSpaces.isNotEmpty
          ? await FirebaseFirestore.instance
              .collection('spaces')
              .doc(nextSpaces.last.id)
              .get()
          : state.lastDocument;

      state = state.copyWith(
        spaces: [...state.spaces, ...nextSpaces],
        isLoading: false,
        hasMore: nextSpaces.length >= 10,
        lastDocument: lastDoc,
      );
    } catch (e) {
      debugPrint('Error loading more spaces: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more spaces: $e',
      );
    }
  }

  // Refresh spaces data
  Future<void> refresh() async {
    state = const SpacesState(isLoading: true);
    await loadInitial();
  }

  // Filter spaces by search query
  void filterBySearch(String query) {
    if (query.isEmpty) return;

    final filteredSpaces = state.spaces.where((space) {
      final name = space.name.toLowerCase();
      final description = space.description.toLowerCase();
      final searchLower = query.toLowerCase();

      return name.contains(searchLower) ||
          description.contains(searchLower) ||
          space.tags.any((tag) => tag.toLowerCase().contains(searchLower));
    }).toList();

    // Don't update the lastDocument or hasMore since this is just a filter
    state = state.copyWith(spaces: filteredSpaces);
  }
}

/// Provider for paginated spaces state
final spacesStateProvider =
    StateNotifierProvider<SpacesNotifier, SpacesState>((ref) {
  return SpacesNotifier();
});

/// Provider for all spaces
final spacesProvider = FutureProvider<List<Space>>((ref) async {
  try {
    final List<Space> spaces = [];
    final Set<String> processedIds = {};

    // Get organizations from RSS feed
    final organizations = await ref.watch(organizationsProvider.future);

    // Get clubs directly from the ClubService to ensure we get all clubs
    final clubs = ClubService.getAllExtractedClubs();

    // Get user data to check for joined clubs
    final userData = ref.watch(userProvider);
    final joinedClubIds = userData?.joinedClubs ?? [];

    // 1. From organizations
    for (final org in organizations) {
      if (processedIds.contains(org.id)) continue;

      final engagementScore = _calculateEngagementScore(org);
      final hasNewContent = _hasNewContent(org);
      final isTrending = _isTrending(org);
      final size = _determineSpaceSize(org, engagementScore);
      final isJoined = joinedClubIds.contains(org.id);

      final metrics = SpaceMetrics(
        spaceId: org.id,
        memberCount: org.memberCount,
        activeMembers: (org.memberCount * 0.3).round(),
        weeklyEvents: org.eventCount ~/ 4,
        monthlyEngagements: org.followersCount,
        lastActivity: org.updatedAt,
        hasNewContent: hasNewContent,
        isTrending: isTrending,
        activeMembers24h: const [],
        activityScores: const {},
        category:
            _determineSpaceCategory(engagementScore, hasNewContent, isTrending),
        size: size,
        engagementScore: engagementScore,
        isTimeSensitive: false,
        connectedFriends: const [],
      );

      final space = Space(
        id: org.id,
        name: org.name,
        description: org.description,
        icon: org.icon,
        imageUrl: org.imageUrl,
        bannerUrl: org.bannerUrl,
        metrics: metrics,
        organization: org,
        tags: [...org.categories, ...org.tags],
        createdAt: org.createdAt,
        updatedAt: org.updatedAt,
        isJoined: isJoined,
      );

      spaces.add(space);
      processedIds.add(org.id);
    }

    // 2. From clubs
    for (final club in clubs) {
      if (processedIds.contains(club.id)) continue;

      final isJoined = joinedClubIds.contains(club.id);
      final clubAsOrg = _convertClubToOrganization(club);
      final engagementScore = _calculateClubEngagementScore(club);
      final hasNewContent = _hasNewContent(clubAsOrg);
      final isTrending = club.isFeatured;
      final size = _determineClubSize(club);

      final metrics = SpaceMetrics(
        spaceId: club.id,
        memberCount: club.memberCount,
        activeMembers: (club.memberCount * 0.3).round(),
        weeklyEvents: club.eventCount ~/ 4,
        monthlyEngagements: club.followersCount,
        lastActivity: club.updatedAt,
        hasNewContent: hasNewContent,
        isTrending: isTrending,
        activeMembers24h: const [],
        activityScores: const {},
        category:
            _determineSpaceCategory(engagementScore, hasNewContent, isTrending),
        size: size,
        engagementScore: engagementScore,
        isTimeSensitive: false,
        connectedFriends: const [],
      );

      final space = Space(
        id: club.id,
        name: club.name,
        description: club.description,
        icon: club.icon,
        imageUrl: club.imageUrl,
        bannerUrl: club.bannerUrl,
        metrics: metrics,
        organization: clubAsOrg,
        tags: [...club.categories, ...club.tags],
        createdAt: club.createdAt,
        updatedAt: club.updatedAt,
        isJoined: isJoined,
      );

      spaces.add(space);
      processedIds.add(club.id);
    }

    return spaces;
  } catch (e) {
    debugPrint('Error loading spaces: $e');
    return [];
  }
});

/// Provider for streaming a specific space (real-time updates)
final spaceStreamProvider =
    StreamProvider.family<Space?, String>((ref, spaceId) {
  return SpaceService.streamSpace(spaceId);
});

/// Provider for user-joined spaces
final userSpacesProvider = FutureProvider<List<Space>>((ref) async {
  try {
    final userData = ref.watch(userProvider);

    // If no user data, return empty list
    if (userData == null) {
      debugPrint('⚠️ userSpacesProvider - No user data available');
      return [];
    }
    
    // Get the user's joined clubs
    final joinedClubs = userData.joinedClubs;
    
    if (joinedClubs.isEmpty) {
      debugPrint('⚠️ userSpacesProvider - User has no joined clubs');
      return [];
    }
    
    debugPrint('🔍 userSpacesProvider - Fetching ${joinedClubs.length} spaces for user ${userData.id}');
    
    // Remove duplicate IDs in the input - this prevents requesting duplicates
    final uniqueSpaceIds = joinedClubs.toSet().toList();
    if (uniqueSpaceIds.length < joinedClubs.length) {
      debugPrint('⚠️ userSpacesProvider - Found ${joinedClubs.length - uniqueSpaceIds.length} duplicate space IDs in joinedClubs');
    }
    
    // Get spaces that the user has joined (now with deduplicated IDs)
    final joinedSpaces = await SpaceService.getUserSpaces(uniqueSpaceIds);
    
    // Additional filtering to ensure there are no duplicates in the result,
    // even if the service somehow returned duplicates
    final Map<String, Space> uniqueSpaces = {};
    for (final space in joinedSpaces) {
      uniqueSpaces[space.id] = space;
    }
    
    // Check if we got all spaces
    if (uniqueSpaces.length < uniqueSpaceIds.length) {
      final retrievedIds = uniqueSpaces.keys.toSet();
      final missingIds = uniqueSpaceIds.where((id) => !retrievedIds.contains(id)).toList();
      
      debugPrint('⚠️ userSpacesProvider - Missing ${missingIds.length} spaces: $missingIds');
      
      // Try to fetch user followedSpaces field to fill in missing data
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userData.id)
            .get();
            
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          
          if (data['followedSpaces'] != null && data['followedSpaces'] is List) {
            final followedSpaces = List<String>.from(data['followedSpaces']);
            // Use Set operations to avoid duplicates
            final additionalSpaceIds = followedSpaces.where((id) => 
              !retrievedIds.contains(id) && uniqueSpaceIds.contains(id)).toList();
            
            if (additionalSpaceIds.isNotEmpty) {
              debugPrint('🔍 userSpacesProvider - Trying to fetch ${additionalSpaceIds.length} additional spaces from followedSpaces');
              final additionalSpaces = await SpaceService.getUserSpaces(additionalSpaceIds);
              
              // Use our map to avoid duplicates when adding
              for (final space in additionalSpaces) {
                uniqueSpaces[space.id] = space;
              }
              
              debugPrint('➕ userSpacesProvider - Added ${additionalSpaces.length} spaces from followedSpaces');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ userSpacesProvider - Error fetching additional spaces: $e');
      }
    }
    
    // Convert map back to list for final result
    final result = uniqueSpaces.values.toList();
    
    // Sort spaces by most active first
    result.sort((a, b) {
      // Sort by trending status first
      if (a.metrics.isTrending != b.metrics.isTrending) {
        return a.metrics.isTrending ? -1 : 1;
      }
      
      // Then by engagement score
      return b.metrics.engagementScore.compareTo(a.metrics.engagementScore);
    });
    
    debugPrint('✅ userSpacesProvider - Returning ${result.length} unique spaces (filtered from ${joinedClubs.length} total IDs)');
    return result;
  } catch (e, stack) {
    debugPrint('❌ userSpacesProvider - Error: $e\n$stack');
    throw Exception('Failed to load user spaces: $e');
  }
});

/// Provider for a specific space by ID (non-streaming version)
final spaceByIdProvider = Provider.family<Space?, String>((ref, spaceId) {
  final spaces = ref.watch(spacesProvider).value ?? [];
  try {
    return spaces.firstWhere((space) => space.id == spaceId);
  } catch (_) {
    // If not found in the loaded spaces, return null
    // The UI can then decide to fetch it directly
    return null;
  }
});

/// Provider for spaces filtered by category
final spacesByCategoryProvider =
    FutureProvider.family<List<Space>, String>((ref, category) async {
  return SpaceService.getSpacesByCategory(category);
});

/// Provider for trending spaces
final trendingSpacesProvider = FutureProvider<List<Space>>((ref) async {
  return SpaceService.getTrendingSpaces();
});

/// Provider to toggle space membership (join/leave)
final toggleSpaceMembershipProvider =
    Provider.family<void, String>((ref, spaceId) {
  final userData = ref.read(userProvider);

  if (userData != null) {
    final isCurrentlyJoined = userData.joinedClubs.contains(spaceId);

    // Update user data
    if (isCurrentlyJoined) {
      // Leave the space
      ref.read(userProvider.notifier).leaveClub(spaceId);
      debugPrint('Left space: $spaceId');
    } else {
      // Join the space
      ref.read(userProvider.notifier).joinClub(spaceId);
      debugPrint('Joined space: $spaceId');
    }

    // Update cached join status in Firestore
    SpaceService.updateJoinStatus(
      spaceId: spaceId,
      isJoined: !isCurrentlyJoined,
      userId: userData.id ?? 'anonymous',
    );
  }

  // Invalidate providers to trigger UI updates
  ref.invalidate(userSpacesProvider);
});

/// Provider for profile-based recommendations
final profileBasedRecommendationsProvider =
    FutureProvider<List<Space>>((ref) async {
  final userData = ref.watch(userProvider);
  final userSpaces = await ref.watch(userSpacesProvider.future);

  // If no user data available, fall back to trending spaces
  if (userData == null) {
    return SpaceService.getTrendingSpaces(limit: 8);
  }

  // Get all spaces to filter and score
  final allSpaces = await ref.watch(spacesProvider.future);

  // Extract user interests and tags from joined spaces
  final userInterests = userData.interests;
  final joinedSpaceIds = userData.joinedClubs;
  final List<String> userSpaceTags =
      userSpaces.expand((space) => space.tags).toList();

  // Score each space based on relevance to user
  final scoredSpaces = allSpaces.where((space) {
    // Skip already joined spaces
    return !joinedSpaceIds.contains(space.id);
  }).map((space) {
    // Calculate a score based on match with user preferences
    double score = 0.0;

    // Interest matching (up to 40 points)
    final spaceKeywords = {
      ...space.tags,
      ...space.description.toLowerCase().split(' '),
      if (space.organization?.category != null)
        space.organization!.category.toLowerCase(),
    };

    // Count matches with user interests
    int interestMatches = 0;
    for (final interest in userInterests) {
      if (spaceKeywords.any((keyword) =>
          keyword.toLowerCase().contains(interest.toLowerCase()) ||
          interest.toLowerCase().contains(keyword))) {
        interestMatches++;
      }
    }

    // Add interest match score
    if (userInterests.isNotEmpty) {
      score += (interestMatches / userInterests.length) * 40;
    }

    // Similar to joined spaces (up to 30 points)
    int similarityCount = 0;
    for (final tag in userSpaceTags) {
      if (spaceKeywords.any((keyword) =>
          keyword.toLowerCase() == tag.toLowerCase() ||
          keyword.toLowerCase().contains(tag.toLowerCase()))) {
        similarityCount++;
      }
    }

    // Add similarity score (capped at 5 matches)
    if (userSpaceTags.isNotEmpty) {
      score += (math.min(similarityCount, 5) / 5) * 30;
    }

    // Trending bonus (up to 30 points)
    if (space.metrics.isTrending) {
      score += 30;
    }

    return (space, score);
  }).toList();

  // Sort by score and return top spaces
  scoredSpaces.sort((a, b) => b.$2.compareTo(a.$2));

  // Return top recommendations
  return scoredSpaces.take(8).map((tuple) => tuple.$1).toList();
});

// Indicator for whether spaces have been migrated to Firestore
final spaceMigrationCompleteProvider = StateProvider<bool>((ref) => false);

// Provider to trigger migration of spaces to Firestore
final migrateSpacesToFirestoreProvider = FutureProvider<bool>((ref) async {
  try {
    // First check if migration has already been done
    if (ref.read(spaceMigrationCompleteProvider)) {
      return true;
    }

    debugPrint('Starting migration of spaces to Firestore...');

    // Get existing spaces from RSS and club services
    final List<Space> existingSpaces = [];

    // 1. From organizations
    final organizations = await ref.watch(organizationsProvider.future);
    final userData = ref.watch(userProvider);
    final joinedClubIds = userData?.joinedClubs ?? [];

    for (final org in organizations) {
      final engagementScore = _calculateEngagementScore(org);
      final hasNewContent = _hasNewContent(org);
      final isTrending = _isTrending(org);
      final size = _determineSpaceSize(org, engagementScore);
      final isJoined = joinedClubIds.contains(org.id);

      final metrics = SpaceMetrics(
        spaceId: org.id,
        memberCount: org.memberCount,
        activeMembers: (org.memberCount * 0.3).round(),
        weeklyEvents: org.eventCount ~/ 4,
        monthlyEngagements: org.followersCount,
        lastActivity: org.updatedAt,
        hasNewContent: hasNewContent,
        isTrending: isTrending,
        activeMembers24h: const [],
        activityScores: const {},
        category:
            _determineSpaceCategory(engagementScore, hasNewContent, isTrending),
        size: size,
        engagementScore: engagementScore,
        isTimeSensitive: false,
        connectedFriends: const [],
      );

      final space = Space(
        id: org.id,
        name: org.name,
        description: org.description,
        icon: org.icon,
        imageUrl: org.imageUrl,
        bannerUrl: org.bannerUrl,
        metrics: metrics,
        organization: org,
        tags: [...org.categories, ...org.tags],
        createdAt: org.createdAt,
        updatedAt: org.updatedAt,
        isJoined: isJoined,
      );

      existingSpaces.add(space);
    }

    // 2. From clubs
    final clubs = ClubService.getAllExtractedClubs();
    final processedIds = existingSpaces.map((s) => s.id).toSet();

    for (final club in clubs) {
      if (processedIds.contains(club.id)) continue;

      final isJoined = joinedClubIds.contains(club.id);
      final clubAsOrg = _convertClubToOrganization(club);
      final engagementScore = _calculateClubEngagementScore(club);
      final hasNewContent = _hasNewContent(clubAsOrg);
      final isTrending = club.isFeatured;
      final size = _determineClubSize(club);

      final metrics = SpaceMetrics(
        spaceId: club.id,
        memberCount: club.memberCount,
        activeMembers: (club.memberCount * 0.3).round(),
        weeklyEvents: club.eventCount ~/ 4,
        monthlyEngagements: club.followersCount,
        lastActivity: club.updatedAt,
        hasNewContent: hasNewContent,
        isTrending: isTrending,
        activeMembers24h: const [],
        activityScores: const {},
        category:
            _determineSpaceCategory(engagementScore, hasNewContent, isTrending),
        size: size,
        engagementScore: engagementScore,
        isTimeSensitive: false,
        connectedFriends: const [],
      );

      final space = Space(
        id: club.id,
        name: club.name,
        description: club.description,
        icon: club.icon,
        imageUrl: club.imageUrl,
        bannerUrl: club.bannerUrl,
        metrics: metrics,
        organization: clubAsOrg,
        tags: [...club.categories, ...club.tags],
        createdAt: club.createdAt,
        updatedAt: club.updatedAt,
        isJoined: isJoined,
      );

      existingSpaces.add(space);
    }

    // Save spaces to Firestore
    debugPrint('Migrating ${existingSpaces.length} spaces to Firestore...');

    // Use batching for better performance (Firestore allows max 500 operations per batch)
    final batch = FirebaseFirestore.instance.batch();
    int count = 0;
    int batchCount = 0;

    for (final space in existingSpaces) {
      try {
        final docRef =
            FirebaseFirestore.instance.collection('spaces').doc(space.id);
        batch.set(docRef, {
          'id': space.id,
          'name': space.name,
          'description': space.description,
          'icon':
              '${space.icon.codePoint},${space.icon.fontFamily},${space.icon.fontPackage}',
          'imageUrl': space.imageUrl,
          'bannerUrl': space.bannerUrl,
          'tags': space.tags,
          'customData': space.customData,
          'isPrivate': space.isPrivate,
          'isJoined': space.isJoined,
          'moderators': space.moderators,
          'admins': space.admins,
          'quickActions': space.quickActions,
          'relatedSpaceIds': space.relatedSpaceIds,
          'createdAt': Timestamp.fromDate(space.createdAt),
          'updatedAt': Timestamp.fromDate(space.updatedAt),
          'organization': space.organization != null
              ? {
                  'id': space.organization!.id,
                  'name': space.organization!.name,
                  'isVerified': space.organization!.isVerified,
                  'isOfficial': space.organization!.isOfficial,
                }
              : null,
          'metrics': {
            'spaceId': space.metrics.spaceId,
            'memberCount': space.metrics.memberCount,
            'activeMembers': space.metrics.activeMembers,
            'weeklyEvents': space.metrics.weeklyEvents,
            'monthlyEngagements': space.metrics.monthlyEngagements,
            'lastActivity': Timestamp.fromDate(space.metrics.lastActivity),
            'hasNewContent': space.metrics.hasNewContent,
            'isTrending': space.metrics.isTrending,
            'engagementScore': space.metrics.engagementScore,
            'isTimeSensitive': space.metrics.isTimeSensitive,
            'size': space.metrics.size.toString().split('.').last,
            'category': space.metrics.category.toString().split('.').last,
          },
        });

        count++;

        // Commit in batches of 400 to stay under Firestore limits
        if (count % 400 == 0) {
          await batch.commit();
          batchCount++;
          debugPrint('Batch $batchCount committed with 400 spaces');
        }
      } catch (e) {
        debugPrint('Error migrating space ${space.id}: $e');
      }
    }

    // Commit any remaining operations
    if (count % 400 != 0) {
      await batch.commit();
      batchCount++;
      debugPrint('Final batch committed with ${count % 400} spaces');
    }

    debugPrint(
        'Migration complete! Migrated $count spaces in $batchCount batches');

    // Mark migration as complete
    ref.read(spaceMigrationCompleteProvider.notifier).state = true;

    return true;
  } catch (e) {
    debugPrint('Error during space migration: $e');
    return false;
  }
});

// Keep these helper methods for use during migration
double _calculateEngagementScore(Organization org) {
  // Existing implementation kept for migration
  double score = 0;
  score += (org.memberCount / 1000).clamp(0, 40);
  final followerRatio =
      org.followersCount / (org.memberCount > 0 ? org.memberCount : 1);
  score += (followerRatio * 30).clamp(0, 30);
  final daysSinceUpdate = DateTime.now().difference(org.updatedAt).inDays;
  score += ((30 - daysSinceUpdate) / 1.5).clamp(0, 20);
  if (org.isOfficial) score += 5;
  if (org.isVerified) score += 5;
  return score.clamp(0, 100);
}

double _calculateClubEngagementScore(Club club) {
  // Existing implementation kept for migration
  double score = 0;
  score += (club.memberCount / 1000).clamp(0, 40);
  score += (club.eventCount * 3).clamp(0, 30);
  final daysSinceUpdate = DateTime.now().difference(club.updatedAt).inDays;
  score += ((30 - daysSinceUpdate) / 1.5).clamp(0, 20);
  if (club.isOfficial) score += 5;
  if (club.isVerified) score += 5;
  return score.clamp(0, 100);
}

bool _hasNewContent(Organization org) {
  // Existing implementation kept for migration
  final hoursSinceUpdate = DateTime.now().difference(org.updatedAt).inHours;
  return hoursSinceUpdate <= 48;
}

bool _isTrending(Organization org) {
  // Existing implementation kept for migration
  final engagementScore = _calculateEngagementScore(org);
  final daysSinceUpdate = DateTime.now().difference(org.updatedAt).inDays;
  return engagementScore >= 70 &&
      daysSinceUpdate <= 7 &&
      org.followersCount >= 500;
}

SpaceSize _determineSpaceSize(Organization org, double engagementScore) {
  // Existing implementation kept for migration
  if ((org.isOfficial && org.isVerified) ||
      engagementScore >= 70 ||
      org.followersCount >= 1000) {
    return SpaceSize.large;
  }
  if (org.isOfficial || engagementScore >= 40 || org.followersCount >= 500) {
    return SpaceSize.medium;
  }
  return SpaceSize.small;
}

SpaceSize _determineClubSize(Club club) {
  // Existing implementation kept for migration
  if ((club.isVerified && club.isOfficial) ||
      (club.isFeatured && club.eventCount >= 5)) {
    return SpaceSize.large;
  }
  if (club.isOfficial || club.eventCount >= 3 || club.memberCount >= 50) {
    return SpaceSize.medium;
  }
  return SpaceSize.small;
}

Organization _convertClubToOrganization(Club club) {
  // Existing implementation kept for migration
  return Organization(
    id: club.id,
    name: club.name,
    description: club.description,
    category: club.category,
    memberCount: club.memberCount,
    status: club.status,
    icon: club.icon,
    imageUrl: club.imageUrl,
    createdAt: club.createdAt,
    updatedAt: club.updatedAt,
    logoUrl: club.logoUrl,
    bannerUrl: club.bannerUrl,
    website: club.website,
    email: club.email,
    location: club.location,
    categories: club.categories,
    tags: club.tags,
    eventCount: club.eventCount,
    isVerified: club.isVerifiedPlus,
    isOfficial: club.isOfficial,
    foundedYear: club.foundedYear?.toString(),
    mission: club.mission,
    leaders: club.leaders.values.toList(),
    followersCount: club.followersCount,
  );
}

SpaceCategory _determineSpaceCategory(
    double engagementScore, bool hasNewContent, bool isTrending) {
  // Existing implementation kept for migration
  if (engagementScore >= 70) return SpaceCategory.active;
  if (engagementScore >= 40) return SpaceCategory.expanding;
  if (isTrending || hasNewContent) return SpaceCategory.emerging;
  return SpaceCategory.suggested;
}
