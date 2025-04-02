import 'package:flutter/foundation.dart';

/// A simplified model for space recommendations
@immutable
class SpaceRecommendationSimple {
  /// The name of the space
  final String name;
  
  /// A brief description or pitch for the space
  final String description;
  
  /// URL for the space's image
  final String? imageUrl;
  
  /// Primary category or tag for the space
  final String category;
  
  /// Recommendation score (0.0 to 1.0)
  final double score;

  /// Constructor
  const SpaceRecommendationSimple({
    required this.name,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.score,
  });

  /// Create from JSON map
  factory SpaceRecommendationSimple.fromJson(Map<String, dynamic> json) {
    return SpaceRecommendationSimple(
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'score': score,
    };
  }
  
  /// Create a copy with some fields replaced
  SpaceRecommendationSimple copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    double? score,
  }) {
    return SpaceRecommendationSimple(
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      score: score ?? this.score,
    );
  }
} 