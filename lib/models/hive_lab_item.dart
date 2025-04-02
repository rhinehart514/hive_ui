import 'package:flutter/foundation.dart';

/// Model class for HIVE Lab items shown in the feed
@immutable
class HiveLabItem {
  /// The title of the lab item
  final String title;
  
  /// A description of the lab item
  final String description;
  
  /// Label for the action button
  final String actionLabel;
  
  /// Type of lab item (e.g., "feature", "experiment", "survey")
  final String type;
  
  /// Unique identifier
  final String id;
  
  /// Function to call when the action button is pressed
  final VoidCallback? onAction;
  
  /// URL for more information
  final String? infoUrl;
  
  /// URL for an image associated with the lab item
  final String? imageUrl;
  
  /// Time when the lab item was created
  final DateTime createdAt;
  
  /// Time when the lab item expires
  final DateTime? expiresAt;
  
  /// Constructor
  HiveLabItem({
    required this.id,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.type,
    this.onAction,
    this.infoUrl,
    this.imageUrl,
    DateTime? createdAt,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Create from JSON map
  factory HiveLabItem.fromJson(Map<String, dynamic> json) {
    return HiveLabItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionLabel: json['actionLabel'] as String,
      type: json['type'] as String,
      infoUrl: json['infoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String) 
          : null,
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actionLabel': actionLabel,
      'type': type,
      'infoUrl': infoUrl,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
  
  /// Check if the lab item is active based on expiration date
  bool get isActive {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }
  
  /// Create a copy with some fields replaced
  HiveLabItem copyWith({
    String? id,
    String? title,
    String? description,
    String? actionLabel,
    String? type,
    VoidCallback? onAction,
    String? infoUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool clearExpirationDate = false,
  }) {
    return HiveLabItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      actionLabel: actionLabel ?? this.actionLabel,
      type: type ?? this.type,
      onAction: onAction ?? this.onAction,
      infoUrl: infoUrl ?? this.infoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: clearExpirationDate ? null : (expiresAt ?? this.expiresAt),
    );
  }
} 