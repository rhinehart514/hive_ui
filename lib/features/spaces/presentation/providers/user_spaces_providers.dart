import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/data/repositories/user_spaces_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/user_spaces_repository.dart';
import 'package:hive_ui/features/spaces/utils/model_converters.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for the UserSpacesRepository implementation
final userSpacesRepositoryProvider = Provider<UserSpacesRepository>((ref) {
  final spacesDataSource = SpacesFirestoreDataSource();
  return UserSpacesRepositoryImpl(spacesDataSource: spacesDataSource);
});

/// Provider for the current user's spaces
final userSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  // Get currently authenticated user ID
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return []; // Return empty list if no user is authenticated
  }

  final userId = user.uid;
  final repository = ref.read(userSpacesRepositoryProvider);
  
  try {
    // Use the user data provider to get the most up-to-date list of joined spaces
    final userData = ref.watch(userProvider);
    final List<String> joinedSpaceIds = userData?.joinedClubs ?? [];
    
    debugPrint('Fetching user spaces for ${joinedSpaceIds.length} joined spaces');
    
    // Get the user's spaces from the repository
    final spaces = await repository.getUserSpaces(userId);
    
    // If the repository returned fewer spaces than expected,
    // try to fetch individual spaces by ID from the userData
    if (spaces.length < joinedSpaceIds.length) {
      debugPrint('Repository returned ${spaces.length} spaces, expected ${joinedSpaceIds.length}');
      
      // Find missing space IDs
      final foundSpaceIds = spaces.map((s) => s.id).toSet();
      final missingSpaceIds = joinedSpaceIds.where((id) => !foundSpaceIds.contains(id)).toList();
      
      if (missingSpaceIds.isNotEmpty) {
        debugPrint('Trying to fetch ${missingSpaceIds.length} missing spaces');
        
        // Fetch missing spaces individually using the SpaceService
        final additionalSpaces = await SpaceService.getUserSpaces(missingSpaceIds);
        if (additionalSpaces.isNotEmpty) {
          debugPrint('Found ${additionalSpaces.length} additional spaces');
          // Convert to SpaceEntity using the converter utility
          spaces.addAll(additionalSpaces.map((legacySpace) => 
            SpaceModelConverters.convertLegacySpaceToEntity(legacySpace)
          ));
        }
      }
    }
    
    return spaces;
  } catch (e) {
    // Log the error and return an empty list
    debugPrint('Error fetching user spaces: $e');
    return [];
  }
});

/// Provider to check if a user has joined a specific space
final hasJoinedSpaceProvider = FutureProvider.family<bool, String>((ref, spaceId) async {
  // Get currently authenticated user ID
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return false; // Not joined if no user is authenticated
  }

  final userId = user.uid;
  final repository = ref.read(userSpacesRepositoryProvider);
  
  try {
    return await repository.hasJoinedSpace(userId, spaceId);
  } catch (e) {
    // Log the error and return false
    debugPrint('Error checking if user joined space: $e');
    return false;
  }
});

/// Provider for recommended spaces for the current user
final recommendedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  // Get currently authenticated user ID
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return []; // Return empty list if no user is authenticated
  }

  final userId = user.uid;
  final repository = ref.read(userSpacesRepositoryProvider);
  
  try {
    return await repository.getRecommendedSpaces(userId);
  } catch (e) {
    // Log the error and return an empty list
    debugPrint('Error fetching recommended spaces: $e');
    return [];
  }
});

/// Function provider to join a space
final joinSpaceProvider = Provider.family<Future<void> Function(), String>((ref, spaceId) {
  return () async {
    // Get currently authenticated user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to join a space');
    }

    final userId = user.uid;
    final repository = ref.read(userSpacesRepositoryProvider);
    
    // Join the space
    await repository.joinSpace(userId, spaceId);
    
    // Refresh only the necessary providers
    ref.invalidate(userSpacesProvider);
    ref.invalidate(hasJoinedSpaceProvider(spaceId));
    
    // Update UserData model for backward compatibility
    final userData = ref.read(userProvider);
    if (userData != null) {
      ref.read(userProvider.notifier).state = userData.joinClub(spaceId);
    }
  };
});

/// Function provider to leave a space
final leaveSpaceProvider = Provider.family<Future<void> Function(), String>((ref, spaceId) {
  return () async {
    // Get currently authenticated user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to leave a space');
    }

    final userId = user.uid;
    final repository = ref.read(userSpacesRepositoryProvider);
    
    // Leave the space
    await repository.leaveSpace(userId, spaceId);
    
    // Refresh providers to update UI
    ref.invalidate(userSpacesProvider);
    ref.invalidate(hasJoinedSpaceProvider(spaceId));
    
    // Update UserData model for backward compatibility
    final userData = ref.read(userProvider);
    if (userData != null) {
      ref.read(userProvider.notifier).state = userData.leaveClub(spaceId);
    }
  };
});

/// Provider to synchronize a user's joined spaces data
final syncUserSpacesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    debugPrint('Synchronizing user spaces data');
    // Get currently authenticated user ID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No authenticated user found');
      return;
    }

    final userId = user.uid;
    
    try {
      // Get the Firestore data for followedSpaces
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('User document not found: $userId');
        return;
      }
      
      // Get the current local UserData
      final userData = ref.read(userProvider);
      if (userData == null) {
        debugPrint('No local UserData available');
        return;
      }
      
      // Extract space IDs from Firestore
      final data = userDoc.data();
      final List<String> firestoreSpaceIds = [];
      
      if (data != null && data['followedSpaces'] != null && data['followedSpaces'] is List) {
        firestoreSpaceIds.addAll(List<String>.from(data['followedSpaces']));
      }
      
      // Get the local joinedClubs
      final List<String> localSpaceIds = userData.joinedClubs;
      
      debugPrint('Firestore followedSpaces: $firestoreSpaceIds');
      debugPrint('Local joinedClubs: $localSpaceIds');
      
      // Check for spaces that need to be added to the local model
      final spacesToAdd = firestoreSpaceIds.where((id) => !localSpaceIds.contains(id)).toList();
      
      // Check for spaces that need to be added to Firestore
      final spacesToAddToFirestore = localSpaceIds.where((id) => !firestoreSpaceIds.contains(id)).toList();
      
      // Update local UserData if needed
      if (spacesToAdd.isNotEmpty) {
        debugPrint('Adding ${spacesToAdd.length} spaces to local UserData: $spacesToAdd');
        var updatedUserData = userData;
        for (final spaceId in spacesToAdd) {
          updatedUserData = updatedUserData.joinClub(spaceId);
        }
        ref.read(userProvider.notifier).state = updatedUserData;
      }
      
      // Update Firestore if needed
      if (spacesToAddToFirestore.isNotEmpty) {
        debugPrint('Adding ${spacesToAddToFirestore.length} spaces to Firestore: $spacesToAddToFirestore');
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'followedSpaces': FieldValue.arrayUnion(spacesToAddToFirestore),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Refresh the spaces provider to update UI
      ref.invalidate(userSpacesProvider);
      
    } catch (e) {
      debugPrint('Error synchronizing user spaces: $e');
    }
  };
}); 