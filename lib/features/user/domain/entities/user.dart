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
  
  /// Constructor
  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.profilePicture,
    this.bio = '',
    this.isVerified = false,
  });
  
  /// Create a copy of this User but with the given fields replaced with the new values
  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? profilePicture,
    String? bio,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
    );
  }
} 