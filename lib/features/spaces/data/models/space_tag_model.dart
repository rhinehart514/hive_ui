import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_tag_entity.dart';

/// Data model representing a Space Tag, used for categorization and filtering
class SpaceTagModel {
  final String id;
  final String name;
  final String description;
  final Color color;
  final TagCategory category;
  final bool isOfficial;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFilterable;
  final bool isSearchable;
  final bool isExclusive; // Tags that can only be applied by admins
  final Map<String, dynamic> metadata;

  const SpaceTagModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.category,
    this.isOfficial = false,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isFilterable = true,
    this.isSearchable = true,
    this.isExclusive = false,
    this.metadata = const {},
  });

  /// Convert to domain entity
  SpaceTagEntity toEntity() {
    return SpaceTagEntity(
      id: id,
      name: name,
      description: description,
      color: color,
      category: category,
      isOfficial: isOfficial,
      usageCount: usageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFilterable: isFilterable,
      isSearchable: isSearchable,
      isExclusive: isExclusive,
      metadata: metadata,
    );
  }

  /// Create a SpaceTagModel from Firestore document
  factory SpaceTagModel.fromFirestore(DocumentSnapshot doc) {
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
          // Parse hex color string
          final hexString = data['color'].toString().replaceAll('#', '');
          color = Color(int.parse('0xFF$hexString'));
        } catch (e) {
          // Use default color if parsing fails
          color = Colors.blue;
        }
      }
    }

    // Parse category
    TagCategory category = TagCategory.general;
    if (data['category'] != null) {
      final categoryStr = data['category'].toString().toLowerCase();
      if (categoryStr.contains('academic')) {
        category = TagCategory.academic;
      } else if (categoryStr.contains('social')) {
        category = TagCategory.social;
      } else if (categoryStr.contains('interest')) {
        category = TagCategory.interest;
      } else if (categoryStr.contains('professional')) {
        category = TagCategory.professional;
      } else if (categoryStr.contains('location')) {
        category = TagCategory.location;
      }
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

    return SpaceTagModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Tag',
      description: data['description'] ?? '',
      color: color,
      category: category,
      isOfficial: data['isOfficial'] == true,
      usageCount: data['usageCount'] is int ? data['usageCount'] : 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFilterable: data['isFilterable'] == true,
      isSearchable: data['isSearchable'] == true,
      isExclusive: data['isExclusive'] == true,
      metadata: parseMetadata(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color.value,
      'category': category.toString().split('.').last,
      'isOfficial': isOfficial,
      'usageCount': usageCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isFilterable': isFilterable,
      'isSearchable': isSearchable,
      'isExclusive': isExclusive,
      'metadata': metadata,
    };
  }

  /// Create a copy of this SpaceTagModel with the given fields replaced with new values
  SpaceTagModel copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    TagCategory? category,
    bool? isOfficial,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFilterable,
    bool? isSearchable,
    bool? isExclusive,
    Map<String, dynamic>? metadata,
  }) {
    return SpaceTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      category: category ?? this.category,
      isOfficial: isOfficial ?? this.isOfficial,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFilterable: isFilterable ?? this.isFilterable,
      isSearchable: isSearchable ?? this.isSearchable,
      isExclusive: isExclusive ?? this.isExclusive,
      metadata: metadata ?? this.metadata,
    );
  }
} 