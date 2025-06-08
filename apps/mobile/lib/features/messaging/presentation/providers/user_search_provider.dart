import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/presentation/providers/user_tag_provider.dart';

/// Represents a user in the system
class User {
  /// Unique identifier for the user
  final String id;
  
  /// Username for the user (unique)
  final String username;
  
  /// Display name for the user
  final String displayName;
  
  /// URL to the user's profile picture
  final String profilePicture;
  
  /// User's biography or description
  final String bio;
  
  /// Constructor
  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.profilePicture,
    this.bio = '',
  });
  
  /// Convert to UserTag
  UserTag toUserTag() {
    return UserTag(
      userId: id,
      username: username,
    );
  }
}

/// Interface for accessing user data
abstract class UserRepository {
  /// Search for users based on a query string
  Future<List<User>> searchUsers(String query);
}

/// Implementation of the UserRepository
class UserRepositoryImpl implements UserRepository {
  @override
  Future<List<User>> searchUsers(String query) async {
    // Mock implementation - replace with actual API call
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock data
    if (query.isEmpty) return [];
    
    return [
      User(
        id: '1',
        username: 'john_doe',
        displayName: 'John Doe',
        profilePicture: 'https://i.pravatar.cc/150?img=1',
        bio: 'Flutter developer and coffee enthusiast',
      ),
      User(
        id: '2',
        username: 'jane_smith',
        displayName: 'Jane Smith',
        profilePicture: 'https://i.pravatar.cc/150?img=2',
        bio: 'UI/UX designer with a passion for mobile apps',
      ),
      User(
        id: '3',
        username: 'alex_johnson',
        displayName: 'Alex Johnson',
        profilePicture: 'https://i.pravatar.cc/150?img=3',
        bio: 'Computer Science student at UB',
      ),
    ].where((user) => 
      user.username.toLowerCase().contains(query.toLowerCase()) ||
      user.displayName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

/// The current search query for finding users
final userSearchProvider = StateProvider<String>((ref) => '');

/// Indicates whether a search is currently in progress
final isSearchingProvider = StateProvider<bool>((ref) => false);

/// Provider for the user repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

/// The search results from the user search
final userSearchResultsProvider = StateNotifierProvider<UserSearchNotifier, List<User>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserSearchNotifier(userRepository);
});

/// Notifier to manage user search state
class UserSearchNotifier extends StateNotifier<List<User>> {
  final UserRepository _userRepository;

  UserSearchNotifier(this._userRepository) : super([]);

  /// Search for users with the given query
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }

    try {
      final results = await _userRepository.searchUsers(query);
      state = results;
    } catch (e) {
      // Handle error
      state = [];
    }
  }
  
  /// Search for users with the given query (alias for searchUsers)
  Future<void> search(String query) async {
    return searchUsers(query);
  }

  /// Clear the search results
  void clearResults() {
    state = [];
  }
}

/// Provider for selected user tags that will be auto-saved
final selectedTagsProvider = Provider<List<UserTag>>((ref) {
  final tagsState = ref.watch(userTagsProvider);
  return tagsState.tags;
});

/// Check if a user is already tagged
final isUserTaggedProvider = Provider.family<bool, String>((ref, userId) {
  final tags = ref.watch(selectedTagsProvider);
  return tags.any((tag) => tag.userId == userId);
});

/// Provider to get all tagged users
final allTaggedUsersProvider = Provider<List<UserTag>>((ref) {
  return ref.watch(selectedTagsProvider);
});

/// Function to add a tag (auto-saves)
void addUserTag(WidgetRef ref, User user) {
  final userTag = user.toUserTag();
  ref.read(userTagsProvider.notifier).addTag(userTag);
}

/// Function to remove a tag (auto-saves)
void removeUserTag(WidgetRef ref, String userId) {
  ref.read(userTagsProvider.notifier).removeTagById(userId);
} 