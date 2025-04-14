/// Entity representing user insights and analytics
class UserInsights {
  final String userId;
  final int totalPosts;
  final int totalComments;
  final int totalLikes;
  final double averageEngagement;
  final DateTime lastActive;

  const UserInsights({
    required this.userId,
    required this.totalPosts,
    required this.totalComments,
    required this.totalLikes,
    required this.averageEngagement,
    required this.lastActive,
  });

  /// Convert the insights to a JSON map
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalPosts': totalPosts,
        'totalComments': totalComments,
        'totalLikes': totalLikes,
        'averageEngagement': averageEngagement,
        'lastActive': lastActive.toIso8601String(),
      };

  /// Create a copy with updated values
  UserInsights copyWith({
    String? userId,
    int? totalPosts,
    int? totalComments,
    int? totalLikes,
    double? averageEngagement,
    DateTime? lastActive,
  }) {
    return UserInsights(
      userId: userId ?? this.userId,
      totalPosts: totalPosts ?? this.totalPosts,
      totalComments: totalComments ?? this.totalComments,
      totalLikes: totalLikes ?? this.totalLikes,
      averageEngagement: averageEngagement ?? this.averageEngagement,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInsights &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          totalPosts == other.totalPosts &&
          totalComments == other.totalComments &&
          totalLikes == other.totalLikes &&
          averageEngagement == other.averageEngagement &&
          lastActive == other.lastActive;

  @override
  int get hashCode =>
      userId.hashCode ^
      totalPosts.hashCode ^
      totalComments.hashCode ^
      totalLikes.hashCode ^
      averageEngagement.hashCode ^
      lastActive.hashCode;
} 