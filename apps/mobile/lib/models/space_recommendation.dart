import 'package:flutter/foundation.dart';

/// Model class for space recommendations in the feed
@immutable
class SpaceRecommendation {
  /// Unique identifier for the space
  final String id;
  
  /// Name of the space
  final String name;
  
  /// Description of the space
  final String description;
  
  /// URL for the space's image
  final String? imageUrl;
  
  /// Category of the space (e.g., "Academic", "Social", "Professional")
  final String category;
  
  /// Number of members in the space
  final int memberCount;
  
  /// Whether this space is recommended based on user's friends
  final bool isFromFriends;
  
  /// Whether this space is recommended based on user's RSVP history
  final bool isFromRsvp;
  
  /// Whether this space is recommended based on user's repost history
  final bool isFromReposts;

  /// Constructor
  const SpaceRecommendation({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.memberCount,
    this.isFromFriends = false,
    this.isFromRsvp = false,
    this.isFromReposts = false,
  });

  /// Create from JSON map
  factory SpaceRecommendation.fromJson(Map<String, dynamic> json) {
    return SpaceRecommendation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String? ?? 'Other',
      memberCount: json['memberCount'] as int,
      isFromFriends: json['isFromFriends'] as bool? ?? false,
      isFromRsvp: json['isFromRsvp'] as bool? ?? false,
      isFromReposts: json['isFromReposts'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'memberCount': memberCount,
      'isFromFriends': isFromFriends,
      'isFromRsvp': isFromRsvp,
      'isFromReposts': isFromReposts,
    };
  }

  /// Create a copy with some fields replaced
  SpaceRecommendation copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    int? memberCount,
    bool? isFromFriends,
    bool? isFromRsvp,
    bool? isFromReposts,
  }) {
    return SpaceRecommendation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      isFromFriends: isFromFriends ?? this.isFromFriends,
      isFromRsvp: isFromRsvp ?? this.isFromRsvp,
      isFromReposts: isFromReposts ?? this.isFromReposts,
    );
  }
} 