import 'package:flutter/foundation.dart';
import 'event.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents user verification status
enum VerificationStatus {
  /// Not verified
  none,
  
  /// Basic verified student
  verified,
  
  /// Verified student leader (higher privileges)
  verifiedPlus
}

/// Extension to parse verification status from string
extension VerificationStatusExtension on VerificationStatus {
  /// Convert to string
  String toShortString() {
    return toString().split('.').last;
  }
  
  /// Parse from string
  static VerificationStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return VerificationStatus.verified;
      case 'verifiedplus':
        return VerificationStatus.verifiedPlus;
      default:
        return VerificationStatus.none;
    }
  }
}

enum AccountTier {
  public,
  verified,
  verifiedPlus,
}

@immutable
class UserProfile {
  final String id;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final String year;
  final String major;
  final String residence;
  final int eventCount;
  final int spaceCount;
  final int friendCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AccountTier accountTier;
  final String? clubAffiliation;
  final String? clubRole;
  final List<String> interests;
  final List<Event> savedEvents;
  final List<String>? _followedSpaces;
  final String? email;
  final String displayName;
  final String firstName;
  final String lastName;
  final bool isPublic;
  final bool isVerified;
  final bool isVerifiedPlus;
  final File? tempProfileImageFile;
  
  /// User's activity level (0-100)
  final int activityLevel;
  
  /// Number of spaces shared with the current user
  final int sharedSpaces;
  
  /// Number of events shared with the current user
  final int sharedEvents;

  List<String> get followedSpaces => _followedSpaces ?? const [];

  int get clubCount => spaceCount;

  UserProfile({
    required this.id,
    required this.username,
    this.profileImageUrl,
    this.bio,
    required this.year,
    required this.major,
    required this.residence,
    required this.eventCount,
    required this.spaceCount,
    required this.friendCount,
    required this.createdAt,
    required this.updatedAt,
    this.accountTier = AccountTier.public,
    this.clubAffiliation,
    this.clubRole,
    required this.interests,
    this.savedEvents = const [],
    List<String>? followedSpaces,
    this.email,
    required this.displayName,
    String? firstName,
    String? lastName,
    this.isPublic = false,
    this.isVerified = false,
    this.isVerifiedPlus = false,
    this.tempProfileImageFile,
    this.activityLevel = 0,
    this.sharedSpaces = 0,
    this.sharedEvents = 0,
  })  : _followedSpaces = followedSpaces,
        firstName = firstName ?? (displayName.contains(' ') ? displayName.split(' ').first : displayName),
        lastName = lastName ?? (displayName.contains(' ') ? displayName.split(' ').last : '');

