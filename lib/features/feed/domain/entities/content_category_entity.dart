import 'package:flutter/material.dart';

/// Entity representing a Content Category in the domain layer
class ContentCategoryEntity {
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

  const ContentCategoryEntity({
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

  /// Creates a copy of this ContentCategoryEntity with given fields replaced
  ContentCategoryEntity copyWith({
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
    return ContentCategoryEntity(
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

  /// Returns a background color for this category (lighter version of the main color)
  Color get backgroundColor => color.withOpacity(0.15);

  /// Returns a text color with appropriate contrast for this category's color
  Color get textColor {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  /// Returns true if this is a system-defined category
  bool get isSystem => isSystemCategory;

  /// Returns true if this is a default category
  bool get isDefaultCategory => isDefault;

  /// Compares categories by priority for sorting
  int compareTo(ContentCategoryEntity other) {
    // Sort by priority first (higher priority comes first)
    if (priority != other.priority) {
      return other.priority - priority;
    }
    // If same priority, sort alphabetically
    return name.compareTo(other.name);
  }
} 