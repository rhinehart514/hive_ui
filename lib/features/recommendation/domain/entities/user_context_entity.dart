/// Entity representing a user's context for recommendation purposes
class UserContextEntity {
  /// User identifier
  final String userId;
  
  /// User interests and preferences
  final List<String> interests;
  
  /// IDs of spaces the user has joined
  final List<String> joinedSpaceIds;
  
  /// Recent interactions (e.g., clicks, views, RSVPs)
  final List<UserInteractionEntity> recentInteractions;
  
  /// User's current location (if available)
  final LocationContext? location;
  
  /// Time context (time of day, day of week, etc.)
  final TimeContext timeContext;
  
  /// User's social graph data
  final SocialGraphContext socialGraph;
  
  /// User's activity data (e.g., events attended, posts created)
  final ActivityContext activityContext;
  
  /// Academic context (major, year, courses)
  final AcademicContext academicContext;
  
  /// Constructor
  const UserContextEntity({
    required this.userId,
    required this.interests,
    required this.joinedSpaceIds,
    required this.recentInteractions,
    this.location,
    required this.timeContext,
    required this.socialGraph,
    required this.activityContext,
    required this.academicContext,
  });
  
  /// Create a copy with modified fields
  UserContextEntity copyWith({
    String? userId,
    List<String>? interests,
    List<String>? joinedSpaceIds,
    List<UserInteractionEntity>? recentInteractions,
    LocationContext? location,
    TimeContext? timeContext,
    SocialGraphContext? socialGraph,
    ActivityContext? activityContext,
    AcademicContext? academicContext,
  }) {
    return UserContextEntity(
      userId: userId ?? this.userId,
      interests: interests ?? this.interests,
      joinedSpaceIds: joinedSpaceIds ?? this.joinedSpaceIds,
      recentInteractions: recentInteractions ?? this.recentInteractions,
      location: location ?? this.location,
      timeContext: timeContext ?? this.timeContext,
      socialGraph: socialGraph ?? this.socialGraph,
      activityContext: activityContext ?? this.activityContext,
      academicContext: academicContext ?? this.academicContext,
    );
  }
}

/// Entity representing a user's interaction with content
class UserInteractionEntity {
  /// Unique identifier for the interaction
  final String id;
  
  /// User identifier
  final String userId;
  
  /// Content identifier
  final String contentId;
  
  /// Type of content (e.g., event, space, post)
  final String contentType;
  
  /// Type of interaction (e.g., view, click, RSVP)
  final InteractionType interactionType;
  
  /// Timestamp of the interaction
  final DateTime timestamp;
  
  /// Duration of the interaction (if applicable)
  final Duration? duration;
  
  /// Additional context data about the interaction
  final Map<String, dynamic>? metadata;
  
  /// Constructor
  const UserInteractionEntity({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.interactionType,
    required this.timestamp,
    this.duration,
    this.metadata,
  });
}

/// Types of user interactions with content
enum InteractionType {
  /// Viewing content
  view,
  
  /// Clicking or tapping on content
  click,
  
  /// RSVPing to an event
  rsvp,
  
  /// Joining a space
  join,
  
  /// Creating content
  create,
  
  /// Sharing or reposting content
  share,
  
  /// Liking or favoriting content
  like,
  
  /// Commenting on content
  comment,
  
  /// Searching for content
  search,
}

/// Entity representing a user's location context
class LocationContext {
  /// Latitude coordinate
  final double latitude;
  
  /// Longitude coordinate
  final double longitude;
  
  /// Accuracy of the location in meters
  final double accuracy;
  
  /// Campus area or building (if known)
  final String? campusLocation;
  
  /// Is user currently on campus
  final bool isOnCampus;
  
  /// Timestamp when location was recorded
  final DateTime timestamp;
  
  /// Constructor
  const LocationContext({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.campusLocation,
    required this.isOnCampus,
    required this.timestamp,
  });
}

/// Entity representing time context for recommendations
class TimeContext {
  /// Current date and time
  final DateTime currentDateTime;
  
  /// Day of week (1-7, where 1 is Monday)
  final int dayOfWeek;
  
  /// Is a weekend day
  final bool isWeekend;
  
  /// Is during academic term
  final bool isDuringTerm;
  
  /// Current academic term (if applicable)
  final String? currentTerm;
  
  /// Is exam period
  final bool isExamPeriod;
  
  /// Constructor
  const TimeContext({
    required this.currentDateTime,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isDuringTerm,
    this.currentTerm,
    required this.isExamPeriod,
  });
}

/// Entity representing a user's social graph context
class SocialGraphContext {
  /// IDs of friends/connections
  final List<String> friendIds;
  
  /// IDs of mutual friends by user ID
  final Map<String, List<String>> mutualFriendsByUser;
  
  /// Social graph distance to other users
  final Map<String, int> socialDistanceToUsers;
  
  /// Friend groups or clusters
  final List<FriendGroupEntity> friendGroups;
  
  /// Constructor
  const SocialGraphContext({
    required this.friendIds,
    required this.mutualFriendsByUser,
    required this.socialDistanceToUsers,
    required this.friendGroups,
  });
}

/// Entity representing a group of friends
class FriendGroupEntity {
  /// Group identifier
  final String id;
  
  /// Group name or label
  final String name;
  
  /// IDs of users in this group
  final List<String> memberIds;
  
  /// Common interests of this group
  final List<String> commonInterests;
  
  /// Constructor
  const FriendGroupEntity({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.commonInterests,
  });
}

/// Entity representing a user's activity context
class ActivityContext {
  /// Recent events attended
  final List<String> recentEventIds;
  
  /// Spaces most actively engaged with
  final List<SpaceEngagement> mostActiveSpaces;
  
  /// Content created by user
  final List<String> createdContentIds;
  
  /// User activity level (interactions per day)
  final double dailyActivityLevel;
  
  /// Constructor
  const ActivityContext({
    required this.recentEventIds,
    required this.mostActiveSpaces,
    required this.createdContentIds,
    required this.dailyActivityLevel,
  });
}

/// Entity representing user engagement with a space
class SpaceEngagement {
  /// Space identifier
  final String spaceId;
  
  /// Space name
  final String spaceName;
  
  /// Engagement level (higher means more engaged)
  final double engagementLevel;
  
  /// Timestamp of last interaction
  final DateTime lastInteraction;
  
  /// Constructor
  const SpaceEngagement({
    required this.spaceId,
    required this.spaceName,
    required this.engagementLevel,
    required this.lastInteraction,
  });
}

/// Entity representing academic context
class AcademicContext {
  /// User's major or field of study
  final String? major;
  
  /// User's academic year
  final String? year;
  
  /// User's college or school within university
  final String? college;
  
  /// Current or recent courses
  final List<String> courses;
  
  /// Constructor
  const AcademicContext({
    this.major,
    this.year,
    this.college,
    required this.courses,
  });
} 