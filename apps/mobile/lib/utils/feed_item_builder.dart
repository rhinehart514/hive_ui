import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/feed_state.dart' hide SpaceRecommendation, HiveLabItem;
import '../models/repost_content_type.dart';
import '../components/event_card/event_card.dart';
import '../models/space_recommendation.dart';
import '../models/hive_lab_item.dart';
import '../components/feed/space_recommendation_card.dart';
import '../components/feed/hive_lab_card.dart';

/// Types of items that can appear in the feed
enum FeedItemType {
  /// A regular event
  event,
  
  /// A reposted event
  repost,
  
  /// A space recommendation
  spaceRecommendation,
  
  /// A HIVE lab item
  hiveLab,
}

/// A utility class for building feed items
class FeedItemBuilder {
  /// Build a feed item based on its type
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
        
      case FeedItemType.spaceRecommendation:
        final space = item as SpaceRecommendation;
        return SpaceRecommendationCard(space: space);
        
      case FeedItemType.hiveLab:
        final hiveLabItem = item as HiveLabItem;
        return HiveLabCard(item: hiveLabItem);
    }
  }
  
  /// Convert a string to a FeedItemType
  static FeedItemType stringToFeedItemType(String type) {
    switch (type) {
      case 'event':
        return FeedItemType.event;
      case 'repost':
        return FeedItemType.repost;
      case 'space_recommendation':
        return FeedItemType.spaceRecommendation;
      case 'hive_lab':
        return FeedItemType.hiveLab;
      default:
        debugPrint('Warning: Unknown feed item type string: $type. Defaulting to event.');
        return FeedItemType.event;
    }
  }
} 