import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider for all available spaces
final allSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  try {
    // Get the spaces repository
    final repository = ref.read(spaceRepositoryProvider);
    
    // Fetch all spaces
    debugPrint('Fetching all spaces...');
    final spaces = await repository.getAllSpaces();
    debugPrint('Retrieved ${spaces.length} spaces');
    
    return spaces;
  } catch (e, stack) {
    debugPrint('Error loading all spaces: $e');
    debugPrint('Stack trace: $stack');
    throw Exception('Failed to load spaces: $e');
  }
});

/// Provider for spaces the current user has joined
final joinedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  try {
    // Get current user
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('No logged in user found');
      return [];
    }
    
    // Get the spaces repository
    final repository = ref.read(spaceRepositoryProvider);
    
    // Fetch joined spaces
    debugPrint('Fetching joined spaces for user $userId...');
    final spaces = await repository.getJoinedSpaces();
    debugPrint('Retrieved ${spaces.length} joined spaces');
    
    return spaces;
  } catch (e, stack) {
    debugPrint('Error loading joined spaces: $e');
    debugPrint('Stack trace: $stack');
    throw Exception('Failed to load joined spaces: $e');
  }
}); 