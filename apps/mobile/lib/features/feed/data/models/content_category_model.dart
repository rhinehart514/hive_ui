import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/feed/domain/entities/content_category_entity.dart';

/// Data model representing a Content Category used for organizing feed content
class ContentCategoryModel {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final int priority;
  final bool isDefault;
  final bool isSystemCategory;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.priority = 0,
    this.isDefault = false,
    this.isSystemCategory = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to domain entity
  ContentCategoryEntity toEntity() {
    return ContentCategoryEntity(
      id: id,
      name: name,
      description: description,
      color: color,
      icon: icon,
      priority: priority,
      isDefault: isDefault,
      isSystemCategory: isSystemCategory,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from Firestore document
  factory ContentCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse dates
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      }
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(data['updatedAt']);
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.parse(data['updatedAt']);
      }
    }

    // Parse color
    Color color = Colors.blue;
    if (data['color'] != null) {
      if (data['color'] is int) {
        color = Color(data['color']);
      } else if (data['color'] is String) {
        try {
          final hexString = data['color'].toString().replaceAll('#', '');
          color = Color(int.parse('0xFF$hexString'));
        } catch (e) {
          color = Colors.blue;
        }
      }
    }

    // Parse icon
    IconData icon = Icons.category;
    if (data['iconCodePoint'] != null && data['iconCodePoint'] is int) {
      icon = IconData(
        data['iconCodePoint'],
        fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      );
    }

    // Parse metadata safely
    Map<String, dynamic> parseMetadata() {
      if (data['metadata'] == null) return const {};
      if (data['metadata'] is Map) {
        try {
          return Map<String, dynamic>.from(data['metadata'] as Map);
        } catch (e) {
          return const {};
        }
      }
      return const {};
    }

    return ContentCategoryModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Category',
      description: data['description'] ?? '',
      color: color,
      icon: icon,
      priority: data['priority'] is int ? data['priority'] : 0,
      isDefault: data['isDefault'] == true,
      isSystemCategory: data['isSystemCategory'] == true,
      metadata: parseMetadata(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'priority': priority,
      'isDefault': isDefault,
      'isSystemCategory': isSystemCategory,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of this ContentCategoryModel with given fields replaced
  ContentCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    IconData? icon,
    int? priority,
    bool? isDefault,
    bool? isSystemCategory,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      priority: priority ?? this.priority,
      isDefault: isDefault ?? this.isDefault,
      isSystemCategory: isSystemCategory ?? this.isSystemCategory,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a default Events category
  static ContentCategoryModel eventsCategory() {
    return ContentCategoryModel(
      id: 'events',
      name: 'Events',
      description: 'Campus events and activities',
      color: Colors.orange,
      icon: Icons.event,
      priority: 10,
      isDefault: true,
      isSystemCategory: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a default Announcements category
  static ContentCategoryModel announcementsCategory() {
    return ContentCategoryModel(
      id: 'announcements',
      name: 'Announcements',
      description: 'Official announcements and updates',
      color: Colors.blue,
      icon: Icons.campaign,
      priority: 20,
      isDefault: true,
      isSystemCategory: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a default Social category
  static ContentCategoryModel socialCategory() {
    return ContentCategoryModel(
      id: 'social',
      name: 'Social',
      description: 'Social updates and community posts',
      color: Colors.purple,
      icon: Icons.people,
      priority: 30,
      isDefault: true,
      isSystemCategory: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a default Academic category
  static ContentCategoryModel academicCategory() {
    return ContentCategoryModel(
      id: 'academic',
      name: 'Academic',
      description: 'Academic resources and information',
      color: Colors.green,
      icon: Icons.school,
      priority: 40,
      isDefault: true,
      isSystemCategory: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 