import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Needed for context
import 'package:firebase_auth/firebase_auth.dart'; // Needed for RSVP status
import '../models/event.dart';
import '../models/repost_content_type.dart';
import '../models/user_profile.dart'; // Needed for repostedBy
// Import the HiveEventCard component
import '../../components/event_card/event_card.dart' as HiveComponents;

/// A wrapper widget in the feed that uses the HiveEventCard component.
class FeedEventCard extends ConsumerWidget { // Changed to ConsumerWidget for potential provider reads
  /// The event to display
  final Event event;
  
  /// Whether this is a reposted event
  final bool isRepost;
  
  /// User who reposted this event (if isRepost is true)
  final UserProfile? repostedBy; // Changed from reposterName
  
  /// Timestamp of the repost (if isRepost is true)
  final DateTime? repostTime;
  
  /// Quote text for quote reposts
  final String? quoteText;
  
  /// Type of repost
  final RepostContentType repostType;
  
  /// Called when the user taps the card
  final Function(Event)? onTap;
  
  /// Called when the user RSVPs to the event
  final Function(Event)? onRsvp;
  
  /// Called when the user reposts the event
  final Function(Event, String?, RepostContentType)? onRepost;

  // Removed heroTag as it's not used by HiveEventCard
  // Removed isFeatured as it's not directly passed, logic internal/TBD

  const FeedEventCard({
    Key? key,
    required this.event,
    this.isRepost = false,
    this.repostedBy, // Updated
    this.repostTime, // Renamed from repostTimestamp for consistency
    this.quoteText,
    this.repostType = RepostContentType.standard,
    this.onTap,
    this.onRsvp,
    this.onRepost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Determine followsClub status (e.g., from a provider)
    final bool followsClub = false; 
    // TODO: Get todayBoosts (e.g., from a user state provider)
    final List<DateTime> todayBoosts = []; 

    // Directly return the HiveEventCard, passing all relevant props.
    // The HiveEventCard itself handles the different display logic 
    // for standard events, reposts, and quote reposts internally.
    return HiveComponents.HiveEventCard(
      event: event,
      isRepost: isRepost,
      repostedBy: repostedBy,
      repostTimestamp: repostTime, 
      quoteText: quoteText,
      repostType: repostType,
      onTap: onTap != null ? (e) => onTap!(e) : null,
      onRsvp: onRsvp != null ? (e) => onRsvp!(e) : null,
      onRepost: onRepost, // Pass directly
      followsClub: followsClub, // Pass determined/default value
      todayBoosts: todayBoosts, // Pass determined/default value
    );
  }
} 