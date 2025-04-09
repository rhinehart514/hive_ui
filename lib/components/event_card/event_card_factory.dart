import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/repost_content_type.dart' as repost_type;
import '../../models/repost_item.dart';
import 'event_card.dart';

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

/// Factory class for creating event cards
class EventCardFactory {
  /// Build the card using the specified variant
  Widget buildCard({
    required Event event,
    required EventCardVariant variant,
    Function(Event)? onTap,
    Function(Event)? onRsvp,
    Function(Event, String?, repost_type.RepostContentType)? onRepost,
    Function(Event)? onReport,
    RepostItem? repost,
    required BuildContext context,
  }) {
    // For backward compatibility, we'll use the HiveEventCard directly
    // which is our new premium event card for all variants
    return HiveEventCard(
      event: event,
      isRepost: variant == EventCardVariant.reposted,
      repostedBy: repost?.reposterProfile,
      repostTimestamp: repost?.repostTime,
      quoteText: repost?.comment,
      repostType: repost?.type != null 
          ? repost_type.RepostContentType.values[repost!.type.index]
          : repost_type.RepostContentType.standard,
      onTap: onTap,
      onRsvp: onRsvp,
      onRepost: onRepost,
      onReport: onReport,
    );
  }
} 