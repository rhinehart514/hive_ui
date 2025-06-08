import 'package:flutter/foundation.dart';

/// Represents the filters that can be applied to user search
@immutable
class UserSearchFilters {
  /// Text query to search across name, username, bio
  final String? query;
  
  /// Filter by academic year
  final String? year;
  
  /// Filter by major/field of study
  final String? major;
  
  /// Filter by residence/location
  final String? residence;
  
  /// Filter by interests/tags
  final List<String> interests;
  
  /// Filter by clubs/organizations
  final List<String> clubs;
  
  /// Filter by minimum activity level (0-100)
  final int? minActivityLevel;
  
  /// Filter by shared spaces count
  final int? minSharedSpaces;
  
  /// Filter by shared events count
  final int? minSharedEvents;
  
  /// Filter by engagement level (low, medium, high)
  final String? engagementLevel;
  
  /// Whether to only show verified users
  final bool onlyVerified;
  
  /// Whether to exclude already followed users
  final bool excludeFollowed;

  /// Constructor
  const UserSearchFilters({
    this.query,
    this.year,
    this.major,
    this.residence,
    this.interests = const [],
    this.clubs = const [],
    this.minActivityLevel,
    this.minSharedSpaces,
    this.minSharedEvents,
    this.engagementLevel,
    this.onlyVerified = false,
    this.excludeFollowed = true,
  });

  /// Create a copy with some fields replaced
  UserSearchFilters copyWith({
    String? query,
    String? year,
    String? major,
    String? residence,
    List<String>? interests,
    List<String>? clubs,
    int? minActivityLevel,
    int? minSharedSpaces,
    int? minSharedEvents,
    String? engagementLevel,
    bool? onlyVerified,
    bool? excludeFollowed,
  }) {
    return UserSearchFilters(
      query: query ?? this.query,
      year: year ?? this.year,
      major: major ?? this.major,
      residence: residence ?? this.residence,
      interests: interests ?? this.interests,
      clubs: clubs ?? this.clubs,
      minActivityLevel: minActivityLevel ?? this.minActivityLevel,
      minSharedSpaces: minSharedSpaces ?? this.minSharedSpaces,
      minSharedEvents: minSharedEvents ?? this.minSharedEvents,
      engagementLevel: engagementLevel ?? this.engagementLevel,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      excludeFollowed: excludeFollowed ?? this.excludeFollowed,
    );
  }

  /// Convert to a map for Firestore queries
  Map<String, dynamic> toQueryParams() {
    return {
      if (query != null) 'query': query,
      if (year != null) 'year': year,
      if (major != null) 'major': major,
      if (residence != null) 'residence': residence,
      if (interests.isNotEmpty) 'interests': interests,
      if (clubs.isNotEmpty) 'clubs': clubs,
      if (minActivityLevel != null) 'minActivityLevel': minActivityLevel,
      if (minSharedSpaces != null) 'minSharedSpaces': minSharedSpaces,
      if (minSharedEvents != null) 'minSharedEvents': minSharedEvents,
      if (engagementLevel != null) 'engagementLevel': engagementLevel,
      if (onlyVerified) 'onlyVerified': true,
      if (excludeFollowed) 'excludeFollowed': true,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSearchFilters &&
        other.query == query &&
        other.year == year &&
        other.major == major &&
        other.residence == residence &&
        listEquals(other.interests, interests) &&
        listEquals(other.clubs, clubs) &&
        other.minActivityLevel == minActivityLevel &&
        other.minSharedSpaces == minSharedSpaces &&
        other.minSharedEvents == minSharedEvents &&
        other.engagementLevel == engagementLevel &&
        other.onlyVerified == onlyVerified &&
        other.excludeFollowed == excludeFollowed;
  }

  @override
  int get hashCode {
    return Object.hash(
      query,
      year,
      major,
      residence,
      Object.hashAll(interests),
      Object.hashAll(clubs),
      minActivityLevel,
      minSharedSpaces,
      minSharedEvents,
      engagementLevel,
      onlyVerified,
      excludeFollowed,
    );
  }
} 