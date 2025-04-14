import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/core/error/failures/app_failure_code.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/watchlist_repository.dart';

/// Watchlist-specific failure class
class WatchlistFailure extends AppFailure {
  const WatchlistFailure({
    required String code,
    required String userMessage,
    String? technicalMessage,
    dynamic exception,
  }) : super(
          code: code,
          userMessage: userMessage,
          technicalMessage: technicalMessage ?? userMessage,
          exception: exception,
        );

  /// Factory for creating common watchlist failures
  factory WatchlistFailure.fromCode(
    AppFailureCode code, {
    String? message,
    dynamic exception,
  }) {
    final userMessage = message ?? _getDefaultMessageForCode(code);
    return WatchlistFailure(
      code: code.name,
      userMessage: userMessage,
      technicalMessage: 'Watchlist error: ${code.name} - $userMessage',
      exception: exception,
    );
  }

  /// Helper method to get default message for failure codes
  static String _getDefaultMessageForCode(AppFailureCode code) {
    switch (code) {
      case AppFailureCode.unauthorized:
        return 'You must be signed in to manage your watchlist';
      case AppFailureCode.operationFailed:
        return 'Unable to update watchlist';
      case AppFailureCode.notFound:
        return 'Space not found';
      case AppFailureCode.network:
        return 'Network error, please try again later';
      default:
        return 'An error occurred with the watchlist';
    }
  }
}

