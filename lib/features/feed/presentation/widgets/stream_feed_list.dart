import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/features/feed/presentation/widgets/feed_item_factory.dart';

/// A widget specifically designed to display the feed items from the live stream provider.
class StreamFeedList extends ConsumerWidget {
  /// The list of feed items (Map<String, dynamic>) from the stream.
  final List<Map<String, dynamic>> feedItems;

  /// Callback when navigating to an event.
  final Function(Event) onNavigateToEventDetails;

  /// Callback when RSVPing to an event.
  final Function(Event) onRsvpToEvent;

  /// Callback when reposting an event.
  final Function(Event, String?, RepostContentType) onRepost;

  /// Constructor
  const StreamFeedList({
    Key? key,
    required this.feedItems,
    required this.onNavigateToEventDetails,
    required this.onRsvpToEvent,
    required this.onRepost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      // Add padding to avoid overlap with AppBar/BottomNav if necessary
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), 
      itemCount: feedItems.length,
      itemBuilder: (context, index) {
        final itemData = feedItems[index];
        
        // Use the factory to build the appropriate widget based on item type
        // Pass the necessary callbacks down to the factory or the widgets it creates
        // Assuming FeedItemFactory can handle the callbacks or they are attached within the factory
        // TODO: Verify how callbacks are handled by FeedItemFactory and adjust if needed.
        return FeedItemFactory.createFeedItem(
          ref,
          itemData,
          onNavigateToEventDetails: onNavigateToEventDetails,
          onRsvpToEvent: onRsvpToEvent,
          onRepost: onRepost,
        );
      },
    );
  }
} 