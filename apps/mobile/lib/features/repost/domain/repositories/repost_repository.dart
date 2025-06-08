import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost.dart';

/// Repository interface for repost-related operations
abstract class RepostRepository {
  /// Create a new repost
  Future<Repost> createRepost({
    required String userId,
    required String eventId,
    required Event event,
    String? text,
    required String contentType,
  });
  
  /// Get reposts by user
  Future<List<Repost>> getRepostsByUser(String userId);
  
  /// Get reposts for an event
  Future<List<Repost>> getRepostsForEvent(String eventId);
  
  /// Delete a repost
  Future<void> deleteRepost(String repostId);
  
  /// Update a repost
  Future<void> updateRepost(Repost repost);
} 