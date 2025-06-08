/// Represents a user in the HIVE app.
class User {
  /// Unique identifier for the user
  final String id;
  
  /// Username for the user (unique)
  final String username;
  
  /// Display name for the user
  final String displayName;
  
  /// URL to the user's profile picture
  final String profilePicture;
  
  /// User's biography or description
  final String bio;
  
  /// Whether the user is verified
  final bool isVerified;

  /// Whether the user is restricted from certain actions
  final bool isRestricted;

  /// The reason for the restriction (if any)
  final String? restrictionReason;

  /// The date when the restriction ends (if temporary)
  final DateTime? restrictionEndDate;

  /// The ID of the admin or system that applied the restriction
  final String? restrictedBy;
  
  /// Constructor
  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.profilePicture,
    this.bio = '',
    this.isVerified = false,
    this.isRestricted = false,
    this.restrictionReason,
    this.restrictionEndDate,
    this.restrictedBy,
  });
  
  /// Create a copy of this User but with the given fields replaced with the new values
  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? profilePicture,
    String? bio,
    bool? isVerified,
    bool? isRestricted,
    String? restrictionReason,
    DateTime? restrictionEndDate,
    String? restrictedBy,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isRestricted: isRestricted ?? this.isRestricted,
      restrictionReason: restrictionReason ?? this.restrictionReason,
      restrictionEndDate: restrictionEndDate ?? this.restrictionEndDate,
      restrictedBy: restrictedBy ?? this.restrictedBy,
    );
  }
} 