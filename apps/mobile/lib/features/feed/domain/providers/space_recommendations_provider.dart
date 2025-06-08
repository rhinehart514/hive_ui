import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space_recommendation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/firebase_init_tracker.dart';
import 'package:hive_ui/core/initialization/app_initializer.dart';
import 'package:firebase_core/firebase_core.dart';

/// Provider for space recommendations state with initialization safety
final spaceRecommendationsProvider = StateNotifierProvider<SpaceRecommendationsNotifier, AsyncValue<List<SpaceRecommendation>>>((ref) {
  // Listen to app initialization status to ensure Firebase is ready
  final appInitialized = ref.watch(appInitializationProvider);
  
  return appInitialized.when(
    data: (_) {
      // Create the notifier with proper Firebase instances when initialized
      if (FirebaseInitTracker.isInitialized || Firebase.apps.isNotEmpty) {
        debugPrint('Creating SpaceRecommendationsNotifier with real Firebase');
        return SpaceRecommendationsNotifier(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );
      } else {
        debugPrint('Firebase not initialized for SpaceRecommendationsNotifier. Using placeholder.');
        return _PlaceholderSpaceRecommendationsNotifier();
      }
    },
    loading: () {
      debugPrint('App still initializing. Using placeholder SpaceRecommendationsNotifier.');
      return _PlaceholderSpaceRecommendationsNotifier();
    },
    error: (error, _) {
      debugPrint('App initialization error: $error. Using placeholder SpaceRecommendationsNotifier.');
      return _PlaceholderSpaceRecommendationsNotifier();
    },
  );
});

/// Placeholder implementation for when Firebase is not initialized
class _PlaceholderSpaceRecommendationsNotifier extends StateNotifier<AsyncValue<List<SpaceRecommendation>>> implements SpaceRecommendationsNotifier {
  _PlaceholderSpaceRecommendationsNotifier() : super(AsyncValue.data(_getDefaultRecommendations()));
  
  @override
  FirebaseFirestore get _firestore => throw UnimplementedError();
  
  @override
  FirebaseAuth get _auth => throw UnimplementedError();
  
  DateTime? _lastFetchTimeValue;
  
  @override
  DateTime? get _lastFetchTime => _lastFetchTimeValue;
  
  @override
  set _lastFetchTime(DateTime? value) {
    _lastFetchTimeValue = value;
  }
  
  @override
  Future<void> refresh() async {
    // No-op for placeholder
    state = AsyncValue.data(_getDefaultRecommendations());
  }
  
  @override
  Future<void> _loadRecommendations() async {
    // No-op for placeholder
  }
  
  @override
  Future<List<SpaceRecommendation>> _getRecommendations() async {
    return _getDefaultRecommendations();
  }
  
  @override
  List<SpaceRecommendation> _getRandomRecommendations() {
    return _getDefaultRecommendations();
  }
  
  /// Static method to get default recommendations
  static List<SpaceRecommendation> _getDefaultRecommendations() {
    return [
      const SpaceRecommendation(
        id: 'cs-dept',
        name: 'CS Department',
        description: 'Latest updates from Computer Science',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fcs_dept.jpg?alt=media',
        category: 'Academic',
        memberCount: 450,
      ),
      const SpaceRecommendation(
        id: 'tech-club',
        name: 'Tech Club',
        description: 'Join fellow tech enthusiasts',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Ftech_club.jpg?alt=media',
        category: 'Social',
        memberCount: 200,
      ),
      const SpaceRecommendation(
        id: 'ai-lab',
        name: 'AI Research Lab',
        description: 'Exploring the future of AI',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fai_lab.jpg?alt=media',
        category: 'Research',
        memberCount: 150,
      ),
    ];
  }
}

