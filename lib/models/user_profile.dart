import 'package:flutter/foundation.dart';
import 'event.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int clubCount;
  final int friendCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AccountTier accountTier;
  final String? clubAffiliation;
  final String? clubRole;
  final List<String>? interests;
  final List<Event> savedEvents;
  final List<String>? _followedSpaces;
  final String? email;
  final String displayName;
  final bool isPublic;
  final bool isVerified;
  final bool isVerifiedPlus;
  final File? tempProfileImageFile;

  List<String> get followedSpaces => _followedSpaces ?? const [];

  const UserProfile({
    required this.id,
    required this.username,
    this.profileImageUrl,
    this.bio,
    required this.year,
    required this.major,
    required this.residence,
    required this.eventCount,
    required this.clubCount,
    required this.friendCount,
    required this.createdAt,
    required this.updatedAt,
    this.accountTier = AccountTier.public,
    this.clubAffiliation,
    this.clubRole,
    this.interests,
    this.savedEvents = const [],
    List<String>? followedSpaces,
    this.email,
    required this.displayName,
    this.isPublic = false,
    this.isVerified = false,
    this.isVerifiedPlus = false,
    this.tempProfileImageFile,
  }) : _followedSpaces = followedSpaces;

  /// The constructor parameters better illustrate the context and use of each field:
  ///
  /// [id] - Unique identifier for the profile
  /// [username] - Display name for the user
  /// [profileImageUrl] - URL to user's profile image
  /// [bio] - User's short bio/introduction text
  /// [year] - Academic year (e.g., "Freshman", "Sophomore")
  /// [major] - User's field of study
  /// [residence] - Where the user lives on/off campus
  /// [eventCount] - Number of events the user has posted/attended
  /// [clubCount] - Number of clubs the user belongs to
  /// [friendCount] - Number of connections in the user's network
  /// [createdAt] - When the profile was created
  /// [updatedAt] - When the profile was last updated
  /// [accountTier] - Level of account verification (public, verified, verified_plus)
  /// [clubAffiliation] - The primary club the user is affiliated with
  /// [clubRole] - This can represent either a role in a club or be repurposed as a website URL
  /// [interests] - List of topics/activities the user is interested in
  /// [savedEvents] - Events the user has bookmarked
  /// [followedSpaces] - Spaces (clubs/organizations) the user follows

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle case where json might not be a proper map
    if (json is! Map<String, dynamic>) {
      debugPrint('Error: Expected a Map<String, dynamic> but got ${json.runtimeType}');
      // Return a minimal valid profile to prevent crashes
      return UserProfile(
        id: '',
        username: 'User',
        displayName: 'User',
        year: '',
        major: '',
        residence: '',
        eventCount: 0,
        clubCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Parse dates which could be either Timestamp objects, DateTime objects, or ISO8601 strings
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

    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'User',
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      year: json['year'] as String? ?? 'Freshman',
      major: json['major'] as String? ?? 'Undecided',
      residence: json['residence'] as String? ?? 'Off Campus',
      eventCount: parseIntField(json['eventCount']),
      clubCount: parseIntField(json['clubCount']),
      friendCount: parseIntField(json['friendCount']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      accountTier: _parseAccountTier(json['accountTier']),
      clubAffiliation: json['clubAffiliation'] as String?,
      clubRole: json['clubRole'] as String?,
      interests: parseInterests(json['interests']),
      savedEvents: json['savedEvents'] != null
          ? (json['savedEvents'] as List)
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      followedSpaces: json['followedSpaces'] != null
          ? (json['followedSpaces'] is String 
              ? json['followedSpaces'].toString().split(',').where((s) => s.isNotEmpty).toList()
              : parseStringList(json['followedSpaces']))
          : const [],
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      isPublic: json['isPublic'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isVerifiedPlus: json['isVerifiedPlus'] as bool? ?? false,
      tempProfileImageFile: json['tempProfileImageFile'] as File?,
    );
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
      'clubCount': clubCount,
      'friendCount': friendCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'accountTier': accountTier.name,
      'clubAffiliation': clubAffiliation,
      'clubRole': clubRole,
      'interests': interests ?? [],
      'savedEvents': savedEvents.map((e) => e.toJson()).toList(),
      'followedSpaces': _followedSpaces ?? const [],
      'email': email,
      'displayName': displayName,
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
    
    // Ensure interests is always a list for Firestore
    if (data['interests'] == null) {
      data['interests'] = [];
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
    int? clubCount,
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
    bool? isPublic,
    bool? isVerified,
    bool? isVerifiedPlus,
    File? tempProfileImageFile,
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
      clubCount: clubCount ?? this.clubCount,
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
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      isVerifiedPlus: isVerifiedPlus ?? this.isVerifiedPlus,
      tempProfileImageFile: tempProfileImageFile ?? this.tempProfileImageFile,
    );
  }

  // Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
      clubCount: data['clubCount'] as int? ?? 0,
      friendCount: data['friendCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accountTier: _parseAccountTier(data['accountTier'] as String?),
      clubAffiliation: data['clubAffiliation'] as String?,
      clubRole: data['clubRole'] as String?,
      interests: (data['interests'] as List<dynamic>?)?.cast<String>(),
      savedEvents: const [],
      followedSpaces:
          (data['followedSpaces'] as List<dynamic>?)?.cast<String>(),
      isPublic: data['isPublic'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      isVerifiedPlus: data['isVerifiedPlus'] as bool? ?? false,
    );
  }
}
