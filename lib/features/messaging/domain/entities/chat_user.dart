/// Represents a user in the chat system
class ChatUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime lastActive;
  final String? role; // e.g., 'admin', 'member', 'leader'
  final String? major;
  final String? year;
  final List<String>? clubIds;
  final bool isVerified;
  final String? email;
  final String? photoUrl;
  final String? bio;

  /// Creates a new ChatUser instance
  const ChatUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    required this.lastActive,
    this.role,
    this.major,
    this.year,
    this.clubIds,
    this.isVerified = false,
    this.email,
    this.photoUrl,
    this.bio,
  });

  /// A computed property that returns the user's display name
  String get displayName => name;

  /// Creates a copy of this ChatUser with the given fields replaced with new values
  ChatUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastActive,
    String? role,
    String? major,
    String? year,
    List<String>? clubIds,
    bool? isVerified,
    String? email,
    String? photoUrl,
    String? bio,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      role: role ?? this.role,
      major: major ?? this.major,
      year: year ?? this.year,
      clubIds: clubIds ?? this.clubIds,
      isVerified: isVerified ?? this.isVerified,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
    );
  }

  /// Activity status text for display
  String getActivityStatus() {
    if (isOnline) return 'Online';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours} hrs ago';
    } else {
      return 'Active ${difference.inDays} days ago';
    }
  }

  /// Checks if the user has admin privileges
  bool isAdmin() =>
      role?.toLowerCase() == 'admin' || role?.toLowerCase() == 'leader';

  /// Checks if the user is a regular member
  bool isMember() => role?.toLowerCase() == 'member';

  /// Returns display name with verification indicator if needed
  String getDisplayName() {
    return isVerified ? '$name ✓' : name;
  }

  /// Converts a ChatUser to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastActive': lastActive.toIso8601String(),
      'role': role,
      'major': major,
      'year': year,
      'clubIds': clubIds,
      'isVerified': isVerified,
      'email': email,
      'bio': bio,
    };
  }

  /// Creates a ChatUser from a Firestore document
  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'] as String)
          : DateTime.now(),
      role: map['role'] as String?,
      major: map['major'] as String?,
      year: map['year'] as String?,
      clubIds: map['clubIds'] != null
          ? List<String>.from(map['clubIds'] as List)
          : null,
      isVerified: map['isVerified'] as bool? ?? false,
      email: map['email'] as String?,
      bio: map['bio'] as String?,
    );
  }

  /// Creates a simplified ChatUser from a basic user profile
  factory ChatUser.fromBasicProfile(Map<String, dynamic> profile) {
    return ChatUser(
      id: profile['id'] as String,
      name: profile['displayName'] ?? profile['name'] ?? 'Unknown User',
      avatarUrl: profile['photoURL'] ?? profile['avatarUrl'],
      photoUrl: profile['photoURL'] ?? profile['avatarUrl'],
      isOnline: false,
      lastActive: DateTime.now(),
      isVerified: profile['isVerified'] ?? false,
      email: profile['email'] as String?,
      bio: profile['bio'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatUser &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.photoUrl == photoUrl &&
        other.isOnline == isOnline &&
        other.lastActive == lastActive &&
        other.role == role &&
        other.major == major &&
        other.year == year &&
        other.isVerified == isVerified &&
        other.email == email &&
        other.bio == bio;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        avatarUrl.hashCode ^
        photoUrl.hashCode ^
        isOnline.hashCode ^
        lastActive.hashCode ^
        role.hashCode ^
        major.hashCode ^
        year.hashCode ^
        isVerified.hashCode ^
        email.hashCode ^
        bio.hashCode;
  }
}
