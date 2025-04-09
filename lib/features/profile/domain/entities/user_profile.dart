import './verification_status.dart';

/// Represents a user profile in the application
class UserProfile {
  /// Unique identifier for the user
  final String id;
  
  /// User's display name
  final String displayName;
  
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
    this.email,
    this.bio,
    this.location,
    this.photoUrl,
    this.interests = const [],
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
    String? email,
    String? bio,
    String? location,
    String? photoUrl,
    List<String>? interests,
    @Deprecated('Use ProfileVisibilitySettings instead') bool? isPublic,
    VerificationLevel? verificationLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    AccountTier? accountTier,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      photoUrl: photoUrl,
      interests: interests ?? this.interests,
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
      'email': email,
      'bio': bio,
      'location': location,
      'photoUrl': photoUrl,
      'interests': interests,
      'verificationLevel': verificationLevel.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'accountTier': accountTier.name,
    };
  }
  
  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      photoUrl: json['photoUrl'] as String?,
      interests: json['interests'] != null 
          ? List<String>.from(json['interests'] as List) 
          : const [],
      verificationLevel: VerificationLevel.values.firstWhere(
        (e) => e.name == json['verificationLevel'],
        orElse: () => VerificationLevel.public,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      accountTier: AccountTier.values.firstWhere(
        (e) => e.name == json['accountTier'],
        orElse: () => AccountTier.standard,
      ),
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