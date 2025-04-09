import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_item.dart';
import 'package:hive_ui/models/repost_content_type.dart' as repost_type;
import 'package:hive_ui/features/visibility/domain/entities/visibility_boost_entity.dart';
import 'package:hive_ui/components/event_card/event_card.dart';

/// Used to track the type of event card to display
enum EventCardVariant {
  /// Standard event card
  standard,
  
  /// Boosted event card - manual boost by verified+ users
  boosted,
  
  /// Honey mode card - special monthly highlight
  honeyMode,
  
  /// Reposted card showing a user's repost of an event
  reposted,
  
  /// Low RSVP card - event that needs more attendees
  lowRsvp,
  
  /// Last minute card - urgent event happening soon
  lastMinute
}

/// Factory to create the appropriate event card based on properties
class EventCardFactory {
  /// Get the appropriate event card variant based on event properties
  static EventCardVariant getVariant({
    required Event event,
    RepostItem? repost,
    VisibilityBoostEntity? boost,
    required DateTime now,
  }) {
    // If the event is reposted, that takes precedence
    if (repost != null) {
      return EventCardVariant.reposted;
    }
    
    // Check if the event has a honey mode boost
    if (boost != null && boost.boostType == BoostType.honeyMode && !boost.isExpired) {
      return EventCardVariant.honeyMode;
    }
    
    // Check if the event has a standard boost
    if (boost != null && boost.boostType == BoostType.standard && !boost.isExpired) {
      return EventCardVariant.boosted;
    }
    
    // Check if it's a last-minute event (happening within 3 hours)
    final timeDiff = event.startDate.difference(now);
    if (timeDiff.inHours <= 3 && timeDiff.isNegative == false) {
      return EventCardVariant.lastMinute;
    }
    
    // Check if it has low RSVPs (less than 5 people and happening in more than 24 hours)
    if (event.attendees.length < 5 && event.startDate.difference(now).inHours > 24) {
      return EventCardVariant.lowRsvp;
    }
    
    // Default to standard card
    return EventCardVariant.standard;
  }
  
  /// Build the appropriate card based on the variant and properties
  static Widget buildCard({
    required Event event,
    required Function(Event) onTap,
    Function(Event)? onRsvp,
    Function(Event)? onReport,
    Function(Event, String?, repost_type.RepostContentType)? onRepost,
    RepostItem? repost,
    VisibilityBoostEntity? boost,
    required String spaceName,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final DateTime now = DateTime.now();
    final variant = getVariant(
      event: event,
      repost: repost,
      boost: boost,
      now: now,
    );
    
    // For all variants, we'll use the HiveEventCard directly 
    // for a consistent premium look across the app
    return HiveEventCard(
      event: event,
      isRepost: variant == EventCardVariant.reposted,
      repostedBy: repost?.reposterProfile,
      repostTimestamp: repost?.repostTime,
      quoteText: repost?.comment,
      onTap: onTap,
      onRsvp: onRsvp,
      onReport: onReport,
      onRepost: onRepost,
    );
  }
} 