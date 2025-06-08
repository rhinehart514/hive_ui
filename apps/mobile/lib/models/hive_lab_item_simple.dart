import 'package:flutter/foundation.dart';

/// Simplified model class for HIVE Lab items shown in the feed
@immutable
class HiveLabItemSimple {
  /// The title of the lab item
  final String title;
  
  /// A description of the lab item
  final String description;
  
  /// Link to the lab item
  final String link;
  
  /// Time when the lab item was created/published
  final DateTime timestamp;
  
  /// Constructor
  const HiveLabItemSimple({
    required this.title,
    required this.description,
    required this.link,
    required this.timestamp,
  });
  
  /// Create from JSON map
  factory HiveLabItemSimple.fromJson(Map<String, dynamic> json) {
    return HiveLabItemSimple(
      title: json['title'] as String,
      description: json['description'] as String,
      link: json['link'] as String,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : DateTime.now(),
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Create a copy with some fields replaced
  HiveLabItemSimple copyWith({
    String? title,
    String? description,
    String? link,
    DateTime? timestamp,
  }) {
    return HiveLabItemSimple(
      title: title ?? this.title,
      description: description ?? this.description,
      link: link ?? this.link,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 