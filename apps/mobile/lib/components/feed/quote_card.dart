import 'package:flutter/material.dart';
import '../../features/feed/domain/models/quote_item.dart';
import '../../models/event.dart';
import '../../models/repost_content_type.dart';
import '../event_card/event_card.dart';

/// A card widget for displaying a quote in the feed
class QuoteCard extends StatelessWidget {
  /// The quote to display
  final QuoteItem quote;

  /// Callback when the card is tapped
  final void Function(Event) onEventTap;

  /// Callback when the RSVP button is tapped
  final void Function(Event) onEventRsvp;

  /// Callback when the repost button is tapped
  final void Function(Event, String?, RepostContentType) onEventRepost;

  /// Constructor
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onEventTap,
    required this.onEventRsvp,
    required this.onEventRepost,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote author info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: quote.author.profileImageUrl != null
                      ? NetworkImage(quote.author.profileImageUrl!)
                      : null,
                  child: quote.author.profileImageUrl == null
                      ? Text(quote.author.displayName[0])
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  quote.author.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Quote text
          if (quote.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                quote.content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          // Embedded event card
          HiveEventCard(
            event: quote.event,
            onTap: (event) => onEventTap(event),
            onRsvp: (event) => onEventRsvp(event),
            onRepost: (event, comment, type) => onEventRepost(event, comment, type),
            isQuoted: true,
          ),
        ],
      ),
    );
  }

  /// Format the timestamp into a readable string
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      // Format as date if more than a week old
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      // Format as days ago
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      // Format as hours ago
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      // Format as minutes ago
      return '${difference.inMinutes}m';
    } else {
      // Just now
      return 'now';
    }
  }
} 