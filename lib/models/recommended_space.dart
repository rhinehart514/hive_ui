import 'package:hive_ui/models/space.dart';

/// Model representing a space recommended to a user in the feed
class RecommendedSpace {
  /// The actual space being recommended
  final Space space;
  
  /// Why this space is being recommended to the user
  final String? recommendationReason;

  /// Custom pitch for this space (for display purposes)
  final String? customPitch;

  /// Get display pitch from either customPitch or space description
  String get displayPitch => customPitch ?? space.description;

  /// Constructor
  const RecommendedSpace({
    required this.space,
    this.recommendationReason,
    this.customPitch,
  });
  
  /// Create a copy of this object with specified changes
  RecommendedSpace copyWith({
    Space? space,
    String? recommendationReason,
    String? customPitch,
  }) {
    return RecommendedSpace(
      space: space ?? this.space,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      customPitch: customPitch ?? this.customPitch,
    );
  }
} 