  /// The constructor parameters better illustrate the context and use of each field:
  ///
  /// [id] - Unique identifier for the profile
  /// [username] - Username for the user (often derived from name)
  /// [profileImageUrl] - URL to user's profile image
  /// [bio] - User's short bio/introduction text
  /// [year] - Academic year (e.g., "Freshman", "Sophomore")
  /// [major] - User's field of study
  /// [residence] - Where the user lives on/off campus
  /// [eventCount] - Number of events the user has posted/attended
  /// [spaceCount] - Number of spaces the user follows or is a member of
  /// [friendCount] - Number of connections in the user's network
  /// [createdAt] - When the profile was created
  /// [updatedAt] - When the profile was last updated
  /// [accountTier] - Level of account verification (public, verified, verified_plus)
  /// [clubAffiliation] - Legacy field for backward compatibility
  /// [clubRole] - Legacy field for backward compatibility
  /// [interests] - List of topics/activities the user is interested in
  /// [savedEvents] - Events the user has bookmarked
  /// [followedSpaces] - Spaces (clubs/organizations) the user follows
  /// [firstName] - User's first name
  /// [lastName] - User's last name
  /// [displayName] - Full name displayed on profile
  /// [email] - User's email address
  /// [isPublic] - Whether profile is publicly visible
  /// [isVerified] - Whether user has been verified
  /// [isVerifiedPlus] - Whether user has advanced verification status

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle case where json might not be a proper map
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }

      if (dateValue is DateTime) {
        return dateValue;
      }

      // Handle Firestore Timestamp
      if (dateValue.runtimeType.toString().contains('Timestamp')) {
        try {
          // First try to access as Firestore Timestamp
          final seconds = dateValue.seconds as int? ?? 0;
          final nanoseconds = dateValue.nanoseconds as int? ?? 0;
          return DateTime.fromMicrosecondsSinceEpoch(
            seconds * 1000000 + (nanoseconds ~/ 1000),
          );
        } catch (e) {
          debugPrint('Error parsing Timestamp: $e');
          return DateTime.now();
        }
      }

      // Handle ISO8601 string
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          debugPrint('Error parsing date string: $e');
          return DateTime.now();
        }
      }

      // Default fallback
      return DateTime.now();
    }

    // Parse integers which might be numeric or string values
    int parseIntField(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    // Parse string lists which might be arrays or comma-separated strings
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      
      try {
        if (value is List) {
          return List<String>.from(value.map((item) => item?.toString() ?? ''))
                           .where((s) => s.isNotEmpty)
                           .toList();
        }
        if (value is String) {
          return value.split(',')
                     .map((s) => s.trim())
                     .where((s) => s.isNotEmpty)
                     .toList();
        }
        if (value is Map) {
          return value.values
                     .map((v) => v?.toString() ?? '')
                     .where((s) => s.isNotEmpty)
                     .toList();
        }
        // Try to convert to string as last resort
        return [value.toString()]
                .where((s) => s.isNotEmpty)
                .toList();
      } catch (e) {
        debugPrint('Error parsing string list: $e');
        return [];
      }
    }

    // Fix for interests field
    List<String>? parseInterests(dynamic value) {
      if (value == null) return null;
      
      try {
        if (value is List) {
          return List<String>.from(value.map((item) => item.toString()));
        } else if (value is String) {
          final parts = value.split(',').where((s) => s.isNotEmpty).toList();
          return parts.isEmpty ? null : parts;
        }
      } catch (e) {
        print('Error parsing interests: $e');
      }
      
      return null;
    }

    try {
      // Parse saved events
      final savedEventsData = json['savedEvents'];
      List<Event> savedEvents = [];

      if (savedEventsData != null && savedEventsData is List) {
        savedEvents = savedEventsData
            .map((e) => e is Map<String, dynamic> ? Event.fromJson(e) : null)
            .whereType<Event>()
            .toList();
      }

      final firstName = json['firstName'] as String?;
      final lastName = json['lastName'] as String?;
      final displayName = json['displayName'] as String? ?? 'User';
      
      // Use parsed interests or default to empty list
      final interests = parseInterests(json['interests']) ?? [];

      // Handle both spaceCount and clubCount fields for backward compatibility
      int parsedSpaceCount = 0;
      if (json.containsKey('spaceCount')) {
        parsedSpaceCount = parseIntField(json['spaceCount']);
      } else if (json.containsKey('clubCount')) {
        // Use clubCount for backward compatibility if spaceCount is not present
        parsedSpaceCount = parseIntField(json['clubCount']);
      }

      return UserProfile(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? 'user',
        profileImageUrl: json['profileImageUrl'] as String?,
        bio: json['bio'] as String?,
        year: json['year'] as String? ?? '',
        major: json['major'] as String? ?? '',
        residence: json['residence'] as String? ?? '',
        eventCount: parseIntField(json['eventCount']),
        spaceCount: parsedSpaceCount,
        friendCount: parseIntField(json['friendCount']),
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
        accountTier: _parseAccountTier(json['accountTier']),
        clubAffiliation: json['clubAffiliation'] as String?,
        clubRole: json['clubRole'] as String?,
        interests: interests,
        savedEvents: savedEvents,
        followedSpaces: parseStringList(json['followedSpaces']),
        email: json['email'] as String?,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        isPublic: json['isPublic'] as bool? ?? false,
        isVerified: json['isVerified'] as bool? ?? false,
        isVerifiedPlus: json['isVerifiedPlus'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('Error parsing profile: $e');
      // Return a minimal valid profile to prevent crashes
      return UserProfile(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? 'User',
        displayName: json['displayName'] as String? ?? 'User',
        year: '',
        major: '',
        residence: '',
        eventCount: 0,
        spaceCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        interests: const [],
      );
    }
  }

  static AccountTier _parseAccountTier(String? value) {
    if (value == null) return AccountTier.public;
    return AccountTier.values.firstWhere(
      (tier) => tier.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AccountTier.public,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'year': year,
      'major': major,
      'residence': residence,
      'eventCount': eventCount,
      'spaceCount': spaceCount,
      'clubCount': spaceCount,
      'friendCount': friendCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'accountTier': accountTier.name,
      'clubAffiliation': clubAffiliation,
      'clubRole': clubRole,
      'interests': interests,
      'savedEvents': savedEvents.map((e) => e.toJson()).toList(),
      'followedSpaces': _followedSpaces ?? const [],
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'isPublic': isPublic,
      'isVerified': isVerified,
      'isVerifiedPlus': isVerifiedPlus,
      'tempProfileImageFile': tempProfileImageFile,
    };
  }

  /// Creates a Firestore-safe version of this profile's data
  Map<String, dynamic> toFirestore() {
    final data = toJson();
    
    // Remove any fields that shouldn't be saved directly to Firestore
    data.remove('tempProfileImageFile');
    
    // Convert DateTime string fields to Firebase Timestamps
    if (data.containsKey('createdAt') && data['createdAt'] is String) {
      try {
        final dateTime = DateTime.parse(data['createdAt']);
        data['createdAt'] = Timestamp.fromDate(dateTime);
      } catch (e) {
        debugPrint('Error converting createdAt to Timestamp: $e');
        data['createdAt'] = Timestamp.now();
      }
    }
    
    if (data.containsKey('updatedAt') && data['updatedAt'] is String) {
      try {
        final dateTime = DateTime.parse(data['updatedAt']);
        data['updatedAt'] = Timestamp.fromDate(dateTime);
      } catch (e) {
        debugPrint('Error converting updatedAt to Timestamp: $e');
        data['updatedAt'] = Timestamp.now();
      }
    }
    
    return data;
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? profileImageUrl,
    String? bio,
    String? year,
    String? major,
    String? residence,
    int? eventCount,
    int? spaceCount,
    int? friendCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    AccountTier? accountTier,
    String? clubAffiliation,
    String? clubRole,
    List<String>? interests,
    List<Event>? savedEvents,
    List<String>? followedSpaces,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    bool? isPublic,
    bool? isVerified,
    bool? isVerifiedPlus,
    File? tempProfileImageFile,
    int? activityLevel,
    int? sharedSpaces,
    int? sharedEvents,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      year: year ?? this.year,
      major: major ?? this.major,
      residence: residence ?? this.residence,
      eventCount: eventCount ?? this.eventCount,
      spaceCount: spaceCount ?? this.spaceCount,
      friendCount: friendCount ?? this.friendCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountTier: accountTier ?? this.accountTier,
      clubAffiliation: clubAffiliation ?? this.clubAffiliation,
      clubRole: clubRole ?? this.clubRole,
      interests: interests ?? this.interests,
      savedEvents: savedEvents ?? this.savedEvents,
      followedSpaces: followedSpaces ?? _followedSpaces,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      isVerifiedPlus: isVerifiedPlus ?? this.isVerifiedPlus,
      tempProfileImageFile: tempProfileImageFile ?? this.tempProfileImageFile,
      activityLevel: activityLevel ?? this.activityLevel,
      sharedSpaces: sharedSpaces ?? this.sharedSpaces,
      sharedEvents: sharedEvents ?? this.sharedEvents,
    );
  }

  // Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both spaceCount and clubCount fields for backward compatibility
    int parsedSpaceCount = 0;
    if (data.containsKey('spaceCount')) {
      parsedSpaceCount = data['spaceCount'] as int? ?? 0;
    } else if (data.containsKey('clubCount')) {
      // Use clubCount for backward compatibility if spaceCount is not present
      parsedSpaceCount = data['clubCount'] as int? ?? 0;
    }

    return UserProfile(
      id: doc.id,
      username: data['username'] as String? ?? 'Anonymous User',
      email: data['email'] as String?,
      displayName: data['displayName'] as String? ?? 'Anonymous User',
      profileImageUrl: data['profileImageUrl'] as String?,
      bio: data['bio'] as String?,
      year: data['year'] as String? ?? 'Freshman',
      major: data['major'] as String? ?? 'Undecided',
      residence: data['residence'] as String? ?? 'Off Campus',
      eventCount: data['eventCount'] as int? ?? 0,
      spaceCount: parsedSpaceCount,
      friendCount: data['friendCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accountTier: _parseAccountTier(data['accountTier'] as String?),
      clubAffiliation: data['clubAffiliation'] as String?,
      clubRole: data['clubRole'] as String?,
      interests: (data['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      savedEvents: const [],
      followedSpaces: (data['followedSpaces'] as List<dynamic>?)?.cast<String>(),
      isPublic: data['isPublic'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      isVerifiedPlus: data['isVerifiedPlus'] as bool? ?? false,
      activityLevel: data['activityLevel'] as int? ?? 0,
      sharedSpaces: data['sharedSpaces'] as int? ?? 0,
      sharedEvents: data['sharedEvents'] as int? ?? 0,
    );
  }
}
