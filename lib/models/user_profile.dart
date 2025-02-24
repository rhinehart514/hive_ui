import 'package:flutter/foundation.dart';

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
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      year: json['year'] as String,
      major: json['major'] as String,
      residence: json['residence'] as String,
      eventCount: json['eventCount'] as int,
      clubCount: json['clubCount'] as int,
      friendCount: json['friendCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
    };
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
    );
  }
} 