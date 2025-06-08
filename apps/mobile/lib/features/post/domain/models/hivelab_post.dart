import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// HIVELab post categories
enum HiveLabPostCategory {
  /// Bug report
  bug,
  
  /// Feature request
  featureRequest,
  
  /// Chaos/other
  chaos,
}

/// Extension for category string conversion
extension HiveLabPostCategoryExtension on HiveLabPostCategory {
  /// Convert enum to display string
  String get displayName {
    switch (this) {
      case HiveLabPostCategory.bug:
        return 'Bug';
      case HiveLabPostCategory.featureRequest:
        return 'Feature Request';
      case HiveLabPostCategory.chaos:
        return 'Chaos';
    }
  }
  
  /// Get the color name for this category
  String get colorName {
    switch (this) {
      case HiveLabPostCategory.bug:
        return 'red';
      case HiveLabPostCategory.featureRequest:
        return 'green';
      case HiveLabPostCategory.chaos:
        return 'purple';
    }
  }
}

/// Model for HIVELab posts
@immutable
class HiveLabPost {
  /// Unique identifier
  final String id;
  
  /// Post content
  final String content;
  
  /// Post category
  final HiveLabPostCategory category;
  
  /// User ID of the poster
  final String userId;
  
  /// Display name of the poster
  final String userName;
  
  /// Optional profile image URL of the poster
  final String? userImage;
  
  /// Status of the post (active, resolved, etc.)
  final String status;
  
  /// When the post was created
  final DateTime createdAt;
  
  /// Users who liked the post
  final List<String> likes;
  
  /// Number of comments
  final int commentCount;
  
  /// Constructor
  const HiveLabPost({
    required this.id,
    required this.content,
    required this.category,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.status,
    required this.createdAt,
    required this.likes,
    this.commentCount = 0,
  });
  
  /// Create a copy with some fields replaced
  HiveLabPost copyWith({
    String? id,
    String? content,
    HiveLabPostCategory? category,
    String? userId,
    String? userName,
    String? userImage,
    String? status,
    DateTime? createdAt,
    List<String>? likes,
    int? commentCount,
  }) {
    return HiveLabPost(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
    );
  }
  
  /// Create from a Firestore document
  factory HiveLabPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse category
    HiveLabPostCategory parsedCategory;
    final categoryString = data['category'] as String? ?? 'Feature Request';
    
    switch (categoryString) {
      case 'Bug':
        parsedCategory = HiveLabPostCategory.bug;
        break;
      case 'Feature Request':
        parsedCategory = HiveLabPostCategory.featureRequest;
        break;
      case 'Chaos':
        parsedCategory = HiveLabPostCategory.chaos;
        break;
      default:
        parsedCategory = HiveLabPostCategory.featureRequest;
    }
    
    return HiveLabPost(
      id: doc.id,
      content: data['content'] as String? ?? '',
      category: parsedCategory,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userImage: data['userImage'] as String?,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] as List? ?? []),
      commentCount: data['commentCount'] as int? ?? 0,
    );
  }
  
  /// Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'category': category.displayName,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'commentCount': commentCount,
    };
  }
  
  /// Check if a user has liked this post
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }
  
  /// Get the number of likes
  int get likeCount => likes.length;
} 