/// Firebase implementation of the [WatchlistRepository] interface
class FirebaseWatchlistRepository implements WatchlistRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SpacesDataSource _spacesDataSource;

  /// Collection name for user watchlists
  static const String _watchlistsCollection = 'user_watchlists';
  
  /// Collection name for space watchers
  static const String _spaceWatchersCollection = 'space_watchers';

  /// Constructor
  FirebaseWatchlistRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required SpacesDataSource spacesDataSource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _spacesDataSource = spacesDataSource;

  /// Gets the current user ID or throws an exception if not authenticated
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw WatchlistFailure.fromCode(
        AppFailureCode.unauthorized,
        message: 'You must be signed in to manage your watchlist',
      );
    }
    return user.uid;
  }

  @override
  Future<bool> watchSpace(String spaceId, {String? userId}) async {
    try {
      final uid = userId ?? _getCurrentUserId();
      
      // Get the space to verify it exists
      final space = await _spacesDataSource.getSpaceById(spaceId);
      if (space == null) {
        throw WatchlistFailure.fromCode(
          AppFailureCode.notFound,
          message: 'Space not found',
        );
      }
      
      // Add to user's watchlist
      await _firestore
          .collection(_watchlistsCollection)
          .doc(uid)
          .collection('spaces')
          .doc(spaceId)
          .set({
        'spaceId': spaceId,
        'addedAt': FieldValue.serverTimestamp(),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
      
      // Add to space's watchers list
      await _firestore
          .collection(_spaceWatchersCollection)
          .doc(spaceId)
          .collection('users')
          .doc(uid)
          .set({
        'userId': uid,
        'addedAt': FieldValue.serverTimestamp(),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
      
      // Update the watcher count in the space summary
      await _firestore
          .collection(_spaceWatchersCollection)
          .doc(spaceId)
          .set({
        'watcherCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      debugPrint('Error watching space: $e');
      if (e is WatchlistFailure) {
        rethrow;
      }
      throw WatchlistFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to add space to watchlist',
        exception: e,
      );
    }
  }

  @override
  Future<bool> unwatchSpace(String spaceId, {String? userId}) async {
    try {
      final uid = userId ?? _getCurrentUserId();
      
      // Remove from user's watchlist
      await _firestore
          .collection(_watchlistsCollection)
          .doc(uid)
          .collection('spaces')
          .doc(spaceId)
          .delete();
      
      // Remove from space's watchers list
      await _firestore
          .collection(_spaceWatchersCollection)
          .doc(spaceId)
          .collection('users')
          .doc(uid)
          .delete();
      
      // Update the watcher count in the space summary
      await _firestore
          .collection(_spaceWatchersCollection)
          .doc(spaceId)
          .set({
        'watcherCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      debugPrint('Error unwatching space: $e');
      if (e is WatchlistFailure) {
        rethrow;
      }
      throw WatchlistFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to remove space from watchlist',
        exception: e,
      );
    }
  }

  @override
  Future<bool> isWatchingSpace(String spaceId, {String? userId}) async {
    try {
      final uid = userId ?? _getCurrentUserId();
      
      final docSnapshot = await _firestore
          .collection(_watchlistsCollection)
          .doc(uid)
          .collection('spaces')
          .doc(spaceId)
          .get();
      
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking if watching space: $e');
      // Don't throw here, just return false as a safer default
      return false;
    }
  }

  @override
  Future<List<SpaceEntity>> getWatchedSpaces({String? userId}) async {
    try {
      final uid = userId ?? _getCurrentUserId();
      
      final querySnapshot = await _firestore
          .collection(_watchlistsCollection)
          .doc(uid)
          .collection('spaces')
          .orderBy('lastViewedAt', descending: true)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return [];
      }
      
      // Get all space IDs from the watchlist
      final spaceIds = querySnapshot.docs.map((doc) => doc.id).toList();
      
      // Fetch all space entities in parallel
      final spaces = await Future.wait(
        spaceIds.map((id) async {
          final space = await _spacesDataSource.getSpaceById(id);
          return space?.toEntity();
        }),
      );
      
      // Filter out nulls (spaces that may have been deleted)
      return spaces.whereType<SpaceEntity>().toList();
    } catch (e) {
      debugPrint('Error getting watched spaces: $e');
      if (e is WatchlistFailure) {
        rethrow;
      }
      throw WatchlistFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to retrieve watched spaces',
        exception: e,
      );
    }
  }

  @override
  Future<int> getWatcherCount(String spaceId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_spaceWatchersCollection)
          .doc(spaceId)
          .get();
      
      if (!docSnapshot.exists) {
        return 0;
      }
      
      return (docSnapshot.data()?['watcherCount'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error getting watcher count: $e');
      return 0; // Return 0 instead of throwing to avoid breaking UI
    }
  }

  @override
  Future<List<String>> getSpaceWatchers(String spaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_spaceWatchersCollection)
          .doc(spaceId)
          .collection('users')
          .get();
      
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting space watchers: $e');
      if (e is WatchlistFailure) {
        rethrow;
      }
      throw WatchlistFailure.fromCode(
        AppFailureCode.operationFailed,
        message: 'Failed to retrieve space watchers',
        exception: e,
      );
    }
  }

  @override
  Future<List<SpaceEntity>> getWatchlistRecommendations({
    String? userId,
    int limit = 5,
  }) async {
    try {
      final uid = userId ?? _getCurrentUserId();
      
      // First, get the user's watched spaces
      final watchedSpaces = await getWatchedSpaces(userId: uid);
      
      if (watchedSpaces.isEmpty) {
        // If no watched spaces, return popular spaces as fallback
        final popularSpacesQuery = await _firestore
            .collection('spaces')
            .orderBy('metrics.memberCount', descending: true)
            .limit(limit)
            .get();
        
        final popularSpaceIds = popularSpacesQuery.docs.map((doc) => doc.id).toList();
        
        final popularSpaces = await Future.wait(
          popularSpaceIds.map((id) async {
            final space = await _spacesDataSource.getSpaceById(id);
            return space?.toEntity();
          }),
        );
        
        return popularSpaces.whereType<SpaceEntity>().toList();
      }
      
      // Get the tags from watched spaces
      final watchedTags = watchedSpaces
          .expand((space) => space.tags)
          .toSet()
          .toList();
      
      // Get spaces with similar tags
      // Use a separate collection for recommendations or use the spaces collection directly
      final spacesQuery = await _firestore
          .collection('spaces')
          .where('tags', arrayContainsAny: watchedTags.take(10).toList())
          .limit(limit * 2) // Get more than needed to filter out already watched
          .get();
      
      final recommendedSpaceIds = spacesQuery.docs.map((doc) => doc.id).toList();
      
      // Filter out spaces the user is already watching
      final watchedSpaceIds = watchedSpaces.map((space) => space.id).toSet();
      final filteredRecommendedSpaceIds = recommendedSpaceIds
          .where((id) => !watchedSpaceIds.contains(id))
          .take(limit)
          .toList();
      
      // Fetch the space entities
      final recommendedSpaces = await Future.wait(
        filteredRecommendedSpaceIds.map((id) async {
          final space = await _spacesDataSource.getSpaceById(id);
          return space?.toEntity();
        }),
      );
      
      return recommendedSpaces.whereType<SpaceEntity>().toList();
    } catch (e) {
      debugPrint('Error getting watchlist recommendations: $e');
      // Return empty list instead of throwing to avoid breaking UI
      return [];
    }
  }

  @override
  Stream<List<SpaceEntity>> watchWatchedSpaces({String? userId}) {
    try {
      final uid = userId ?? _getCurrentUserId();
      
      return _firestore
          .collection(_watchlistsCollection)
          .doc(uid)
          .collection('spaces')
          .orderBy('lastViewedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            if (snapshot.docs.isEmpty) {
              return [];
            }
            
            // Get all space IDs from the watchlist
            final spaceIds = snapshot.docs.map((doc) => doc.id).toList();
            
            // Fetch all space entities in parallel
            final spaces = await Future.wait(
              spaceIds.map((id) async {
                final space = await _spacesDataSource.getSpaceById(id);
                return space?.toEntity();
              }),
            );
            
            // Filter out nulls (spaces that may have been deleted)
            return spaces.whereType<SpaceEntity>().toList();
          });
    } catch (e) {
      debugPrint('Error watching watched spaces: $e');
      // Return empty stream in case of error
      return Stream.value([]);
    }
  }

  @override
  Stream<int> watchWatcherCount(String spaceId) {
    return _firestore
        .collection(_spaceWatchersCollection)
        .doc(spaceId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return 0;
          }
          return (snapshot.data()?['watcherCount'] as int?) ?? 0;
        });
  }
} 