import 'package:flutter/material.dart';

/// Tag categories used for organizing space tags
enum TagCategory {
  academic,
  social,
  interest,
  professional,
  location,
  general
}

/// Entity representing a Space Tag in the domain layer
class SpaceTagEntity {
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
  final bool isExclusive;
  final Map<String, dynamic> metadata;

  const SpaceTagEntity({
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

  /// Creates a copy of this SpaceTagEntity with the given fields replaced with new values
  SpaceTagEntity copyWith({
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
    return SpaceTagEntity(
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

  /// Returns whether this tag can be shown in search results
  bool get canBeSearched => isSearchable;

  /// Returns whether this tag can be used for filtering
  bool get canBeFiltered => isFilterable;

  /// Returns whether this tag is exclusive to admins
  bool get isAdminOnly => isExclusive;

  /// Returns whether this tag is officially recognized
  bool get isOfficialTag => isOfficial;

  /// Returns the category name as a string
  String get categoryName => category.toString().split('.').last;

  /// Returns a lighter version of the tag color for backgrounds
  Color get backgroundColor => color.withOpacity(0.15);

  /// Returns the tag color for text with appropriate contrast
  Color get textColor {
    // Calculate brightness to determine if we need dark or light text
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
} 