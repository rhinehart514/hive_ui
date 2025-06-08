import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'repost_content_type.dart';

@immutable
class Repost {
  final String id;
  final String userId;
  final String eventId;
  final String? text;
  final DateTime createdAt;
  final RepostContentType contentType;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy;
  final String? originalEventTitle;
  final String? originalEventImageUrl;
  
  const Repost({
    required this.id,
    required this.userId,
    required this.eventId,
    this.text,
    required this.createdAt,
    this.contentType = RepostContentType.standard,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedBy = const [],
    this.originalEventTitle,
    this.originalEventImageUrl,
  });

  factory Repost.create({
    required String userId,
    required String eventId,
    String? text,
    RepostContentType contentType = RepostContentType.standard,
    String? originalEventTitle,
    String? originalEventImageUrl,
  }) {
    final id = 'repost_${DateTime.now().millisecondsSinceEpoch}_$userId';
    
    return Repost(
      id: id,
      userId: userId,
      eventId: eventId,
      text: text,
      createdAt: DateTime.now(),
      contentType: contentType,
      originalEventTitle: originalEventTitle,
      originalEventImageUrl: originalEventImageUrl,
    );
  }

  factory Repost.fromJson(Map<String, dynamic> json) {
    return Repost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      text: json['text'] as String?,
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      contentType: _parseContentType(json['contentType'] as String?),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      likedBy: json['likedBy'] != null 
          ? List<String>.from(json['likedBy'] as List)
          : const [],
      originalEventTitle: json['originalEventTitle'] as String?,
      originalEventImageUrl: json['originalEventImageUrl'] as String?,
    );
  }

  static RepostContentType _parseContentType(String? value) {
    if (value == null) return RepostContentType.standard;
    return RepostContentType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RepostContentType.standard,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'contentType': contentType.name,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'originalEventTitle': originalEventTitle,
      'originalEventImageUrl': originalEventImageUrl,
    };
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'contentType': contentType.name,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'originalEventTitle': originalEventTitle,
      'originalEventImageUrl': originalEventImageUrl,
    };
  }

  // Create from Firestore document
  factory Repost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Repost(
      id: doc.id,
      userId: data['userId'] as String,
      eventId: data['eventId'] as String,
      text: data['text'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      contentType: _parseContentType(data['contentType'] as String?),
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      likedBy: data['likedBy'] != null 
          ? List<String>.from(data['likedBy'] as List)
          : const [],
      originalEventTitle: data['originalEventTitle'] as String?,
      originalEventImageUrl: data['originalEventImageUrl'] as String?,
    );
  }

  Repost copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? text,
    DateTime? createdAt,
    RepostContentType? contentType,
    int? likeCount,
    int? commentCount,
    List<String>? likedBy,
    String? originalEventTitle,
    String? originalEventImageUrl,
  }) {
    return Repost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      contentType: contentType ?? this.contentType,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedBy: likedBy ?? this.likedBy,
      originalEventTitle: originalEventTitle ?? this.originalEventTitle,
      originalEventImageUrl: originalEventImageUrl ?? this.originalEventImageUrl,
    );
  }
} 