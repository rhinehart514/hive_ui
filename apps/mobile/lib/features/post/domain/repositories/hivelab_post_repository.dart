import '../models/hivelab_post.dart';

/// Repository interface for HIVELab posts
abstract class HiveLabPostRepository {
  /// Create a new HIVELab post
  Future<String> createPost({
    required String content,
    required HiveLabPostCategory category,
    required String userId,
    required String userName,
    String? userImage,
  });
  
  /// Fetch a post by ID
  Future<HiveLabPost?> getPost(String postId);
  
  /// Fetch all posts
  Future<List<HiveLabPost>> getPosts({
    int limit = 20,
    HiveLabPost? lastPost,
    String? category,
  });
  
  /// Fetch posts by a specific user
  Future<List<HiveLabPost>> getUserPosts(String userId, {
    int limit = 20,
    HiveLabPost? lastPost,
  });
  
  /// Update an existing post
  Future<void> updatePost(HiveLabPost post);
  
  /// Delete a post
  Future<void> deletePost(String postId);
  
  /// Like or unlike a post
  Future<void> toggleLike(String postId, String userId);
  
  /// Add a comment to a post
  Future<void> addComment(String postId);
  
  /// Remove a comment from a post
  Future<void> removeComment(String postId);
} 