/// Notifier class for managing space recommendations state
class SpaceRecommendationsNotifier extends StateNotifier<AsyncValue<List<SpaceRecommendation>>> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Cache timeout duration
  static const _cacheDuration = Duration(minutes: 15);
  DateTime? _lastFetchTime;
  
  SpaceRecommendationsNotifier({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth,
        super(const AsyncValue.loading()) {
    // Initial load
    _loadRecommendations();
  }

  /// Load recommendations with caching
  Future<void> _loadRecommendations() async {
    // Return cached data if within cache duration
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        !state.isLoading) {
      return;
    }

    try {
      state = const AsyncValue.loading();
      final recommendations = await _getRecommendations();
      _lastFetchTime = DateTime.now();
      state = AsyncValue.data(recommendations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Force refresh recommendations
  Future<void> refresh() async {
    _lastFetchTime = null;
    await _loadRecommendations();
  }

  /// Get space recommendations based on user activity
  Future<List<SpaceRecommendation>> _getRecommendations() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _getRandomRecommendations();
    }

    try {
      // Query each type collection directly instead of using collectionGroup
      final allSpaces = <SpaceRecommendation>[];
      final spaceTypes = [
        'student_organizations',
        'university',
        'campus_living',
        'greek_life',
        'other',
        'hive_exclusive'
      ];

      // Get user's activity data in parallel
      final futures = await Future.wait([
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('savedEvents')
            .limit(10)
            .get(),
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reposts')
            .limit(10)
            .get(),
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('friends')
            .limit(10)
            .get(),
      ]);

      final userRsvps = futures[0];
      final userReposts = futures[1];
      final userFriends = futures[2];

      // Query each type collection in parallel
      final spaceFutures = spaceTypes.map((type) async {
        try {
          final snapshot = await _firestore
              .collection('spaces')
              .doc(type)
              .collection('spaces')
              .where('isPrivate', isEqualTo: false)
              .limit(10)
              .get();

          return snapshot.docs.map((doc) {
            final data = doc.data();
            if (data['name'] != null && data['description'] != null) {
              return SpaceRecommendation.fromJson({
                ...data,
                'id': doc.id,
                'category': data['category'] ?? type,
                'memberCount': data['memberCount'] ?? 0,
              });
            }
            return null;
          }).whereType<SpaceRecommendation>();
        } catch (e) {
          debugPrint('Error fetching spaces for type $type: $e');
          return <SpaceRecommendation>[];
        }
      });

      // Wait for all space queries to complete
      final spaceResults = await Future.wait(spaceFutures);
      allSpaces.addAll(spaceResults.expand((spaces) => spaces));

      if (allSpaces.isEmpty) {
        debugPrint('No valid spaces found, returning random recommendations');
        return _getRandomRecommendations();
      }

      // Prioritize spaces based on user activity
      final recommendations = <SpaceRecommendation>[];
      final random = Random();

      // Helper function to get relevant spaces or random fallback
      SpaceRecommendation getRelevantOrRandom(
        List<SpaceRecommendation> relevantSpaces,
        bool Function(SpaceRecommendation) isRelevant,
      ) {
        if (relevantSpaces.isNotEmpty) {
          return relevantSpaces[random.nextInt(relevantSpaces.length)];
        }
        return allSpaces[random.nextInt(allSpaces.length)];
      }

      // Add RSVP-based recommendation
      if (userRsvps.docs.isNotEmpty && allSpaces.isNotEmpty) {
        final rsvpSpaces = allSpaces.where((space) {
          return userRsvps.docs.any((rsvp) {
            final eventData = rsvp.data();
            return eventData['spaceId'] == space.id ||
                   eventData['organizerId'] == space.id;
          });
        }).toList();
        recommendations.add(
          getRelevantOrRandom(rsvpSpaces, (s) => true).copyWith(isFromRsvp: true)
        );
      }

      // Add repost-based recommendation
      if (userReposts.docs.isNotEmpty && allSpaces.isNotEmpty) {
        final repostSpaces = allSpaces.where((space) {
          return userReposts.docs.any((repost) {
            final eventData = repost.data();
            return eventData['spaceId'] == space.id ||
                   eventData['originalSpaceId'] == space.id;
          });
        }).toList();
        recommendations.add(
          getRelevantOrRandom(repostSpaces, (s) => true).copyWith(isFromReposts: true)
        );
      }

      // Add friend-based recommendation
      if (userFriends.docs.isNotEmpty && allSpaces.isNotEmpty) {
        final friendSpaces = allSpaces.where((space) {
          return userFriends.docs.any((friend) {
            final friendData = friend.data();
            return space.id == friendData['followedSpaces']?.contains(space.id);
          });
        }).toList();
        recommendations.add(
          getRelevantOrRandom(friendSpaces, (s) => true).copyWith(isFromFriends: true)
        );
      }

      // Fill remaining slots with random recommendations
      while (recommendations.length < 3 && allSpaces.isNotEmpty) {
        final randomSpace = allSpaces[random.nextInt(allSpaces.length)];
        if (!recommendations.any((r) => r.id == randomSpace.id)) {
          recommendations.add(randomSpace);
        }
      }

      return recommendations;
    } catch (e, stackTrace) {
      debugPrint('Error getting space recommendations: $e\n$stackTrace');
      return _getRandomRecommendations();
    }
  }

  /// Get random space recommendations when user is not logged in or there's an error
  List<SpaceRecommendation> _getRandomRecommendations() {
    return [
      const SpaceRecommendation(
        id: 'cs-dept',
        name: 'CS Department',
        description: 'Latest updates from Computer Science',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fcs_dept.jpg?alt=media',
        category: 'Academic',
        memberCount: 450,
      ),
      const SpaceRecommendation(
        id: 'tech-club',
        name: 'Tech Club',
        description: 'Join fellow tech enthusiasts',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Ftech_club.jpg?alt=media',
        category: 'Social',
        memberCount: 200,
      ),
      const SpaceRecommendation(
        id: 'ai-lab',
        name: 'AI Research Lab',
        description: 'Exploring the future of AI',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fai_lab.jpg?alt=media',
        category: 'Research',
        memberCount: 150,
      ),
    ];
  }
} 