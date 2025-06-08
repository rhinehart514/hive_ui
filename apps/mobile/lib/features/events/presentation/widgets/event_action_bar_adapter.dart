import 'package:flutter/material.dart';
import '../../../../components/event_details/event_action_bar.dart';
import '../../../../models/event.dart';
import '../../../../models/repost_content_type.dart';

/// An adapter for EventActionBar that simplifies usage with async methods
class EventActionBarAdapter extends StatelessWidget {
  /// The event
  final Event event;

  /// Whether the user has RSVP'd to this event
  final bool isRsvpd;

  /// Callback when the RSVP button is tapped
  final Future<void> Function(bool)? onRsvp;

  /// Callback when the Add to Calendar button is tapped
  final VoidCallback onAddToCalendar;
  
  /// Callback when the user taps the repost button
  final VoidCallback? onRepost;
  
  /// Whether the user follows the event's club
  final bool followsClub;
  
  /// Whether the RSVP operation is in progress
  final bool isLoading;
  
  /// Whether the current user is the event owner and can edit/cancel
  final bool isEventOwner;
  
  /// Callback when edit event is tapped
  final VoidCallback? onEditTap;
  
  /// Callback when cancel event is tapped
  final VoidCallback? onCancelTap;

  /// Constructor
  const EventActionBarAdapter({
    Key? key,
    required this.event,
    required this.isRsvpd,
    required this.onAddToCalendar,
    this.onRsvp,
    this.onRepost,
    this.followsClub = false,
    this.isLoading = false,
    this.isEventOwner = false,
    this.onEditTap,
    this.onCancelTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EventActionBar(
      event: event,
      isRsvpd: isRsvpd,
      onRsvpTap: onRsvp != null ? _adaptRsvpCallback(onRsvp!) : _noOpRsvpCallback,
      onAddToCalendarTap: onAddToCalendar,
      onRepost: onRepost != null ? _adaptRepostCallback() : null,
      followsClub: followsClub,
      todayBoosts: const <DateTime>[],
      isLoading: isLoading,
      isEventOwner: isEventOwner,
      onEditTap: onEditTap,
      onCancelTap: onCancelTap,
    );
  }
  
  /// Adapts an async RSVP callback to the required signature
  Function(bool) _adaptRsvpCallback(Future<void> Function(bool) callback) {
    return (bool attending) {
      callback(attending);
      return true;
    };
  }
  
  /// No-op RSVP callback for when onRsvp is null
  bool _noOpRsvpCallback(bool attending) {
    return attending;
  }
  
  /// Adapts a simple repost callback to the required signature
  Function(Event, String?, RepostContentType) _adaptRepostCallback() {
    return (Event event, String? comment, RepostContentType type) {
      if (onRepost != null) {
        onRepost!();
      }
      return null;
    };
  }
} 