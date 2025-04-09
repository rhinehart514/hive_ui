import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/repost_content_type.dart';
import '../utils/feed_item_builder.dart';

/// A wrapper widget for the feed list that ensures proper parent-child widget relationships
class FeedListWrapper extends StatelessWidget {
  /// The list of feed items to display
  final List<Map<String, dynamic>> feedItems;
  
  /// Whether more items are being loaded
  final bool isLoadingMore;
  
  /// Whether there are more items to load
  final bool hasMoreEvents;
  
  /// Scroll controller for the list
  final ScrollController scrollController;
  
  /// Callback when loading more items
  final VoidCallback onLoadMore;
  
  /// Callback when navigating to an event
  final Function(Event) onNavigateToEventDetails;
  
  /// Callback when RSVPing to an event
  final Function(Event) onRsvpToEvent;
  
  /// Callback when reposting an event
  final Function(Event, String?, RepostContentType) onRepost;
  
  /// Constructor
  const FeedListWrapper({
    Key? key,
    required this.feedItems,
    required this.isLoadingMore,
    required this.hasMoreEvents,
    required this.scrollController,
    required this.onLoadMore,
    required this.onNavigateToEventDetails,
    required this.onRsvpToEvent,
    required this.onRepost,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: feedItems.length + 1, // +1 for load more indicator
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == feedItems.length) {
          return _buildLoadMore();
        }
        
        return _buildFeedItem(context, feedItems[index]);
      },
    );
  }
  
  /// Build the load more indicator or padding at the end of the list
  Widget _buildLoadMore() {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)), // AppColors.gold
            strokeWidth: 2.0,
          ),
        ),
      );
    } else if (hasMoreEvents) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: TextButton(
            onPressed: onLoadMore,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFD700), // AppColors.gold
              backgroundColor: const Color(0xFF1C1C1E), // AppColors.cardBackground
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFFFD700)), // AppColors.gold
              ),
            ),
            child: const Text('Load More'),
          ),
        ),
      );
    } else {
      return const SizedBox(height: 40); // Bottom padding
    }
  }
  
  /// Build a feed item based on its type
  Widget _buildFeedItem(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'] as String;
    final data = item['data'];
    
    // Convert the string type to FeedItemType enum
    final itemType = FeedItemBuilder.stringToFeedItemType(type);
    
    // Use the feed item builder to create the appropriate widget
    return FeedItemBuilder.buildFeedItem(
      type: itemType,
      item: data,
      onTap: onNavigateToEventDetails,
      onRsvp: onRsvpToEvent,
      onRepost: onRepost,
    );
  }
} 