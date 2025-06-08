import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/features/feed/domain/repositories/feed_repository.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/repost/domain/repositories/repost_repository.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';

/// Use case that handles feed interactions including RSVP, repost, and quote actions
class HandleInteractionsUseCase {
  final FeedRepository _feedRepository;
  final ProfileRepository _profileRepository;
  final RepostRepository _repostRepository;
  
  /// Constructor
  HandleInteractionsUseCase({
    required FeedRepository feedRepository,
    required ProfileRepository profileRepository,
    required RepostRepository repostRepository,
  }) : 
    _feedRepository = feedRepository,
    _profileRepository = profileRepository,
    _repostRepository = repostRepository;
  
  /// Handle RSVP action for an event
  /// Returns true if successful, false otherwise
  Future<bool> handleRsvp(String eventId, bool attending) async {
    try {
      // Provide haptic feedback
      if (attending) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      
      // Call feed repository to handle RSVP
      final result = await _feedRepository.rsvpToEvent(eventId, attending);
      
      // Process the result
      return result.fold(
        (failure) {
          debugPrint('RSVP Failed: ${failure.message}');
          return false;
        },
        (success) {
          // Success - no need to update profile, feed repository handles it
          return success;
        },
      );
    } catch (e) {
      debugPrint('Error in handleRsvp: $e');
      return false;
    }
  }
  
  /// Handle repost action for an event
  /// Returns true if successful, false otherwise
  Future<bool> handleRepost(
    Event event, 
    String? comment, 
    RepostContentType type
  ) async {
    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      // Create a new repost via the feed repository
      final result = await _feedRepository.repostEvent(
        eventId: event.id,
        comment: comment,
        userId: null, // Let the repository determine current user
      );
      
      // Process the result
      return result.fold(
        (failure) {
          debugPrint('Repost Failed: ${failure.message}');
          return false;
        },
        (repostedEvent) {
          // Success handling done within the repository
          return repostedEvent != null;
        },
      );
    } catch (e) {
      debugPrint('Error in handleRepost: $e');
      return false;
    }
  }
} 