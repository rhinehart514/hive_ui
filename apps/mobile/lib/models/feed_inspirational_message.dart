import 'package:flutter/material.dart';

/// Data class for inspirational messages displayed in the feed
class InspirationalMessage {
  /// The icon to display with the message
  final IconData icon;

  /// The title of the message
  final String title;

  /// The message content
  final String message;

  /// Constructor
  const InspirationalMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  /// Create a copy with some fields replaced
  InspirationalMessage copyWith({
    IconData? icon,
    String? title,
    String? message,
  }) {
    return InspirationalMessage(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      message: message ?? this.message,
    );
  }
}
