import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';

/// Interface for profile repository operations
abstract class ProfileRepository {
  /// Get a user's profile by ID
  Future<UserProfile> getProfile(String userId);
  
  /// Update a user's profile
  Future<bool> updateProfile(String userId, UserProfile profile);
  
  /// Get profiles for a list of user IDs
  Future<List<UserProfile>> getProfiles(List<String> userIds);
  
  /// Save an event to the user's saved events list
  Future<bool> saveEvent(String userId, dynamic event);
  
  /// Remove an event from the user's saved events list
  Future<bool> removeEvent(String userId, String eventId);
  
  /// Check if an event is saved by the user
  Future<bool> isEventSaved(String userId, String eventId);
  
  /// Get all events saved by the user
  Future<List<dynamic>> getSavedEvents(String userId);
}

/// Provider for the profile repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // In a real implementation, we would return a concrete implementation
  throw UnimplementedError('Implement a concrete ProfileRepository');
});

/// Provider for pending offline actions
final pendingOfflineActionsProvider = Provider<List<dynamic>>((ref) {
  // In a real implementation, this would come from OfflineQueueManager
  return [];
}); 