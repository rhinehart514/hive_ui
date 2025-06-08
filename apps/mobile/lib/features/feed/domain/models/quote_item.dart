import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Represents a quote/comment on an event in the feed
class QuoteItem {
  /// Unique identifier for the quote
  final String id;

  /// The event being quoted/commented on
  final Event event;

  /// The user who created the quote
  final UserProfile author;

  /// The quote text content
  final String content;

  /// When the quote was created
  final DateTime createdAt;

  /// When the quote was last modified
  final DateTime? lastModified;

  /// Constructor
  QuoteItem({
    required this.id,
    required this.event,
    required this.author,
    required this.content,
    required this.createdAt,
    this.lastModified,
  });

  /// Create a copy of this quote with some fields replaced
  QuoteItem copyWith({
    String? id,
    Event? event,
    UserProfile? author,
    String? content,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      event: event ?? this.event,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
} 