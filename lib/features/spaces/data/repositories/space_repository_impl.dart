import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/models/event.dart';

import '../../domain/entities/space_entity.dart';
import '../../domain/repositories/space_repository.dart';

/// Implementation of the [SpaceRepository] that uses Firestore
class SpaceRepositoryImpl implements SpaceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// Collection references
  static const String _spacesCollection = 'spaces';
  static const String _usersCollection = 'users';
  static const String _interestsCollection = 'interests';
  static const String _metricsCollection = 'metrics';
  static const String _eventsCollection = 'events';

  /// Constructor with dependency injection
  SpaceRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<bool> createSpace(SpaceEntity space, {File? coverImage}) async {
    try {
      // Upload image if provided
      String? imageUrl;
      if (coverImage != null) {
        final storageRef = _storage
            .ref()
            .child('spaces/${space.id}/cover_${DateTime.now().millisecondsSinceEpoch}');
        
        final uploadTask = storageRef.putFile(coverImage);
        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Prepare space data
      final spaceData = {
        'id': space.id,
        'name': space.name,
        'description': space.description,
        'iconCodePoint': space.iconCodePoint,
        'imageUrl': imageUrl ?? space.imageUrl,
        'bannerUrl': space.bannerUrl,
        'tags': space.tags,
        'isPrivate': space.isPrivate,
        'moderators': space.moderators,
        'admins': space.admins,
        'quickActions': space.quickActions,
        'relatedSpaceIds': space.relatedSpaceIds,
        'createdAt': Timestamp.fromDate(space.createdAt),
        'updatedAt': Timestamp.fromDate(space.updatedAt),
        'spaceType': space.spaceType.index,
        'eventIds': space.eventIds,
        'hiveExclusive': space.hiveExclusive,
        'customData': space.customData,
      };

      // Create space document
      await _firestore.collection(_spacesCollection).doc(space.id).set(spaceData);

      // Create initial metrics
      final metricsData = {
        'spaceId': space.id,
        'memberCount': 0,
        'activeMembers': 0,
        'weeklyEvents': 0,
        'monthlyEngagements': 0,
        'lastActivity': Timestamp.fromDate(DateTime.now()),
        'hasNewContent': false,
        'isTrending': false,
        'activeMembers24h': <String>[],
        'activityScores': <String, int>{},
        'category': SpaceCategory.suggested.index,
        'size': SpaceSize.small.index,
        'engagementScore': 0.0,
      };

      await _firestore
          .collection(_spacesCollection)
          .doc(space.id)
          .collection(_metricsCollection)
          .doc('stats')
          .set(metricsData);

      // Add creator as admin
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection(_usersCollection)
            .doc(currentUser.uid)
            .collection('spaces')
            .doc(space.id)
            .set({
          'role': 'admin',
          'joinedAt': Timestamp.now(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error creating space: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteSpace(String spaceId) async {
    try {
      // Delete space document
      await _firestore.collection(_spacesCollection).doc(spaceId).delete();
      
      // Delete metrics document
      await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_metricsCollection)
          .doc('stats')
          .delete();
      
      // Remove space from user's spaces
      final batch = _firestore.batch();
      final membersSnapshot = await _firestore
          .collectionGroup('spaces')
          .where(FieldPath.documentId, isEqualTo: spaceId)
          .get();
      
      for (final doc in membersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting space: $e');
      return false;
    }
  }

  @override
  Future<bool> addAdmin(String spaceId, String userId) async {
    try {
      // Check if space exists
      final spaceDoc = await _firestore.collection(_spacesCollection).doc(spaceId).get();
      
      if (!spaceDoc.exists) {
        return false;
      }
      
      // Check admin limit
      final data = spaceDoc.data()!;
      final List<dynamic> admins = data['admins'] ?? [];
      
      if (admins.length >= 4) {
        throw SpaceAdminLimitException('Space cannot have more than 4 admins');
      }
      
      // Add user as admin
      await _firestore.collection(_spacesCollection).doc(spaceId).update({
        'admins': FieldValue.arrayUnion([userId]),
      });
      
      // Update user's role in space
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .set({
        'role': 'admin',
        'joinedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      if (e is SpaceAdminLimitException) rethrow;
      debugPrint('Error adding admin: $e');
      return false;
    }
  }

  @override
  Future<bool> createSpaceEvent(String spaceId, String eventId, String creatorId) async {
    try {
      // Check if user is admin
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(creatorId)
          .collection('spaces')
          .doc(spaceId)
          .get();
      
      if (!userDoc.exists || userDoc.data()!['role'] != 'admin') {
        return false;
      }

      // Get the event data from the main events collection
      final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (!eventDoc.exists) {
        return false;
      }

      // Create a batch write to ensure atomicity
      final batch = _firestore.batch();
      
      // Add event to space's events collection with the SAME ID
      final spaceEventRef = _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_eventsCollection)
          .doc(eventId); // Use the same eventId
      
      batch.set(spaceEventRef, {
        ...eventDoc.data()!,
        'spaceId': spaceId,
        'creatorId': creatorId,
      });
      
      // Add event to space's eventIds array
      final spaceRef = _firestore.collection(_spacesCollection).doc(spaceId);
      batch.update(spaceRef, {
        'eventIds': FieldValue.arrayUnion([eventId]),
      });
      
      // Update the main event document to link it to the space
      final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
      batch.update(eventRef, {
        'spaceId': spaceId,
        'creatorId': creatorId,
      });
      
      // Update metrics
      final metricsRef = _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_metricsCollection)
          .doc('stats');
          
      batch.update(metricsRef, {
        'weeklyEvents': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
        'hasNewContent': true,
      });
      
      // Commit all operations atomically
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('Error creating space event: $e');
      return false;
    }
  }

  /// Helper method to sync an event between collections
  Future<void> _syncEventData(String eventId, String spaceId) async {
    try {
      final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (!eventDoc.exists) return;

      final spaceEventRef = _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_eventsCollection)
          .doc(eventId);

      await spaceEventRef.set(eventDoc.data()!);
    } catch (e) {
      debugPrint('Error syncing event data: $e');
    }
  }

  @override
  Future<SpaceEntity?> getSpaceById(String spaceId, {String? spaceType}) async {
    try {
      // Get space document from Firestore
      final spaceDoc = await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .get();

      if (!spaceDoc.exists) {
        // Try using the data source with space type
        final dataSource = SpacesFirestoreDataSource();
        final space = await dataSource.getSpaceById(spaceId, spaceType: spaceType);
        if (space != null) {
          return space.toEntity();
        }
        return null;
      }

      // Convert to SpaceEntity
      final data = spaceDoc.data()!;
      return SpaceEntity(
        id: spaceId,
        name: data['name'] as String,
        description: data['description'] as String? ?? '',
        iconCodePoint: data['iconCodePoint'] as int? ?? Icons.groups.codePoint,
        imageUrl: data['imageUrl'] as String? ?? '',
        bannerUrl: data['bannerUrl'] as String? ?? '',
        tags: List<String>.from(data['tags'] ?? []),
        isPrivate: data['isPrivate'] as bool? ?? false,
        moderators: List<String>.from(data['moderators'] ?? []),
        admins: List<String>.from(data['admins'] ?? []),
        quickActions: Map<String, String>.from(data['quickActions']?.map(
          (key, value) => MapEntry(key as String, value?.toString() ?? ''),
        ) ?? {}),
        relatedSpaceIds: List<String>.from(data['relatedSpaceIds'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        spaceType: SpaceType.values[data['spaceType'] as int? ?? 0],
        eventIds: List<String>.from(data['eventIds'] ?? []),
        hiveExclusive: data['hiveExclusive'] as bool? ?? false,
        customData: Map<String, dynamic>.from(data['customData'] ?? {}),
        metrics: SpaceMetricsEntity(
          spaceId: spaceId,
          memberCount: 0,
          activeMembers: 0,
          weeklyEvents: 0,
          monthlyEngagements: 0,
          lastActivity: DateTime.now(),
          hasNewContent: false,
          isTrending: false,
          activeMembers24h: const [],
          activityScores: const {},
          category: SpaceCategory.suggested,
          size: SpaceSize.small,
          engagementScore: 0.0,
        ),
      );
    } catch (e) {
      debugPrint('Error getting space by ID: $e');
      return null;
    }
  }

  @override
  Future<List<SpaceEntity>> getInvitedSpaces(String userId) async {
    try {
      final invitesSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('invites')
          .get();
      
      final spaces = <SpaceEntity>[];
      for (final invite in invitesSnapshot.docs) {
        final spaceId = invite.id;
        final space = await getSpaceById(spaceId);
        if (space != null) {
          spaces.add(space);
        }
      }
      
      return spaces;
    } catch (e) {
      debugPrint('Error getting invited spaces: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getRecommendedSpaces(String userId) async {
    try {
      // Get user interests
      final interests = await getUserInterests(userId);
      
      // Query spaces based on interests
      final spacesSnapshot = await _firestore
          .collection(_spacesCollection)
          .where('isPrivate', isEqualTo: false)
          .where('tags', arrayContainsAny: interests)
          .limit(10)
          .get();
      
      final List<SpaceEntity> spaces = [];
      for (final doc in spacesSnapshot.docs) {
        final spaceId = doc.id;
        final space = await getSpaceById(spaceId);
        if (space != null) {
          spaces.add(space);
        }
      }
      
      return spaces;
    } catch (e) {
      debugPrint('Error getting recommended spaces: $e');
      return [];
    }
  }

  @override
  Future<SpaceMetrics> getSpaceMetrics(String spaceId) async {
    try {
      final metricsEntity = await _getSpaceMetricsEntity(spaceId);
      
      // Convert SpaceMetricsEntity to SpaceMetrics
      return SpaceMetrics(
        memberCount: metricsEntity.memberCount,
        eventCount: metricsEntity.weeklyEvents,
        activeMembers: metricsEntity.activeMembers,
      );
    } catch (e) {
      debugPrint('Error getting space metrics: $e');
      return const SpaceMetrics(
        memberCount: 0,
        eventCount: 0,
        activeMembers: 0,
      );
    }
  }

  /// Internal method to get detailed metrics entity
  Future<SpaceMetricsEntity> _getSpaceMetricsEntity(String spaceId) async {
    try {
      debugPrint('🔄 Fetching metrics for space: $spaceId');
      
      // Get metrics document
      final metricsDoc = await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_metricsCollection)
          .doc('stats')
          .get();

      if (!metricsDoc.exists) {
        debugPrint('📊 No existing metrics found, calculating from scratch');
        final metrics = await _calculateSpaceMetrics(spaceId);
        
        // Save calculated metrics
        await _firestore
            .collection(_spacesCollection)
            .doc(spaceId)
            .collection(_metricsCollection)
            .doc('stats')
            .set(metrics.toJson());
            
        return metrics;
      }

      final data = metricsDoc.data()!;
      debugPrint('📊 Found existing metrics document');
      
      // Get real-time member count from all possible locations
      final membersQuery = await Future.wait([
        // Check main users collection
        _firestore
            .collection(_usersCollection)
            .where('joinedSpaces', arrayContains: spaceId)
            .count()
            .get(),
        // Check space-specific members subcollection
        _firestore
            .collection(_spacesCollection)
            .doc(spaceId)
            .collection('members')
            .count()
            .get(),
      ]);
      
      // Use the highest count found
      final memberCount = membersQuery
          .map((q) => q.count ?? 0)
          .reduce((max, count) => count > max ? count : max);
      
      debugPrint('👥 Calculated member count: $memberCount');
      
      // Get real-time event count for this week from both locations
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final eventsQuery = await Future.wait([
        // Query main events collection
        _firestore
            .collection(_eventsCollection)
            .where('spaceId', isEqualTo: spaceId)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .count()
            .get(),
            
        // Query space-specific events subcollection
        _firestore
            .collection(_spacesCollection)
            .doc(spaceId)
            .collection(_eventsCollection)
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .count()
            .get(),
      ]);
      
      // Sum up events from both locations
      final totalWeeklyEvents = eventsQuery
          .map((q) => q.count ?? 0)
          .reduce((sum, count) => sum + count);
          
      debugPrint('📅 Calculated weekly events: $totalWeeklyEvents');
      
      // Get active members in last 24h
      final lastDay = now.subtract(const Duration(hours: 24));
      final activeQuery = await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection('activity')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(lastDay))
          .get();
      
      final activeMembers24h = activeQuery.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();

      final activeMembers = activeMembers24h.length;
      debugPrint('👤 Active members in last 24h: $activeMembers');

      // Calculate engagement score
      final engagementScore = _calculateEngagementScore(
        memberCount: memberCount,
        activeMembers: activeMembers,
        weeklyEvents: totalWeeklyEvents,
      );

      // Update metrics in Firestore if they've changed significantly
      if (_shouldUpdateMetrics(data, memberCount, totalWeeklyEvents, activeMembers)) {
        debugPrint('📝 Updating metrics in Firestore due to significant changes');
        await _firestore
            .collection(_spacesCollection)
            .doc(spaceId)
            .collection(_metricsCollection)
            .doc('stats')
            .update({
          'memberCount': memberCount,
          'activeMembers': activeMembers,
          'weeklyEvents': totalWeeklyEvents,
          'lastActivity': Timestamp.now(),
          'engagementScore': engagementScore,
          'activeMembers24h': activeMembers24h,
        });
      }

      return SpaceMetricsEntity(
        spaceId: spaceId,
        memberCount: memberCount,
        activeMembers: activeMembers,
        weeklyEvents: totalWeeklyEvents,
        monthlyEngagements: data['monthlyEngagements'] as int? ?? 0,
        lastActivity: (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
        hasNewContent: data['hasNewContent'] as bool? ?? false,
        isTrending: data['isTrending'] as bool? ?? false,
        activeMembers24h: activeMembers24h,
        activityScores: Map<String, int>.from(data['activityScores'] as Map? ?? {}),
        category: _determineCategory(engagementScore),
        size: _determineSize(memberCount),
        engagementScore: engagementScore,
      );
    } catch (e) {
      debugPrint('❌ Error getting space metrics: $e');
      return SpaceMetricsEntity.initial(spaceId);
    }
  }

  /// Helper method to determine if metrics should be updated
  bool _shouldUpdateMetrics(
    Map<String, dynamic> currentData,
    int newMemberCount,
    int newWeeklyEvents,
    int newActiveMembers,
  ) {
    final currentMemberCount = currentData['memberCount'] as int? ?? 0;
    final currentWeeklyEvents = currentData['weeklyEvents'] as int? ?? 0;
    final currentActiveMembers = currentData['activeMembers'] as int? ?? 0;

    // Update if any metric has changed by more than 5% or absolute difference > 2
    return (newMemberCount - currentMemberCount).abs() > 2 ||
           (newWeeklyEvents - currentWeeklyEvents).abs() > 2 ||
           (newActiveMembers - currentActiveMembers).abs() > 2 ||
           (newMemberCount / (currentMemberCount + 1) > 1.05) ||
           (newWeeklyEvents / (currentWeeklyEvents + 1) > 1.05) ||
           (newActiveMembers / (currentActiveMembers + 1) > 1.05);
  }

  /// Calculate space metrics from scratch
  Future<SpaceMetricsEntity> _calculateSpaceMetrics(String spaceId) async {
    try {
      final now = DateTime.now();
      
      // Get member count
      final membersQuery = await _firestore
          .collection(_usersCollection)
          .where('joinedSpaces', arrayContains: spaceId)
          .count()
          .get();
      
      // Get weekly events
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final eventsQuery = await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_eventsCollection)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .count()
          .get();
      
      // Get active members in last 24h
      final lastDay = now.subtract(const Duration(hours: 24));
      final activeQuery = await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection('activity')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(lastDay))
          .get();
      
      final activeMembers24h = activeQuery.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();

      final memberCount = membersQuery.count ?? 0;
      final weeklyEvents = eventsQuery.count ?? 0;
      final activeMembers = activeMembers24h.length;
      
      // Calculate engagement score based on members and activity
      final engagementScore = _calculateEngagementScore(
        memberCount: memberCount,
        activeMembers: activeMembers,
        weeklyEvents: weeklyEvents,
      );
      
      return SpaceMetricsEntity(
        spaceId: spaceId,
        memberCount: memberCount,
        activeMembers: activeMembers,
        weeklyEvents: weeklyEvents,
        monthlyEngagements: 0, // Will be updated over time
        lastActivity: now,
        hasNewContent: false,
        isTrending: false,
        activeMembers24h: activeMembers24h,
        activityScores: {},
        category: _determineCategory(engagementScore),
        size: _determineSize(memberCount),
        engagementScore: engagementScore,
      );
    } catch (e) {
      debugPrint('Error calculating space metrics: $e');
      return SpaceMetricsEntity.initial(spaceId);
    }
  }

  /// Calculate engagement score based on various metrics
  double _calculateEngagementScore({
    required int memberCount,
    required int activeMembers,
    required int weeklyEvents,
  }) {
    if (memberCount == 0) return 0.0;
    
    // Weight factors
    const double activeWeight = 0.5;
    const double eventsWeight = 0.3;
    const double memberWeight = 0.2;
    
    // Calculate individual scores
    final activeScore = activeMembers / memberCount;
    final eventsScore = weeklyEvents / 10; // Normalize to 0-1 range (10 events/week is max)
    final memberScore = memberCount / 1000; // Normalize to 0-1 range (1000 members is max)
    
    // Calculate weighted average
    return (activeScore * activeWeight) +
           (eventsScore * eventsWeight) +
           (memberScore * memberWeight);
  }

  /// Determine space category based on engagement score
  SpaceCategory _determineCategory(double engagementScore) {
    if (engagementScore >= 0.7) return SpaceCategory.active;
    if (engagementScore >= 0.4) return SpaceCategory.expanding;
    if (engagementScore >= 0.2) return SpaceCategory.emerging;
    return SpaceCategory.suggested;
  }

  /// Determine space size based on member count
  SpaceSize _determineSize(int memberCount) {
    if (memberCount >= 500) return SpaceSize.large;
    if (memberCount >= 100) return SpaceSize.medium;
    return SpaceSize.small;
  }

  @override
  Future<List<String>> getUserInterests(String userId) async {
    try {
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final data = userDoc.data()!;
      return List<String>.from(data['interests'] ?? []);
    } catch (e) {
      debugPrint('Error getting user interests: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getUserSpaces(String userId) async {
    try {
      final userSpacesSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('spaces')
          .get();
      
      final List<SpaceEntity> spaces = [];
      for (final doc in userSpacesSnapshot.docs) {
        final spaceId = doc.id;
        final space = await getSpaceById(spaceId);
        if (space != null) {
          spaces.add(space);
        }
      }
      
      return spaces;
    } catch (e) {
      debugPrint('Error getting user spaces: $e');
      return [];
    }
  }

  @override
  Future<bool> inviteUsers(String spaceId, List<String> userIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        final inviteRef = _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection('invites')
            .doc(spaceId);
        
        batch.set(inviteRef, {
          'invitedAt': Timestamp.now(),
          'status': 'pending',
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error inviting users: $e');
      return false;
    }
  }

  @override
  Future<bool> isSpaceNameAvailable(String name) async {
    try {
      final normalizedName = name.toLowerCase().trim();
      
      final snapshot = await _firestore
          .collection(_spacesCollection)
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking space name: $e');
      return false;
    }
  }

  @override
  Future<bool> joinSpace(String spaceId, String userId) async {
    try {
      // Check if space exists
      final spaceDoc = await _firestore.collection(_spacesCollection).doc(spaceId).get();
      
      if (!spaceDoc.exists) {
        return false;
      }
      
      final data = spaceDoc.data()!;
      final bool isPrivate = data['isPrivate'] ?? false;
      
      // If private, check if user is invited
      if (isPrivate) {
        final inviteDoc = await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection('invites')
            .doc(spaceId)
            .get();
        
        if (!inviteDoc.exists) {
          throw SpaceJoinException('This space is private and requires an invitation');
        }
        
        // Remove invite
        await inviteDoc.reference.delete();
      }
      
      // Add user to space
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .set({
        'role': 'member',
        'joinedAt': Timestamp.now(),
      });
      
      // Update metrics
      await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_metricsCollection)
          .doc('stats')
          .update({
        'memberCount': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      if (e is SpaceJoinException) rethrow;
      debugPrint('Error joining space: $e');
      return false;
    }
  }

  @override
  Future<bool> leaveSpace(String spaceId, String userId) async {
    try {
      // Check if user is admin
      final userSpaceDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .get();
      
      if (!userSpaceDoc.exists) {
        return false;
      }
      
      final isAdmin = userSpaceDoc.data()!['role'] == 'admin';
      
      // If admin, check if there are other admins
      if (isAdmin) {
        final spaceDoc = await _firestore.collection(_spacesCollection).doc(spaceId).get();
        
        if (spaceDoc.exists) {
          final data = spaceDoc.data()!;
          final List<dynamic> admins = data['admins'] ?? [];
          
          if (admins.length <= 1) {
            // Last admin cannot leave without deleting space or transferring ownership
            return false;
          }
          
          // Remove from admins list
          await _firestore.collection(_spacesCollection).doc(spaceId).update({
            'admins': FieldValue.arrayRemove([userId]),
          });
        }
      }
      
      // Remove user from space
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .delete();
      
      // Update metrics
      await _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_metricsCollection)
          .doc('stats')
          .update({
        'memberCount': FieldValue.increment(-1),
        'lastActivity': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error leaving space: $e');
      return false;
    }
  }

  @override
  Future<bool> removeAdmin(String spaceId, String userId) async {
    try {
      // Remove admin role
      await _firestore.collection(_spacesCollection).doc(spaceId).update({
        'admins': FieldValue.arrayRemove([userId]),
      });
      
      // Change user's role to member
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .update({
        'role': 'member',
      });
      
      return true;
    } catch (e) {
      debugPrint('Error removing admin: $e');
      return false;
    }
  }

  @override
  Future<bool> removeInvites(String spaceId, List<String> userIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        final inviteRef = _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection('invites')
            .doc(spaceId);
        
        batch.delete(inviteRef);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error removing invites: $e');
      return false;
    }
  }

  @override
  Future<List<SpaceEntity>> searchSpaces(String query) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();
      
      // Search by name and description
      final nameSnapshot = await _firestore
          .collection(_spacesCollection)
          .where('isPrivate', isEqualTo: false)
          .where('name', isGreaterThanOrEqualTo: normalizedQuery)
          .where('name', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .limit(10)
          .get();
      
      final tagSnapshot = await _firestore
          .collection(_spacesCollection)
          .where('isPrivate', isEqualTo: false)
          .where('tags', arrayContains: normalizedQuery)
          .limit(10)
          .get();
      
      // Combine results
      final results = <String, SpaceEntity>{};
      
      for (final doc in nameSnapshot.docs) {
        final spaceId = doc.id;
        final space = await getSpaceById(spaceId);
        if (space != null) {
          results[spaceId] = space;
        }
      }
      
      for (final doc in tagSnapshot.docs) {
        final spaceId = doc.id;
        if (!results.containsKey(spaceId)) {
          final space = await getSpaceById(spaceId);
          if (space != null) {
            results[spaceId] = space;
          }
        }
      }
      
      return results.values.toList();
    } catch (e) {
      debugPrint('Error searching spaces: $e');
      return [];
    }
  }

  @override
  Future<bool> updateSpace(SpaceEntity space, {File? coverImage}) async {
    try {
      // Upload new image if provided
      String? imageUrl;
      if (coverImage != null) {
        final storageRef = _storage
            .ref()
            .child('spaces/${space.id}/cover_${DateTime.now().millisecondsSinceEpoch}');
        
        final uploadTask = storageRef.putFile(coverImage);
        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Prepare updated data
      final Map<String, dynamic> updateData = {
        'name': space.name,
        'description': space.description,
        'iconCodePoint': space.iconCodePoint,
        'tags': space.tags,
        'isPrivate': space.isPrivate,
        'moderators': space.moderators,
        'admins': space.admins,
        'quickActions': space.quickActions,
        'relatedSpaceIds': space.relatedSpaceIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'spaceType': space.spaceType.index,
        'eventIds': space.eventIds,
        'hiveExclusive': space.hiveExclusive,
        'customData': space.customData,
      };
      
      // Add imageUrl if new one was uploaded
      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }
      
      // Add bannerUrl if provided
      if (space.bannerUrl != null) {
        updateData['bannerUrl'] = space.bannerUrl;
      }
      
      // Update space document
      final docRef = _firestore.collection(_spacesCollection).doc(space.id);
      await docRef.update(updateData);
      
      // Fetch the updated document to ensure we have the latest state
      final updatedDoc = await docRef.get();
      if (!updatedDoc.exists) {
        return false;
      }

      // Update metrics if needed
      await _firestore
          .collection(_spacesCollection)
          .doc(space.id)
          .collection(_metricsCollection)
          .doc('stats')
          .update({
        'lastActivity': Timestamp.now(),
        'hasNewContent': true,
      });

      // Clear any cached data to force a refresh
      final dataSource = SpacesFirestoreDataSource();
      await dataSource.invalidateCache();
      
      return true;
    } catch (e) {
      debugPrint('Error updating space: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified) async {
    try {
      // Check if current user is system admin
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection(_usersCollection).doc(currentUser.uid).get();
      
      if (!userDoc.exists || !(userDoc.data()!['isSystemAdmin'] ?? false)) {
        return false;
      }
      
      // Update verification status
      await _firestore.collection(_spacesCollection).doc(spaceId).update({
        'isVerified': isVerified,
        'verifiedAt': isVerified ? Timestamp.now() : null,
        'verifiedBy': isVerified ? currentUser.uid : null,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating space verification: $e');
      return false;
    }
  }

  @override
  Future<List<SpaceEntity>> getTrendingSpaces() async {
    try {
      // Get spaces with high engagement scores
      final spacesQuery = await _firestore
          .collection(_spacesCollection)
          .where('isPrivate', isEqualTo: false)
          .orderBy('metrics.engagementScore', descending: true)
          .limit(10)
          .get();
      
      // Convert to SpaceEntity objects
      final List<SpaceEntity> spaces = [];
      for (final doc in spacesQuery.docs) {
        final spaceId = doc.id;
        final space = await getSpaceById(spaceId);
        if (space != null) {
          spaces.add(space);
        }
      }
      
      return spaces;
    } catch (e) {
      debugPrint('Error getting trending spaces: $e');
      return [];
    }
  }

  @override
  Future<List<Event>> getSpaceEvents(String spaceId) async {
    try {
      final dataSource = SpacesFirestoreDataSource();
      return await dataSource.getSpaceEvents(spaceId);
    } catch (e) {
      debugPrint('❌ Error in SpaceRepositoryImpl.getSpaceEvents: $e');
      
      // Try fallback approach if data source fails
      try {
        debugPrint('🔄 Trying fallback approach to get events for space: $spaceId');
        final eventsMap = <String, Event>{};
        
        // Try to find which collection the space is in
        final spaceTypes = [
          'student_organizations',
          'university',
          'campus_living',
          'greek_life',
          'hive_exclusive',
          'other'
        ];
        
        for (final spaceType in spaceTypes) {
          // Get events from the space's events subcollection
          final spaceEventsQuery = await _firestore
              .collection('spaces')
              .doc(spaceType)
              .collection('spaces')
              .doc(spaceId)
              .collection(_eventsCollection)
              .get();
          
          if (spaceEventsQuery.docs.isEmpty) {
            debugPrint('No events found in $spaceType collection for space $spaceId');
            continue;
          }
          
          debugPrint('Found ${spaceEventsQuery.docs.length} events in $spaceType collection');
          
          // Helper function to safely convert timestamps to DateTime
          DateTime? safeTimestampToDateTime(dynamic value) {
            if (value == null) return null;
            if (value is Timestamp) return value.toDate();
            if (value is DateTime) return value;
            if (value is String) {
              try {
                return DateTime.parse(value);
              } catch (e) {
                debugPrint('Error parsing date string: $value');
                return null;
              }
            }
            debugPrint('Unhandled date format type: ${value.runtimeType}');
            return null;
          }
          
          // Process each event document
          for (final doc in spaceEventsQuery.docs) {
            if (!eventsMap.containsKey(doc.id)) {
              final data = doc.data();
              if (data != null) {
                // Parse event source
                EventSource source = EventSource.external;
                if (data['source'] != null) {
                  final sourceStr = data['source'].toString().toLowerCase();
                  if (sourceStr == 'user') {
                    source = EventSource.user;
                  } else if (sourceStr == 'club') {
                    source = EventSource.club;
                  }
                }

                eventsMap[doc.id] = Event(
                  id: doc.id,
                  title: data['title'] as String? ?? '',
                  description: data['description'] as String? ?? '',
                  startDate: safeTimestampToDateTime(data['startDate']) ?? DateTime.now(),
                  endDate: safeTimestampToDateTime(data['endDate']) ?? DateTime.now(),
                  location: data['location'] as String? ?? '',
                  organizerEmail: data['organizerEmail'] as String? ?? '',
                  organizerName: data['organizerName'] as String? ?? '',
                  category: data['category'] as String? ?? '',
                  status: data['status'] as String? ?? '',
                  link: data['link'] as String? ?? '',
                  imageUrl: data['imageUrl'] as String? ?? '',
                  source: source,
                  createdBy: data['createdBy'] as String? ?? '',
                  lastModified: safeTimestampToDateTime(data['lastModified']) ?? DateTime.now(),
                  visibility: data['visibility'] as String? ?? 'public',
                  attendees: List<String>.from(data['attendees'] ?? []),
                  spaceId: spaceId,
                );
              }
            }
          }
          
          // If we found events, no need to check other collections
          if (eventsMap.isNotEmpty) {
            debugPrint('Successfully found events in $spaceType collection');
            break;
          }
        }
        
        // Convert to list and sort by start date
        final events = eventsMap.values.toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        
        return events;
      } catch (fallbackError) {
        debugPrint('❌ Fallback approach failed: $fallbackError');
        return [];
      }
    }
  }

  /// Delete an event from both the main events collection and space events subcollection
  Future<bool> deleteSpaceEvent(String spaceId, String eventId) async {
    try {
      final batch = _firestore.batch();

      // Remove from main events collection
      final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
      batch.delete(eventRef);

      // Remove from space's events subcollection
      final spaceEventRef = _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_eventsCollection)
          .doc(eventId);
      batch.delete(spaceEventRef);

      // Remove from space's eventIds array
      final spaceRef = _firestore.collection(_spacesCollection).doc(spaceId);
      batch.update(spaceRef, {
        'eventIds': FieldValue.arrayRemove([eventId]),
      });

      // Update metrics
      final metricsRef = _firestore
          .collection(_spacesCollection)
          .doc(spaceId)
          .collection(_metricsCollection)
          .doc('stats');
          
      batch.update(metricsRef, {
        'weeklyEvents': FieldValue.increment(-1),
        'lastActivity': Timestamp.now(),
      });

      // Commit all operations atomically
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting space event: $e');
      return false;
    }
  }
} 