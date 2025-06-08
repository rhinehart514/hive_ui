import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';

/// Data model for profile visibility settings
class ProfileVisibilitySettingsModel extends ProfileVisibilitySettings {
  /// Constructor
  const ProfileVisibilitySettingsModel({
    required super.userId,
    super.isDiscoverable = true,
    super.showEventsToPublic = true,
    super.showSpacesToPublic = true,
    super.showFriendsToPublic = false,
    super.friendRequestsPrivacy = PrivacyLevel.everyone,
    super.activityFeedPrivacy = PrivacyLevel.friends,
    required super.updatedAt,
  });

  /// Create from domain entity
  factory ProfileVisibilitySettingsModel.fromEntity(ProfileVisibilitySettings entity) {
    return ProfileVisibilitySettingsModel(
      userId: entity.userId,
      isDiscoverable: entity.isDiscoverable,
      showEventsToPublic: entity.showEventsToPublic,
      showSpacesToPublic: entity.showSpacesToPublic,
      showFriendsToPublic: entity.showFriendsToPublic,
      friendRequestsPrivacy: entity.friendRequestsPrivacy,
      activityFeedPrivacy: entity.activityFeedPrivacy,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create from Firestore JSON data
  factory ProfileVisibilitySettingsModel.fromFirestore(Map<String, dynamic> json) {
    return ProfileVisibilitySettingsModel(
      userId: json['userId'] as String,
      isDiscoverable: json['isDiscoverable'] as bool? ?? true,
      showEventsToPublic: json['showEventsToPublic'] as bool? ?? true,
      showSpacesToPublic: json['showSpacesToPublic'] as bool? ?? true,
      showFriendsToPublic: json['showFriendsToPublic'] as bool? ?? false,
      friendRequestsPrivacy: PrivacyLevel.fromString(json['friendRequestsPrivacy'] as String? ?? 'everyone'),
      activityFeedPrivacy: PrivacyLevel.fromString(json['activityFeedPrivacy'] as String? ?? 'friends'),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Map<String, dynamic>).containsKey('seconds')
              ? DateTime.fromMillisecondsSinceEpoch(
                  (json['updatedAt']['seconds'] as int) * 1000)
              : DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'isDiscoverable': isDiscoverable,
      'showEventsToPublic': showEventsToPublic,
      'showSpacesToPublic': showSpacesToPublic,
      'showFriendsToPublic': showFriendsToPublic,
      'friendRequestsPrivacy': friendRequestsPrivacy.name,
      'activityFeedPrivacy': activityFeedPrivacy.name,
      'updatedAt': updatedAt,
    };
  }
} 