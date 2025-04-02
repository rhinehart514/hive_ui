/// The privacy setting for a space
enum SpacePrivacy {
  /// Visible to anyone, can be joined by anyone
  public,
  
  /// Visible to anyone, but requires approval to join
  restricted,
  
  /// Not visible in search, requires invitation to join
  private,
}

/// The type of space
enum SpaceType {
  /// A general community space
  community,
  
  /// A space for clubs and organizations
  club,
  
  /// A space for academic purposes
  academic,
  
  /// A space for events
  event,
  
  /// A space exclusive to HIVE
  hiveExclusive,
}

/// Represents a space in the HIVE app
class Space {
  /// Unique identifier for the space
  final String id;
  
  /// Name of the space
  final String name;
  
  /// Description of the space
  final String description;
  
  /// Privacy setting for the space
  final SpacePrivacy privacy;
  
  /// Type of space
  final SpaceType type;
  
  /// URL to the cover image for the space
  final String coverImageUrl;
  
  /// ID of the space owner
  final String ownerId;
  
  /// Number of members in the space
  final int memberCount;
  
  /// When the space was created
  final DateTime createdAt;
  
  /// Whether the current user is a member of this space
  final bool isMember;
  
  /// Whether the current user is following this space
  final bool isFollowing;
  
  /// Tags associated with this space
  final List<String> tags;
  
  /// Constructor
  Space({
    required this.id,
    required this.name,
    required this.description,
    required this.privacy,
    required this.type,
    required this.coverImageUrl,
    required this.ownerId,
    required this.memberCount,
    required this.createdAt,
    this.isMember = false,
    this.isFollowing = false,
    this.tags = const [],
  });
  
  /// Create a copy of this Space but with the given fields replaced with the new values
  Space copyWith({
    String? id,
    String? name,
    String? description,
    SpacePrivacy? privacy,
    SpaceType? type,
    String? coverImageUrl,
    String? ownerId,
    int? memberCount,
    DateTime? createdAt,
    bool? isMember,
    bool? isFollowing,
    List<String>? tags,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      privacy: privacy ?? this.privacy,
      type: type ?? this.type,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ownerId: ownerId ?? this.ownerId,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      isMember: isMember ?? this.isMember,
      isFollowing: isFollowing ?? this.isFollowing,
      tags: tags ?? this.tags,
    );
  }
} 