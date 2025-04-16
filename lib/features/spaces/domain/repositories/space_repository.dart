import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Interface for space repository operations
///
/// This interface defines the required methods for interacting with spaces
/// in the application. It provides methods for checking, joining, and leaving spaces,
/// as well as retrieving lists of spaces.
abstract class SpaceRepository {
  /// Check if the user has joined a space
  ///
  /// [spaceId] The ID of the space to check
  ///
  /// Returns true if the current user has joined the space, false otherwise
  Future<bool> isSpaceJoined(String spaceId);
  
  /// Join a space
  ///
  /// [spaceId] The ID of the space to join
  ///
  /// Adds the current user to the specified space
  Future<void> joinSpace(String spaceId);
  
  /// Leave a space
  ///
  /// [spaceId] The ID of the space to leave
  ///
  /// Removes the current user from the specified space
  Future<void> leaveSpace(String spaceId);
  
  /// Get all spaces
  ///
  /// Returns a list of all available spaces in the application
  Future<List<SpaceEntity>> getAllSpaces();
  
  /// Get spaces that the user has joined
  ///
  /// Returns a list of spaces that the current user has joined
  Future<List<SpaceEntity>> getJoinedSpaces();
} 