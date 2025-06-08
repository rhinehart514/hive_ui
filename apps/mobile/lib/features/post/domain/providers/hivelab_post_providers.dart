import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/hivelab_post.dart';
import '../repositories/hivelab_post_repository.dart';
import '../../data/repositories/hivelab_post_repository_impl.dart';

/// Provider for the HIVELab post repository
final hiveLabPostRepositoryProvider = Provider<HiveLabPostRepository>((ref) {
  return HiveLabPostRepositoryImpl();
});

/// State class for HIVELab posts
class HiveLabPostsState {
  /// Posts currently loaded
  final List<HiveLabPost> posts;
  
  /// Whether posts are currently loading
  final bool isLoading;
  
  /// Whether there are more posts to load
  final bool hasMore;
  
  /// Any error message
  final String? errorMessage;
  
  /// Last post used for pagination
  final HiveLabPost? lastPost;
  
  /// Selected category filter
  final String? categoryFilter;
  
  /// Constructor
  HiveLabPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.lastPost,
    this.categoryFilter,
  });
  
  /// Create a copy with updated values
  HiveLabPostsState copyWith({
    List<HiveLabPost>? posts,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    HiveLabPost? lastPost,
    String? categoryFilter,
  }) {
    return HiveLabPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      lastPost: lastPost ?? this.lastPost,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

/// Provider for HIVELab posts state
final hiveLabPostsProvider = StateNotifierProvider<HiveLabPostsNotifier, HiveLabPostsState>((ref) {
  final repository = ref.watch(hiveLabPostRepositoryProvider);
  return HiveLabPostsNotifier(repository);
});

/// Notifier class for HIVELab posts
class HiveLabPostsNotifier extends StateNotifier<HiveLabPostsState> {
  final HiveLabPostRepository _repository;
  
  /// Constructor
  HiveLabPostsNotifier(this._repository) : super(HiveLabPostsState()) {
    // Load initial posts when created
    loadPosts();
  }
  
  /// Load posts, either initially or for pagination
  Future<void> loadPosts({bool refresh = false}) async {
    if (state.isLoading) return;
    
    // Set loading state
    state = state.copyWith(isLoading: true);
    
    try {
      // If refreshing, clear the posts and reset pagination
      final HiveLabPost? lastPost = refresh ? null : state.lastPost;
      
      // Fetch posts from repository
      final posts = await _repository.getPosts(
        lastPost: lastPost,
        category: state.categoryFilter,
      );
      
      // Update state with new posts
      state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.isNotEmpty,
        errorMessage: null,
        lastPost: posts.isNotEmpty ? posts.last : state.lastPost,
      );
    } catch (e) {
      debugPrint('Error loading HIVELab posts: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load posts: $e',
      );
    }
  }
  
  /// Filter posts by category
  void filterByCategory(String? category) {
    // Only reload if the category changed
    if (category != state.categoryFilter) {
      state = state.copyWith(
        categoryFilter: category,
        posts: [],
        lastPost: null,
        hasMore: true,
      );
      loadPosts(refresh: true);
    }
  }
  
  /// Create a new post
  Future<bool> createPost({
    required String content,
    required HiveLabPostCategory category,
    required String userId,
    required String userName,
    String? userImage,
  }) async {
    try {
      await _repository.createPost(
        content: content,
        category: category,
        userId: userId,
        userName: userName,
        userImage: userImage,
      );
      
      // Refresh posts to include the new one
      loadPosts(refresh: true);
      return true;
    } catch (e) {
      debugPrint('Error creating HIVELab post: $e');
      state = state.copyWith(errorMessage: 'Failed to create post: $e');
      return false;
    }
  }
  
  /// Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // Optimistic update
      state = state.copyWith(
        posts: state.posts.map((post) {
          if (post.id == postId) {
            final List<String> updatedLikes = List.from(post.likes);
            if (updatedLikes.contains(userId)) {
              updatedLikes.remove(userId);
            } else {
              updatedLikes.add(userId);
            }
            return post.copyWith(likes: updatedLikes);
          }
          return post;
        }).toList(),
      );
      
      // Update in repository
      await _repository.toggleLike(postId, userId);
    } catch (e) {
      debugPrint('Error toggling like on post: $e');
      // Reload posts to revert optimistic update if failed
      loadPosts(refresh: true);
    }
  }
  
  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
      
      // Remove post from state
      state = state.copyWith(
        posts: state.posts.where((post) => post.id != postId).toList(),
      );
    } catch (e) {
      debugPrint('Error deleting post: $e');
      state = state.copyWith(errorMessage: 'Failed to delete post: $e');
    }
  }
} 