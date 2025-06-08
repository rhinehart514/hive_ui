import './verification_status.dart';

/// Represents a user profile in the application
class UserProfile {
  /// Unique identifier for the user
  final String id;
  
  /// User's display name
  final String displayName;
  
  /// User's unique username
  final String? username;
  
  /// User's email address
  final String? email;
  
  /// Optional bio or description
  final String? bio;
  
  /// User's location
  final String? location;
  
  /// URL to user's profile photo
  final String? photoUrl;
  
  /// List of user's interests
  final List<String> interests;
  
  /// Added: User's academic year
  final String? year;
  
  /// Added: User's major/field of study
  final String? major;
  
  /// Added: User's residence type
  final String? residenceType;
  
  /// Whether the profile is public or private
  @Deprecated('Use ProfileVisibilitySettings instead')
  final bool isPublic;
  
  /// Current verification level of the user
  final VerificationLevel verificationLevel;
  
  /// When the profile was created
  final DateTime? createdAt;
  
  /// When the profile was last updated
  final DateTime? updatedAt;
  
  /// Account tier of the user
  final AccountTier accountTier;
  
  /// Constructor
  const UserProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.email,
    this.bio,
    this.location,
    this.photoUrl,
    this.interests = const [],
    this.year,
    this.major,
    this.residenceType,
    this.isPublic = true,
    this.verificationLevel = VerificationLevel.public,
    this.createdAt,
    this.updatedAt,
    this.accountTier = AccountTier.standard,
  });
  
  /// Create an empty user profile
  factory UserProfile.empty() => const UserProfile(
    id: '',
    displayName: '',
    verificationLevel: VerificationLevel.public,
  );
  
  /// Check if profile is empty
  bool get isEmpty => id.isEmpty;
  
  /// Check if profile is not empty
  bool get isNotEmpty => !isEmpty;
  
  /// Helper getters for verification level
  bool get isVerified => verificationLevel == VerificationLevel.verified;
  bool get isVerifiedPlus => verificationLevel == VerificationLevel.verifiedPlus;
  
  /// Create a copy of this profile with updated properties
  UserProfile copyWith({
    String? id,
    String? displayName,
    String? username,
    String? email,
    String? bio,
    String? location,
    String? photoUrl,
    List<String>? interests,
    String? year,
    String? major,
    String? residenceType,
    @Deprecated('Use ProfileVisibilitySettings instead') bool? isPublic,
    VerificationLevel? verificationLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    AccountTier? accountTier,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      interests: interests ?? this.interests,
      year: year ?? this.year,
      major: major ?? this.major,
      residenceType: residenceType ?? this.residenceType,
      isPublic: isPublic ?? this.isPublic,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountTier: accountTier ?? this.accountTier,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'email': email,
      'bio': bio,
      'location': location,
      'photoUrl': photoUrl,
      'interests': interests,
      'year': year,
      'major': major,
      'residenceType': residenceType,
      'verificationLevel': verificationLevel.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'accountTier': accountTier.name,
    };
  }
  
  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      photoUrl: json['photoUrl'] as String?,
      interests: json['interests'] != null 
          ? List<String>.from(json['interests'] as List) 
          : const [],
      year: json['year'] as String?,
      major: json['major'] as String?,
      residenceType: json['residenceType'] as String?,
      verificationLevel: VerificationLevel.values.firstWhere(
        (e) => e.name == json['verificationLevel'],
        orElse: () => VerificationLevel.public,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] as String? ?? '') 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'] as String? ?? '') 
          : null,
      accountTier: AccountTier.values.firstWhere(
        (e) => e.name == json['accountTier'],
        orElse: () => AccountTier.standard,
      ),
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }
}

/// Enum representing account tier levels
enum AccountTier {
  standard,
  verified,
  verifiedPlus,
  admin
} 