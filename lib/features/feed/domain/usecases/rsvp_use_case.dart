import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/repositories/feed_repository.dart';
import 'package:hive_ui/features/feed/domain/providers/feed_domain_providers.dart';
import 'package:hive_ui/models/event.dart';

/// Use case specifically for RSVP functionality
class RsvpUseCase {
  final FeedRepository _feedRepository;
  
  /// Constructor
  RsvpUseCase({required FeedRepository feedRepository}) 
    : _feedRepository = feedRepository;
  
  /// Handle RSVP action for an event
  /// Returns true if successful, false otherwise
  Future<bool> toggleRsvp(String eventId, bool newStatus) async {
    try {
      // Provide appropriate haptic feedback based on action
      if (newStatus) {
        HapticFeedback.mediumImpact(); // More noticeable when RSVPing
      } else {
        HapticFeedback.lightImpact(); // Lighter when canceling
      }
      
      // Call repository to handle RSVP
      final result = await _feedRepository.rsvpToEvent(eventId, newStatus);
      
      // Process the result
      return result.fold(
        (failure) {
          debugPrint('RSVP Failed: ${failure.message}');
          return false;
        },
        (success) {
          // Record in Trail/history if needed
          _recordUserAction(eventId, newStatus);
          return success;
        },
      );
    } catch (e) {
      debugPrint('Error in RsvpUseCase: $e');
      return false;
    }
  }
  
  /// Get current RSVP status for an event
  Future<bool> getRsvpStatus(String eventId) async {
    try {
      final result = await _feedRepository.getEventRsvpStatus(eventId);
      
      return result.fold(
        (failure) {
          debugPrint('Failed to get RSVP status: ${failure.message}');
          return false;
        },
        (isRsvped) => isRsvped,
      );
    } catch (e) {
      debugPrint('Error getting RSVP status: $e');
      return false;
    }
  }
  
  /// Record user action for Trail system - placeholder for now
  void _recordUserAction(String eventId, bool status) {
    // This would integrate with the Trail system to record the user's RSVP action
    // For now, just log the action
    debugPrint('Recording RSVP action: Event $eventId, Status: $status');
  }
}

/// Provider for the RsvpUseCase
final rsvpUseCaseProvider = Provider<RsvpUseCase>((ref) {
  final feedRepository = ref.watch(feedRepositoryProvider);
  return RsvpUseCase(feedRepository: feedRepository);
}); 