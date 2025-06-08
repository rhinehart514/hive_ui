import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:hive_ui/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_analytics.dart';
import 'package:hive_ui/features/profile/domain/entities/recommended_user.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/user_profile.dart' as model;
import 'package:hive_ui/features/shared/infrastructure/platform_integration_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;
  final SpacesRepository _spacesRepository;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final PlatformIntegrationManager _integrationManager;
  final Duration _cacheDuration = const Duration(minutes: 5);
  DateTime? _lastSyncTime;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
    required SpacesRepository spacesRepository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    PlatformIntegrationManager? integrationManager,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _spacesRepository = spacesRepository,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _integrationManager = integrationManager ?? PlatformIntegrationManager();

  @override
  Future<domain.UserProfile?> getProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) {
        debugPrint('ProfileRepositoryImpl: No user ID provided or found');
        return null;
      }

      // Check if we have a valid cached profile
      final cachedProfile = await _localDataSource.getProfile();
      final now = DateTime.now();
      final isCacheValid = _lastSyncTime != null &&
          now.difference(_lastSyncTime!) < _cacheDuration;

      if (cachedProfile != null && isCacheValid) {
        debugPrint('ProfileRepositoryImpl: Returning cached profile for $targetUserId');
        return UserProfileMapper.mapToDomain(cachedProfile);
      }

      // Try to get fresh data from remote
      try {
        final remoteProfile = await _remoteDataSource.getProfile(targetUserId);
        if (remoteProfile != null) {
          // Update cache
          await _localDataSource.cacheProfile(remoteProfile);
          _lastSyncTime = now;
          return UserProfileMapper.mapToDomain(remoteProfile);
        }
      } catch (e) {
        debugPrint('ProfileRepositoryImpl: Error fetching remote profile: $e');
        // If we have a cached profile, return it even if expired
        if (cachedProfile != null) {
          return UserProfileMapper.mapToDomain(cachedProfile);
        }
        rethrow;
      }

      return cachedProfile != null ? UserProfileMapper.mapToDomain(cachedProfile) : null;
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error in getProfile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(domain.UserProfile profile) async {
    try {
      // Convert domain profile to model profile
      final modelProfile = UserProfileMapper.mapToModel(profile);
      
      // Update remote first
      await _remoteDataSource.updateProfile(modelProfile);
      
      // If successful, update local cache
      await _localDataSource.cacheProfile(modelProfile);
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Optimize and validate image before upload
      final optimizedImage = await _optimizeImage(imageFile);
      final validatedImage = await _validateImage(optimizedImage);

      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = validatedImage.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        throw Exception('Invalid image format. Supported formats: JPG, PNG, WebP');
      }

      final storageRef = _storage
          .ref()
          .child('profile_images/${currentUser.uid}/profile_$timestamp.$ext');

      // Upload with metadata
      final uploadTask = storageRef.putFile(
        validatedImage,
        SettableMetadata(
          contentType: 'image/$ext',
          customMetadata: {
            'userId': currentUser.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFilename': imageFile.path.split('/').last,
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get and validate download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      if (!await _isImageUrlAccessible(downloadUrl)) {
        throw Exception('Uploaded image is not accessible');
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Stream<domain.UserProfile?> watchProfile(String userId) {
    // Merge remote and local streams
    final remoteStream = _remoteDataSource.watchProfile(userId);
    
    return remoteStream.asyncMap((remoteProfile) async {
      if (remoteProfile != null) {
        // Update local cache with remote data
        await _localDataSource.cacheProfile(remoteProfile);
        _lastSyncTime = DateTime.now();
        return UserProfileMapper.mapToDomain(remoteProfile);
      }
      // If remote returns null, try local cache
      final localProfile = await _localDataSource.getProfile();
      return localProfile != null ? UserProfileMapper.mapToDomain(localProfile) : null;
    }).handleError((error) async {
      debugPrint('ProfileRepositoryImpl: Error in remote stream: $error');
      // On remote error, fallback to local cache
      final localProfile = await _localDataSource.getProfile();
      return localProfile != null ? UserProfileMapper.mapToDomain(localProfile) : null;
    }).asBroadcastStream();
  }

  @override
  Future<void> updateUserInterests(String userId, List<String> interests) async {
    try {
      // Get current profile
      final domainProfile = await getProfile(userId);
      if (domainProfile == null) {
        throw Exception('Profile not found');
      }

      // Create updated profile
      final updatedDomainProfile = domainProfile.copyWith(
        interests: interests,
        updatedAt: DateTime.now(),
      );

      // Update profile
      await updateProfile(updatedDomainProfile);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error updating interests: $e');
      rethrow;
    }
  }

  @override
  Future<void> createProfile(domain.UserProfile profile) async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Create profile with the current user's ID
      final updatedDomainProfile = profile.copyWith(
        id: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convert domain profile to model before storing
      final modelProfile = UserProfileMapper.mapToModel(updatedDomainProfile);

      // Create in Firestore
      await _remoteDataSource.createProfile(modelProfile);

      // Cache locally
      await _localDataSource.cacheProfile(modelProfile);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error creating profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  @override
  Future<void> removeProfileImage() async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get current profile
      final domainProfile = await getProfile(currentUser.uid);
      if (domainProfile == null) {
        throw Exception('Profile not found');
      }

      // Update profile with null image URL
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache with a converted model that has null photoUrl
      final updatedDomainProfile = domainProfile.copyWith(
        photoUrl: null,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.cacheProfile(UserProfileMapper.mapToModel(updatedDomainProfile));
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error removing profile image: $e');
      throw Exception('Failed to remove profile image: $e');
    }
  }

  /// Get saved events for a user
  ///
  /// This method uses the platform integration manager to ensure consistency
  /// with how events are stored and retrieved across the platform
  @override
  Future<List<Event>> getSavedEvents(String userId) async {
    try {
      // Check local cache first
      final cachedProfile = await _localDataSource.getProfile();
      if (cachedProfile != null && 
          cachedProfile.id == userId && 
          _lastSyncTime != null &&
          DateTime.now().difference(_lastSyncTime!) < _cacheDuration) {
        return cachedProfile.savedEvents;
      }
      
      // Fetch from remote if cache is stale or for a different user
      return await _integrationManager.getSavedEventsForUser(userId);
    } catch (e) {
      debugPrint('Error getting saved events: $e');
      // If remote fails, try cache
      final cachedProfile = await _localDataSource.getProfile();
      if (cachedProfile != null && cachedProfile.id == userId) {
        return cachedProfile.savedEvents;
      }
      return [];
    }
  }

  /// Get spaces joined by a user
  ///
  /// Fetches joined spaces using the dedicated SpacesRepository.
  @override
  Future<List<Space>> getJoinedSpaces(String userId) async {
    try {
      // Use the injected SpacesRepository
      final List<SpaceEntity> spaceEntities = 
          await _spacesRepository.getJoinedSpaces(userId: userId);
      
      // Map SpaceEntity list to Space list (using hypothetical Space.fromEntity)
      final List<Space> spaces = spaceEntities
          // .map((entity) => SpaceMapper.toModel(entity)) // Use the mapper
          .map((entity) => Space.fromEntity(entity)) // Use static method on model
          .toList();
          
      return spaces;
      // Old implementation using PlatformIntegrationManager (incorrect)
      // return await _integrationManager.getSpacesForUser(userId);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error getting joined spaces via SpacesRepository: $e');
      return []; // Return empty list on error
    }
  }

  // Helper method to normalize image URL
  Future<String> _normalizeImageUrl(String url) async {
    try {
      if (url.isEmpty) return '';

      // Handle network URLs
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final uri = Uri.parse(url);
        if (!uri.hasScheme || uri.host.isEmpty) {
          debugPrint('Invalid network URL: $url');
          return '';
        }
        
        // Verify URL is accessible
        if (!await _isImageUrlAccessible(url)) {
          debugPrint('Image URL is not accessible: $url');
          return '';
        }
        
        return url;
      }

      // Handle file:// URLs and local paths
      if (Platform.isIOS || Platform.isAndroid || Platform.isWindows || Platform.isMacOS) {
        String normalizedPath = url.startsWith('file://')
            ? url.replaceFirst('file://', '')
            : url;

        normalizedPath = normalizedPath.replaceAll('\\', '/');

        try {
          final file = File(normalizedPath);
          if (!await file.exists()) {
            debugPrint('File does not exist: $normalizedPath');
            return '';
          }
        } catch (e) {
          debugPrint('Error checking file existence: $e');
          return '';
        }

        return normalizedPath;
      }

      return '';
    } catch (e) {
      debugPrint('Error normalizing image URL: $e');
      return '';
    }
  }

  // Helper method to check if an image URL is accessible
  Future<bool> _isImageUrlAccessible(String url) async {
    try {
      final response = await _integrationManager.httpClient.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking image URL accessibility: $e');
      return false;
    }
  }

  // Helper method to optimize image before upload
  Future<File> _optimizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Resize if needed
      var processedImage = image;
      if (image.width > 800 || image.height > 800) {
        processedImage = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height >= image.width ? 800 : null,
        );
      }

      // Compress and save
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final optimizedBytes = img.encodeJpg(processedImage, quality: 85);
      await tempFile.writeAsBytes(optimizedBytes);

      return tempFile;
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  // Helper method to validate image file
  Future<File> _validateImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) { // 5MB limit
      throw Exception('Image file size exceeds 5MB limit');
    }

    // Verify it's a valid image
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Invalid image file');
    }

    return imageFile;
  }

  @override
  Future<void> saveEvent(String userId, Event event) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      
      // Use a transaction for concurrent write safety
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDoc);
        
        if (!userSnapshot.exists) {
          throw Exception('User profile not found');
        }
        
        // Get current saved events
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> savedEventsData = userData['savedEvents'] ?? [];
        
        // Check if this event is already saved
        bool isAlreadySaved = false;
        for (var eventData in savedEventsData) {
          if (eventData is Map<String, dynamic> && eventData['id'] == event.id) {
            isAlreadySaved = true;
            break;
          }
        }
        
        if (!isAlreadySaved) {
          // Add the event
          transaction.update(userDoc, {
            'savedEvents': FieldValue.arrayUnion([event.toJson()]),
            'updatedAt': FieldValue.serverTimestamp(),
            'eventCount': FieldValue.increment(1),
          });
          
          // Also update local cache
          final cachedProfile = await _localDataSource.getProfile();
          if (cachedProfile != null && cachedProfile.id == userId) {
            final updatedEvents = List<Event>.from(cachedProfile.savedEvents)..add(event);
            final updatedProfile = cachedProfile.copyWith(
              savedEvents: updatedEvents,
              eventCount: cachedProfile.eventCount + 1,
              updatedAt: DateTime.now(),
            );
            await _localDataSource.cacheProfile(updatedProfile);
          }
        }
      });
      
      // Log the action
      debugPrint('Event saved to profile: ${event.id}');
    } catch (e) {
      debugPrint('Error saving event to profile: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> removeEvent(String userId, String eventId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      
      // Use a transaction for concurrent write safety
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDoc);
        
        if (!userSnapshot.exists) {
          throw Exception('User profile not found');
        }
        
        // Get current saved events
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> savedEventsData = userData['savedEvents'] ?? [];
        
        // Find the event to remove
        Map<String, dynamic>? eventToRemove;
        for (var eventData in savedEventsData) {
          if (eventData is Map<String, dynamic> && eventData['id'] == eventId) {
            eventToRemove = eventData;
            break;
          }
        }
        
        if (eventToRemove != null) {
          // Remove the event
          transaction.update(userDoc, {
            'savedEvents': FieldValue.arrayRemove([eventToRemove]),
            'updatedAt': FieldValue.serverTimestamp(),
            'eventCount': FieldValue.increment(-1),
          });
          
          // Also update local cache
          final cachedProfile = await _localDataSource.getProfile();
          if (cachedProfile != null && cachedProfile.id == userId) {
            final updatedEvents = cachedProfile.savedEvents.where((e) => e.id != eventId).toList();
            final updatedProfile = cachedProfile.copyWith(
              savedEvents: updatedEvents,
              eventCount: cachedProfile.eventCount > 0 ? cachedProfile.eventCount - 1 : 0,
              updatedAt: DateTime.now(),
            );
            await _localDataSource.cacheProfile(updatedProfile);
          }
        }
      });
      
      // Log the action
      debugPrint('Event removed from profile: $eventId');
    } catch (e) {
      debugPrint('Error removing event from profile: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> isEventSaved(String userId, String eventId) async {
    try {
      // Check local cache first for performance
      final cachedProfile = await _localDataSource.getProfile();
      if (cachedProfile != null && 
          cachedProfile.id == userId && 
          _lastSyncTime != null &&
          DateTime.now().difference(_lastSyncTime!) < _cacheDuration) {
        return cachedProfile.savedEvents.any((event) => event.id == eventId);
      }
      
      // If not in cache or cache is stale, check Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> savedEventsData = userData['savedEvents'] ?? [];
      
      return savedEventsData.any((eventData) => 
        eventData is Map<String, dynamic> && eventData['id'] == eventId);
    } catch (e) {
      debugPrint('Error checking if event is saved: $e');
      return false;
    }
  }

  @override
  Future<void> updateUserRestriction(String userId, {
    required bool isRestricted,
    String? reason,
    DateTime? endDate,
    String? restrictedBy,
  }) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      
      // Prepare data for update
      final updateData = {
        'isRestricted': isRestricted,
        'restrictionReason': reason,
        'restrictionEndDate': endDate, // Store as Timestamp or null
        'restrictedBy': restrictedBy,
        'updatedAt': FieldValue.serverTimestamp(), // Update timestamp
      };
      
      // Remove null values from the update data
      updateData.removeWhere((key, value) => value == null);
      
      // If removing restriction, remove all restriction fields
      if (!isRestricted) {
        updateData.addAll({
          'restrictionReason': FieldValue.delete(),
          'restrictionEndDate': FieldValue.delete(),
          'restrictedBy': FieldValue.delete(),
        });
      }
      
      await userDocRef.update(updateData);
      
      // Optionally update local cache if needed, though restrictions might not be in UserProfile model
      // Consider invalidating or updating the relevant user data in local caches/providers
      
      debugPrint('User restriction updated for $userId: isRestricted=$isRestricted');
    } catch (e) {
      debugPrint('Error updating user restriction for $userId: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileAnalytics?> getProfileAnalytics(String userId) async {
    try {
      // TODO: Implement actual analytics fetch from Firestore/Analytics service
      debugPrint('ProfileRepositoryImpl: Fetching analytics for $userId');
      
      // Placeholder implementation - in a real app, fetch this from Firestore
      return ProfileAnalytics.empty().copyWith(
        engagementScore: 10,
        recentProfileViews: 5,
        recentSearchAppearances: 3,
        eventAttendanceRate: 0.4,
        spaceParticipationRate: 0.3,
        connectionGrowthRate: 0.1,
        contentEngagementRate: 0.2,
        topActiveSpaces: [],
        topEventTypes: [],
        topConnections: [],
        peakActivityHours: [],
        monthlyActivity: {},
      );
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error fetching profile analytics: $e');
      return null;
    }
  }

  @override
  Future<void> recordProfileInteraction({
    required String viewedUserId,
    required String viewerId,
    required String interactionType,
  }) async {
    try {
      // Record interaction in Firestore
      final interactionData = {
        'viewedUserId': viewedUserId,
        'viewerId': viewerId,
        'interactionType': interactionType,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('profileInteractions')
          .add(interactionData);
          
      debugPrint('ProfileRepositoryImpl: Recorded interaction $interactionType from $viewerId on $viewedUserId');
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error recording interaction: $e');
      // We might want to swallow this error rather than disrupt the app flow
      // for analytics tracking
    }
  }

  @override
  Future<List<domain.UserProfile>> searchProfiles({
    required String query,
    UserSearchFilters? filters,
    int limit = 20,
  }) async {
    try {
      // Start with a base query
      Query usersQuery = _firestore.collection('users');
      
      // Apply text search (this is a simple implementation - in production you'd 
      // likely want to use a proper search service like Algolia or ElasticSearch)
      if (query.isNotEmpty) {
        // Firebase doesn't support full text search, so we're using simple prefix matching
        // on displayName field - this is not ideal for production
        usersQuery = usersQuery
            .orderBy('displayName')
            .startAt([query])
            .endAt(['$query\uf8ff']);
      }
      
      // Apply filters if provided
      if (filters != null) {
        // Apply verification filter if onlyVerified is true
        if (filters.onlyVerified) {
          usersQuery = usersQuery.where(
            'isVerified', 
            isEqualTo: true
          );
        }
        
        if (filters.residence != null && filters.residence!.isNotEmpty) {
          usersQuery = usersQuery.where('residence', isEqualTo: filters.residence);
        }
        
        if (filters.year != null && filters.year!.isNotEmpty) {
          usersQuery = usersQuery.where('year', isEqualTo: filters.year);
        }
        
        if (filters.major != null && filters.major!.isNotEmpty) {
          usersQuery = usersQuery.where('major', isEqualTo: filters.major);
        }
        
        if (filters.interests.isNotEmpty) {
          // This is a limitation of Firestore - we can only query for profiles
          // that have ALL of these interests
          usersQuery = usersQuery.where('interests', arrayContainsAny: filters.interests);
        }
        
        // Note: Additional filters would need a composite index in Firestore
      }
      
      // Apply limit
      usersQuery = usersQuery.limit(limit);
      
      // Execute query
      final querySnapshot = await usersQuery.get();
      
      // Convert documents to UserProfile entities
      final profiles = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Create a model UserProfile
        final modelProfile = model.UserProfile(
          id: doc.id,
          username: doc.id,
          displayName: data['displayName'] ?? '',
          email: data['email'],
          bio: data['bio'],
          profileImageUrl: data['photoUrl'],
          interests: data['interests'] != null 
              ? List<String>.from(data['interests']) 
              : [],
          year: data['year'] ?? '',
          major: data['major'] ?? '',
          residence: data['location'] ?? '',
          eventCount: data['eventCount'] ?? 0,
          spaceCount: data['spaceCount'] ?? 0,
          friendCount: data['friendCount'] ?? 0,
          createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
          updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
          isPublic: data['isPublic'] ?? true,
          isVerified: data['isVerified'] ?? false,
          isVerifiedPlus: data['isVerifiedPlus'] ?? false,
        );
        
        // Convert to domain entity
        return UserProfileMapper.mapToDomain(modelProfile);
      }).toList();
      
      return profiles;
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error searching profiles: $e');
      // Return empty list on error
      return [];
    }
  }

  @override
  Future<List<RecommendedUser>> getRecommendedUsers({
    String? basedOnUserId,
    int limit = 10,
  }) async {
    try {
      final userId = basedOnUserId ?? _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User ID is required for recommendations');
      }
      
      // TODO: Implement actual recommendation algorithm 
      // For now, this is a simple placeholder that just returns random users
      
      // Get current user's profile to understand interests
      final currentUserProfile = await getProfile(userId);
      final userInterests = currentUserProfile?.interests ?? [];
      
      // Find users with similar interests
      // Note: This is a very basic recommendation strategy - in production you'd
      // want a more sophisticated algorithm
      final usersQuery = await _firestore
          .collection('users')
          .where('id', isNotEqualTo: userId) // Exclude current user
          .limit(limit * 2) // Fetch more than needed to account for filtering
          .get();
      
      final List<RecommendedUser> recommendations = [];
      
      for (final doc in usersQuery.docs) {
        if (recommendations.length >= limit) break;
        
        final data = doc.data();
        
        // Create a model UserProfile
        final modelProfile = model.UserProfile(
          id: doc.id,
          username: doc.id,
          displayName: data['displayName'] ?? '',
          email: data['email'],
          bio: data['bio'],
          profileImageUrl: data['photoUrl'],
          interests: data['interests'] != null 
              ? List<String>.from(data['interests']) 
              : [],
          year: data['year'] ?? '',
          major: data['major'] ?? '',
          residence: data['location'] ?? '',
          eventCount: data['eventCount'] ?? 0,
          spaceCount: data['spaceCount'] ?? 0,
          friendCount: data['friendCount'] ?? 0,
          createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
          updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
          isPublic: data['isPublic'] ?? true,
          isVerified: data['isVerified'] ?? false,
          isVerifiedPlus: data['isVerifiedPlus'] ?? false,
        );
        
        // Convert to domain entity for consistent API
        final userProfile = UserProfileMapper.mapToDomain(modelProfile);
        
        // Calculate recommendation strength based on shared interests
        final docInterests = data['interests'] != null 
            ? List<String>.from(data['interests']) 
            : <String>[];
            
        final sharedInterestCount = docInterests
            .where((interest) => userInterests.contains(interest))
            .length;
            
        // Only include users with at least one shared interest
        if (sharedInterestCount > 0 || userInterests.isEmpty) {
          // Create recommendation with normalized strength (0.0 - 1.0)
          final strength = userInterests.isEmpty 
              ? 0.5 // If user has no interests, give neutral strength
              : sharedInterestCount / userInterests.length;
              
          recommendations.add(RecommendedUser(
            id: doc.id,
            name: data['displayName'] ?? '',
            profileImage: data['photoUrl'],
            major: data['major'],
            year: data['year'],
            residence: data['location'],
            reasons: ['Shared interests: $sharedInterestCount'],
            score: strength,
          ));
        }
      }
      
      // Sort by recommendation strength (score)
      recommendations.sort((a, b) => b.score.compareTo(a.score));
          
      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error getting recommended users: $e');
      return [];
    }
  }
  
  // Helper methods for parsing Firestore data
  
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    
    return null;
  }
  
  VerificationLevel _parseVerificationLevel(dynamic level) {
    if (level == null) return VerificationLevel.public;
    
    if (level is String) {
      try {
        return VerificationLevel.values.firstWhere(
          (e) => e.name == level,
          orElse: () => VerificationLevel.public,
        );
      } catch (_) {
        return VerificationLevel.public;
      }
    } else if (level is int && level >= 0 && level < VerificationLevel.values.length) {
      return VerificationLevel.values[level];
    }
    
    return VerificationLevel.public;
  }
}
