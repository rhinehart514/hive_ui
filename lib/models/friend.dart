import 'package:flutter/foundation.dart';

@immutable
class Friend {
  final String id;
  final String name;
  final String major;
  final String year;
  final String? imageUrl;
  final bool isOnline;
  final DateTime lastActive;
  final DateTime createdAt;

  const Friend({
    required this.id,
    required this.name,
    required this.major,
    required this.year,
    this.imageUrl,
    required this.isOnline,
    required this.lastActive,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      name: json['name'] as String,
      major: json['major'] as String,
      year: json['year'] as String,
      imageUrl: json['imageUrl'] as String?,
      isOnline: json['isOnline'] as bool,
      lastActive: DateTime.parse(json['lastActive'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'major': major,
      'year': year,
      'imageUrl': imageUrl,
      'isOnline': isOnline,
      'lastActive': lastActive.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get status => '$major • $year';

  Friend copyWith({
    String? id,
    String? name,
    String? major,
    String? year,
    String? imageUrl,
    bool? isOnline,
    DateTime? lastActive,
    DateTime? createdAt,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      major: major ?? this.major,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
