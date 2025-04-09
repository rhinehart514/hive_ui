import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/event.dart';
import '../../../../models/repost_content_type.dart';
import '../../../../models/feed_state.dart';
import '../../../../models/space_recommendation.dart' as model;
import '../../../../widgets/feed_event_card.dart';
import '../../../../services/analytics_service.dart';
import '../../../../components/feed/space_recommendation_card.dart';
import '../../../../components/moderation/report_dialog.dart';
import '../../../../features/moderation/domain/entities/content_report_entity.dart';

/// A reusable widget for displaying the feed items
class FeedList extends ConsumerWidget {
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
  const FeedList({
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
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
              foregroundColor: AppColors.gold,
              backgroundColor: AppColors.cardBackground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.gold),
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
    
    switch (type) {
      case 'event':
        final event = data as Event;
        return FeedEventCard(
          key: ValueKey('event_${event.id}'),
          event: event,
          onTap: (e) => onNavigateToEventDetails(e),
          onRsvp: (e) => onRsvpToEvent(e),
          onRepost: (e, comment, type) => _handleRepost(context, e, comment, type),
          onReport: (e) => _handleReport(context, e),
        );
        
      case 'repost':
        final repost = data as RepostItem;
        return FeedEventCard(
          key: ValueKey('repost_${repost.event.id}_${repost.repostTime.millisecondsSinceEpoch}'),
          event: repost.event,
          isRepost: true,
          repostedBy: repost.reposterProfile,
          repostTime: repost.repostTime,
          quoteText: repost.comment,
          repostType: repost.contentType,
          onTap: (e) => onNavigateToEventDetails(e),
          onRsvp: (e) => onRsvpToEvent(e),
          onRepost: (e, comment, type) => _handleRepost(context, e, comment, type),
          onReport: (e) => _handleReport(context, e),
        );
        
      case 'spaceRecommendation':
        final space = data as model.SpaceRecommendation;
        return SpaceRecommendationCard(
          space: space,
          onTap: () {
            // Analytics tracking
            AnalyticsService.logEvent('space_recommendation_tapped', parameters: {
              'space_id': space.id,
              'space_name': space.name,
              'space_category': space.category,
            });
          },
        );
        
      default:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Unsupported content type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }
  
  /// Build a space recommendation card
  Widget _buildSpaceRecommendationCard(model.SpaceRecommendation space) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Recommended Space',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Space info
          Row(
            children: [
              // Space image
              if (space.imageUrl != null)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(space.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardBackground,
                  ),
                  child: const Icon(
                    Icons.group,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                
              // Space details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      space.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gold.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Description
          if (space.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                space.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
          // Member count
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${space.memberCount} members',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // View button
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Navigate to space details page
                  debugPrint('Navigate to space: ${space.id}');
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.gold.withOpacity(0.1),
                  foregroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                  ),
                ),
                child: const Text('View Space'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRepost(BuildContext context, Event event, String? comment, RepostContentType type) {
    // Directly call the parent handler which already has auth checking
    onRepost(event, comment, type);
  }
  
  void _handleReport(BuildContext context, Event event) {
    showReportDialog(
      context,
      contentId: event.id,
      contentType: ReportedContentType.event,
      contentPreview: event.title,
      ownerId: event.createdBy,
    );
  }
} 