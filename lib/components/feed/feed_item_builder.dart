import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/feed_state.dart' hide SpaceRecommendation, HiveLabItem;
import '../../models/repost_content_type.dart';
import '../../models/user_profile.dart';
import '../../models/space_recommendation.dart';
import '../../models/hive_lab_item.dart';
import '../../features/feed/domain/models/quote_item.dart';
import '../feed/space_recommendation_card.dart';
import '../feed/hive_lab_card.dart';
import '../event_card/event_card.dart';
import '../feed/feed_event_card.dart';
import '../feed/quote_card.dart';

/// A utility class for building feed items based on their type
class FeedItemBuilder {
  /// Build a feed item based on its type and data
  static Widget buildFeedItem({
    required FeedItemType type,
    required dynamic item,
    required Function(Event) onTap,
    required Function(Event) onRsvp,
    required Function(Event, String?, RepostContentType) onRepost,
  }) {
    switch (type) {
      case FeedItemType.event:
        final event = item as Event;
        return HiveEventCard(
          key: ValueKey('event_${event.id}'),
          event: event,
          onTap: onTap,
          onRsvp: onRsvp,
          onRepost: onRepost,
          isRepost: false,
          followsClub: false,
          todayBoosts: const [],
          repostType: RepostContentType.standard,
        );
        
      case FeedItemType.repost:
        final repost = item as RepostItem;
        return HiveEventCard(
          key: ValueKey('repost_${repost.event.id}_${repost.repostTime.millisecondsSinceEpoch}'),
          event: repost.event,
          isRepost: true,
          repostedBy: repost.reposterProfile,
          repostTimestamp: repost.repostTime,
          quoteText: repost.comment,
          repostType: repost.contentType,
          onTap: onTap,
          onRsvp: onRsvp,
          onRepost: onRepost,
          followsClub: false,
          todayBoosts: const [],
        );

      case FeedItemType.quote:
        final quote = item as QuoteItem;
        return QuoteCard(
          key: ValueKey('quote_${quote.id}'),
          quote: quote,
          onEventTap: onTap,
          onEventRsvp: onRsvp,
          onEventRepost: onRepost,
        );
            
      case FeedItemType.spaceRecommendation:
        final space = item as SpaceRecommendation;
        return SpaceRecommendationCard(space: space);
        
      case FeedItemType.hiveLab:
        final hiveLabItem = item as HiveLabItem;
        return HiveLabCard(item: hiveLabItem);

      case FeedItemType.boostedEvent:
        final event = item as Event;
        return HiveEventCard(
          key: ValueKey('boosted_${event.id}'),
          event: event,
          onTap: onTap,
          onRsvp: onRsvp,
          onRepost: onRepost,
          isRepost: false,
          followsClub: false,
          todayBoosts: const [],
          repostType: RepostContentType.standard,
        );

      case FeedItemType.friendRecommendation:
        // TODO: Implement friend recommendation card
        return const SizedBox.shrink(); // Return empty widget for now
    }
  }
  
  /// Convert a string type to FeedItemType enum
  static FeedItemType stringToFeedItemType(String typeString) {
    switch (typeString) {
      case 'event':
        return FeedItemType.event;
      case 'repost':
        return FeedItemType.repost;
      case 'quote':
        return FeedItemType.quote;
      case 'spaceRecommendation':
        return FeedItemType.spaceRecommendation;
      case 'hiveLab':
        return FeedItemType.hiveLab;
      case 'boostedEvent':
        return FeedItemType.boostedEvent;
      case 'friendRecommendation':
        return FeedItemType.friendRecommendation;
      default:
        return FeedItemType.event; // Default fallback
    }
  }
} 