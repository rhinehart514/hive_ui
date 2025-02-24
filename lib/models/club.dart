import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class Club {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final String status; // active, inactive
  final IconData icon;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
    required this.status,
    required this.icon,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      memberCount: json['memberCount'] as int,
      status: json['status'] as String,
      icon: _getIconFromString(json['icon'] as String),
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'memberCount': memberCount,
      'status': status,
      'icon': _getStringFromIcon(icon),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'computer':
        return Icons.computer;
      case 'business':
        return Icons.business;
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'art':
        return Icons.palette;
      case 'science':
        return Icons.science;
      default:
        return Icons.group;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.computer) return 'computer';
    if (icon == Icons.business) return 'business';
    if (icon == Icons.sports) return 'sports';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.palette) return 'art';
    if (icon == Icons.science) return 'science';
    return 'group';
  }

  String get subtitle => '$memberCount members • $category';

  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? memberCount,
    String? status,
    IconData? icon,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 