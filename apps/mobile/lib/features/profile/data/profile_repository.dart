import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/conflict_resolver.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:uuid/uuid.dart';

// User profile model
class UserProfile {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  UserProfile({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.bio,
    required this.interests,
    required this.createdAt,
    this.updatedAt,
  });
  
  // Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final interests = <String>[];
    if (data['interests'] != null) {
      interests.addAll((data['interests'] as List).cast<String>());
    }
    
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'] ?? 'New User',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      interests: interests,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }
  
  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }
  
  // Create a copy with updated fields
  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Repository for user profile data with offline support
class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CacheManager _cacheManager;
  final AppEventBus _eventBus;
  final OfflineQueueManager _offlineQueueManager;
  final ConnectivityService _connectivityService;
  
  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required CacheManager cacheManager,
    required AppEventBus eventBus,
    required OfflineQueueManager offlineQueueManager,
    required ConnectivityService connectivityService,
  }) : 
    _firestore = firestore,
    _auth = auth,
    _cacheManager = cacheManager,
    _eventBus = eventBus,
    _offlineQueueManager = offlineQueueManager,
    _connectivityService = connectivityService {
    _registerOfflineHandlers();
  }
  
  // Register offline action handlers
  void _registerOfflineHandlers() {
    _offlineQueueManager.registerExecutor(
      'profile',
      _executeProfileAction,
      remoteFetcher: _fetchRemoteProfile,
      conflictStrategy: ConflictStrategy.preferRecent,
    );
  }
  
  // Execute a profile action when online
  Future<bool> _executeProfileAction(OfflineAction action) async {
    try {
      final profileId = action.resourceId!;
      final data = action.payload;
      
      switch (action.type) {
        case OfflineActionType.update:
          await _firestore.collection('users').doc(profileId).update(data);
          // Invalidate cache after successful update
          _cacheManager.invalidateCache('user:$profileId');
          _cacheManager.invalidateCache('user:$profileId:profile');
          // Emit event for profile update
          _eventBus.emit(ProfileUpdatedEvent(
            userId: profileId,
            updates: data,
          ));
          return true;
          
        default:
          debugPrint('⚠️ Unsupported action type: ${action.type}');
          return false;
      }
    } catch (e) {
      debugPrint('⚠️ Error executing profile action: $e');
      return false;
    }
  }
  
  // Fetch remote profile data for conflict resolution
  Future<Map<String, dynamic>?> _fetchRemoteProfile(OfflineAction action) async {
    try {
      final profileId = action.resourceId!;
      final doc = await _firestore.collection('users').doc(profileId).get();
      
      if (doc.exists) {
        return doc.data();
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ Error fetching remote profile: $e');
      return null;
    }
  }
  
  // Get user profile
  Future<UserProfile?> getProfile({String? userId}) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        debugPrint('⚠️ No user ID provided and no user is logged in');
        return null;
      }
      
      // Check cache first
      return await _cacheManager.getOrCompute<UserProfile?>(
        'user:$uid:profile',
        () async {
          final doc = await _firestore.collection('users').doc(uid).get();
          
          if (doc.exists) {
            return UserProfile.fromFirestore(doc);
          }
          
          return null;
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error getting profile: $e');
      return null;
    }
  }
  
  // Update user profile with offline support
  Future<void> updateProfile(Map<String, dynamic> updates, {String? userId}) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        throw Exception('No user ID provided and no user is logged in');
      }
      
      // Add updated_at timestamp if not included
      final updatedData = Map<String, dynamic>.from(updates);
      if (!updatedData.containsKey('updatedAt')) {
        updatedData['updatedAt'] = FieldValue.serverTimestamp();
      }
      
      // Check if we're online
      if (_connectivityService.hasConnectivity) {
        // We're online, update directly
        await _firestore.collection('users').doc(uid).update(updatedData);
        
        // Invalidate cache
        _cacheManager.invalidateCache('user:$uid');
        _cacheManager.invalidateCache('user:$uid:profile');
        
        // Emit event for profile update
        _eventBus.emit(ProfileUpdatedEvent(
          userId: uid,
          updates: updatedData,
        ));
      } else {
        // We're offline, queue the update for later
        final actionId = const Uuid().v4();
        
        final action = OfflineAction(
          id: actionId,
          type: OfflineActionType.update,
          resourceType: 'profile',
          resourceId: uid,
          priority: 10, // High priority for profile updates
          payload: updatedData,
        );
        
        await _offlineQueueManager.enqueueAction(action);
        
        debugPrint('🔄 Profile update queued for offline processing: $actionId');
      }
    } catch (e) {
      debugPrint('⚠️ Error updating profile: $e');
      rethrow;
    }
  }
}

// Provider for profile repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final cacheManager = ref.watch(cacheManagerProvider);
  final eventBus = AppEventBus();
  final offlineQueueManager = ref.watch(offlineQueueManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  
  return ProfileRepository(
    firestore: firestore,
    auth: auth,
    cacheManager: cacheManager,
    eventBus: eventBus,
    offlineQueueManager: offlineQueueManager,
    connectivityService: connectivityService,
  );
}); 