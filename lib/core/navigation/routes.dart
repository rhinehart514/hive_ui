import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';

/// Route path constants for the application
class AppRoutes {
  // Auth routes
  static const String landing = '/';
  static const String signIn = '/sign-in';
  static const String createAccount = '/create-account';
  static const String onboarding = '/onboarding';

  // Main app routes (Shell branches)
  static const String home = '/home'; // Maps to MainFeed in main_feed.dart
  static const String spaces = '/spaces';
  static const String profile = '/profile';

  // Settings routes
  static const String settings = '/settings';
  static const String accountSettings = '/settings/account';
  static const String privacySettings = '/settings/privacy';
  static const String notificationSettings = '/settings/notifications';
  static const String appearanceSettings = '/settings/appearance';
  
  // Repost routes
  static const String quoteRepost = '/quote-repost';

  // Test routes
  static const String eventCardTest = '/test/event-card';

  // Sub-routes
  // Home sub-routes
  static const String organizations = 'organizations';
  static const String organizationProfile = 'organizations/:organizationId';
  static const String hiveLab = 'hivelab';
  static const String createPost = 'post/create';

  // Spaces sub-routes
  static const String clubSpace = 'club'; // Legacy route - will be removed
  static const String spaceDetail = ':type/spaces/:id'; // New format
  static const String spacesRevamp = 'revamp';
  static const String createSpace = 'create';
  static const String createEvent = 'create-event';
  static const String spaceSearch = 'search';
  static const String spaceView = ':spaceId';

  // Messaging routes
  static const String messaging = '/messaging';
  static const String chat = '/messaging/chat/:chatId';
  static const String createChat = '/messaging/create';
  static const String groupMembers = '/messaging/chat/:chatId/members';

  // Admin routes
  static const String adminVerificationRequests =
      '/admin/verification-requests';

  // Developer routes
  static const String developerTools = '/dev/tools';

  // Profile sub-routes
  static const String profilePhoto = 'photo';

  // Full paths for direct navigation
  static String getOrganizationsPath() => '$home/$organizations';
  static String getOrganizationProfilePath(String id) =>
      '$home/organizations/$id';
  static String getHiveLabPath() => '$home/$hiveLab';
  static String getSpacesRevampPath() => '$spaces/$spacesRevamp';
  static String getSpaceDetailPath(String type, String id) => '$spaces/$type/spaces/$id';
  static String getLegacyClubSpacePath(String id) => '$spaces/$clubSpace?id=$id'; // Legacy - will be removed
  static String getCreateSpacePath() => '$spaces/$createSpace';
  static String getSpaceSearchPath() => '$spaces/$spaceSearch';
  static String getSpaceViewPath(String id) => '$spaces/$id';
  static String getCreateEventPath() => '$spaces/$createEvent';
}

/// Route parameter classes for type-safe navigation
class OrganizationRouteParams {
  final String organizationId;

  const OrganizationRouteParams({required this.organizationId});

  Map<String, String> toPathParameters() => {'organizationId': organizationId};
}

class ChatRouteParams {
  final String chatId;
  final String chatName;
  final String? chatAvatar;
  final bool isGroupChat;
  final List<String> participantIds;

  const ChatRouteParams({
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
    this.isGroupChat = false,
    this.participantIds = const [],
  });

  Map<String, String> toPathParameters() => {'chatId': chatId};

  Map<String, dynamic> toExtra() => {
        'chatName': chatName,
        'chatAvatar': chatAvatar,
        'isGroupChat': isGroupChat,
        'participantIds': participantIds,
      };
}

class GroupMembersRouteParams {
  final String chatId;

  const GroupMembersRouteParams({required this.chatId});

  Map<String, String> toPathParameters() => {'chatId': chatId};
}

/// Route parameters for space navigation
class SpaceRouteParams {
  final String spaceId;
  final String spaceType;
  final Space? space; // Optional space object for direct navigation

  const SpaceRouteParams({
    required this.spaceId,
    required this.spaceType,
    this.space,
  });

  Map<String, String> toPathParameters() => {
    'id': spaceId,
    'type': spaceType,
  };

  Map<String, dynamic>? toExtra() => space != null ? {'space': space} : null;
}

/// Legacy route parameters for club navigation
/// @deprecated Use SpaceRouteParams instead
@Deprecated('Use SpaceRouteParams instead')
class ClubSpaceRouteParams {
  final String clubId;
  final Club? club;

  const ClubSpaceRouteParams({
    required this.clubId,
    this.club,
  });

  Map<String, String> toQueryParameters() => {'id': clubId};
  
  Map<String, dynamic>? toExtra() => club != null ? {'club': club} : null;
}
