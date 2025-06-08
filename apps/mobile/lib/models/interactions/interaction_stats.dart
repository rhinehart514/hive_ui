import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'interaction.dart';

/// Statistics about user interactions with an entity (event, space)
@immutable
class InteractionStats {
  /// ID of the entity these stats are for
  final String entityId;

  /// Type of entity (event, space, etc.)
  final EntityType entityType;

  /// Total number of views
  final int viewCount;

  /// Total number of RSVPs/saves
  final int rsvpCount;

  /// Total number of shares
  final int shareCount;

  /// Total number of comments
  final int commentCount;

  /// Click-through rate (percentage of views that result in clicks)
  final double ctr;

  /// Conversion rate (percentage of views that result in RSVPs)
  final double conversionRate;

  /// Engagement score (calculated based on multiple interaction types)
  final double engagementScore;

  /// Last time these stats were updated
  final DateTime lastUpdated;

  /// Map of action types to counts
  final Map<String, int> actionCounts;

  const InteractionStats({
    required this.entityId,
    required this.entityType,
    this.viewCount = 0,
    this.rsvpCount = 0,
    this.shareCount = 0,
    this.commentCount = 0,
    this.ctr = 0.0,
    this.conversionRate = 0.0,
    this.engagementScore = 0.0,
    required this.lastUpdated,
    this.actionCounts = const {},
  });

  /// Create stats from Firestore document
  factory InteractionStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final entityTypeStr = data['entityType'] as String;

    // Parse entity type from string
    EntityType entityType;
    switch (entityTypeStr) {
      case 'event':
        entityType = EntityType.event;
        break;
      case 'space':
        entityType = EntityType.space;
        break;
      case 'profile':
        entityType = EntityType.profile;
        break;
      case 'post':
        entityType = EntityType.post;
        break;
      default:
        throw ArgumentError('Unknown entity type: $entityTypeStr');
    }

    return InteractionStats(
      entityId: data['entityId'] as String,
      entityType: entityType,
      viewCount: data['viewCount'] as int? ?? 0,
      rsvpCount: data['rsvpCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      ctr: (data['ctr'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (data['conversionRate'] as num?)?.toDouble() ?? 0.0,
      engagementScore: (data['engagementScore'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      actionCounts: (data['actionCounts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
    );
  }

  /// Helper method to parse timestamp from different formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return DateTime.now(); // Fallback to current time
    }
  }

  /// Convert stats to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'entityId': entityId,
      'entityType': entityType.toString().split('.').last,
      'viewCount': viewCount,
      'rsvpCount': rsvpCount,
      'shareCount': shareCount,
      'commentCount': commentCount,
      'ctr': ctr,
      'conversionRate': conversionRate,
      'engagementScore': engagementScore,
      'lastUpdated': FieldValue.serverTimestamp(),
      'actionCounts': actionCounts,
    };
  }

  /// Create a new stats object by incrementing a specific action count
  InteractionStats incrementAction(InteractionAction action) {
    final newCounts = Map<String, int>.from(actionCounts);
    final actionKey = action.toString().split('.').last;

    newCounts[actionKey] = (newCounts[actionKey] ?? 0) + 1;

    // Update specific counters
    int newViewCount = viewCount;
    int newRsvpCount = rsvpCount;
    int newShareCount = shareCount;
    int newCommentCount = commentCount;

    switch (action) {
      case InteractionAction.view:
        newViewCount++;
        break;
      case InteractionAction.rsvp:
      case InteractionAction.save:
        newRsvpCount++;
        break;
      case InteractionAction.share:
        newShareCount++;
        break;
      case InteractionAction.comment:
        newCommentCount++;
        break;
      default:
        // Other action types just update the action counts map
        break;
    }

    // Calculate new metrics
    final newCtr = newViewCount > 0
        ? (newCounts['click'] ?? 0) / newViewCount.toDouble()
        : 0.0;

    final newConversionRate =
        newViewCount > 0 ? newRsvpCount / newViewCount.toDouble() : 0.0;

    // Calculate engagement score (weighted sum of different interactions)
    final newEngagementScore = _calculateEngagementScore(
      viewCount: newViewCount,
      rsvpCount: newRsvpCount,
      shareCount: newShareCount,
      commentCount: newCommentCount,
    );

    return InteractionStats(
      entityId: entityId,
      entityType: entityType,
      viewCount: newViewCount,
      rsvpCount: newRsvpCount,
      shareCount: newShareCount,
      commentCount: newCommentCount,
      ctr: newCtr,
      conversionRate: newConversionRate,
      engagementScore: newEngagementScore,
      lastUpdated: DateTime.now(),
      actionCounts: newCounts,
    );
  }

  /// Calculate engagement score based on different interaction types
  static double _calculateEngagementScore({
    required int viewCount,
    required int rsvpCount,
    required int shareCount,
    required int commentCount,
  }) {
    // Weight factors for different actions
    const double viewWeight = 1.0;
    const double rsvpWeight = 10.0;
    const double shareWeight = 15.0;
    const double commentWeight = 8.0;

    // Calculate weighted sum
    final double totalScore = (viewCount * viewWeight) +
        (rsvpCount * rsvpWeight) +
        (shareCount * shareWeight) +
        (commentCount * commentWeight);

    // Normalize to a 0-10 scale
    // Using log scale to prevent outliers from skewing the score too much
    if (totalScore <= 0) return 0.0;

    // Log scale maxes out at 500 interactions (which gives a 10)
    const double maxScore = 500.0;
    return (10.0 * math.min(totalScore, maxScore) / maxScore);
  }

  /// Create an empty stats object with default values
  factory InteractionStats.empty(String entityId, EntityType entityType) {
    return InteractionStats(
      entityId: entityId,
      entityType: entityType,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy of this stats object with some fields replaced
  InteractionStats copyWith({
    String? entityId,
    EntityType? entityType,
    int? viewCount,
    int? rsvpCount,
    int? shareCount,
    int? commentCount,
    double? ctr,
    double? conversionRate,
    double? engagementScore,
    DateTime? lastUpdated,
    Map<String, int>? actionCounts,
  }) {
    return InteractionStats(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      viewCount: viewCount ?? this.viewCount,
      rsvpCount: rsvpCount ?? this.rsvpCount,
      shareCount: shareCount ?? this.shareCount,
      commentCount: commentCount ?? this.commentCount,
      ctr: ctr ?? this.ctr,
      conversionRate: conversionRate ?? this.conversionRate,
      engagementScore: engagementScore ?? this.engagementScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      actionCounts: actionCounts ?? this.actionCounts,
    );
  }
}
