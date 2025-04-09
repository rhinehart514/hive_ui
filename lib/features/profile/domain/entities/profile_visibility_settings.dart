/// Defines the granular visibility settings for a user profile
class ProfileVisibilitySettings {
  /// The user ID that these settings belong to
  final String userId;
  
  /// Controls if the profile is publicly discoverable
  final bool isDiscoverable;
  
  /// Controls if the user's events are visible to non-connections
  final bool showEventsToPublic;
  
  /// Controls if the user's spaces are visible to non-connections
  final bool showSpacesToPublic;
  
  /// Controls if the user's friend list is visible to non-connections
  final bool showFriendsToPublic;
  
  /// Controls who can send friend requests to the user
  final PrivacyLevel friendRequestsPrivacy;
  
  /// Controls who can see user's activity feed
  final PrivacyLevel activityFeedPrivacy;
  
  /// When these settings were last updated
  final DateTime updatedAt;

  /// Constructor
  const ProfileVisibilitySettings({
    required this.userId,
    this.isDiscoverable = true,
    this.showEventsToPublic = true,
    this.showSpacesToPublic = true,
    this.showFriendsToPublic = false,
    this.friendRequestsPrivacy = PrivacyLevel.everyone,
    this.activityFeedPrivacy = PrivacyLevel.friends,
    required this.updatedAt,
  });

  /// Create default settings for a new user
  factory ProfileVisibilitySettings.defaultSettings(String userId) => ProfileVisibilitySettings(
    userId: userId,
    updatedAt: DateTime.now(),
  );

  /// Create a copy with updated fields
  ProfileVisibilitySettings copyWith({
    String? userId,
    bool? isDiscoverable,
    bool? showEventsToPublic,
    bool? showSpacesToPublic,
    bool? showFriendsToPublic,
    PrivacyLevel? friendRequestsPrivacy,
    PrivacyLevel? activityFeedPrivacy,
    DateTime? updatedAt,
  }) {
    return ProfileVisibilitySettings(
      userId: userId ?? this.userId,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      showEventsToPublic: showEventsToPublic ?? this.showEventsToPublic,
      showSpacesToPublic: showSpacesToPublic ?? this.showSpacesToPublic,
      showFriendsToPublic: showFriendsToPublic ?? this.showFriendsToPublic,
      friendRequestsPrivacy: friendRequestsPrivacy ?? this.friendRequestsPrivacy,
      activityFeedPrivacy: activityFeedPrivacy ?? this.activityFeedPrivacy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isDiscoverable': isDiscoverable,
      'showEventsToPublic': showEventsToPublic,
      'showSpacesToPublic': showSpacesToPublic,
      'showFriendsToPublic': showFriendsToPublic,
      'friendRequestsPrivacy': friendRequestsPrivacy.name,
      'activityFeedPrivacy': activityFeedPrivacy.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ProfileVisibilitySettings.fromJson(Map<String, dynamic> json) {
    return ProfileVisibilitySettings(
      userId: json['userId'] as String,
      isDiscoverable: json['isDiscoverable'] as bool? ?? true,
      showEventsToPublic: json['showEventsToPublic'] as bool? ?? true,
      showSpacesToPublic: json['showSpacesToPublic'] as bool? ?? true,
      showFriendsToPublic: json['showFriendsToPublic'] as bool? ?? false,
      friendRequestsPrivacy: PrivacyLevel.fromString(json['friendRequestsPrivacy'] as String? ?? 'everyone'),
      activityFeedPrivacy: PrivacyLevel.fromString(json['activityFeedPrivacy'] as String? ?? 'friends'),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.now(),
    );
  }
}

/// Privacy level enum to control visibility of profile features
enum PrivacyLevel {
  /// Visible to everyone
  everyone,
  
  /// Visible to friends only
  friends,
  
  /// Visible only to the user
  private;
  
  /// Convert string to privacy level
  static PrivacyLevel fromString(String value) {
    return PrivacyLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => PrivacyLevel.everyone,
    );
  }
} 