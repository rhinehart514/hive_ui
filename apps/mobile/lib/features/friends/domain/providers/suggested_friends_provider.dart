import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/suggested_friend.dart';
import '../../data/repositories/friends_repository_impl.dart';
import '../../../../providers/profile_provider.dart';
import '../repositories/friends_repository.dart';

/// Provider for friends repository
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepositoryImpl();
});

/// Provider for suggested friends that can be displayed in the main feed
final suggestedFriendsProvider = FutureProvider.autoDispose<List<SuggestedFriend>>((ref) async {
  final friendsRepository = ref.watch(friendsRepositoryProvider);
  final currentUser = ref.watch(profileProvider).profile;
  
  if (currentUser == null) {
    return [];
  }
  
  try {
    // Get friends recommended for the user based on interests, major, and location
    final suggestedFriends = await friendsRepository.getSuggestedFriends(
      userId: currentUser.id,
      limit: 3, // Limit to 3 suggestions for the feed
    );
    
    return suggestedFriends;
  } catch (e) {
    // Log error but don't crash the feed
    print('Error loading suggested friends: $e');
    return [];
  }
});

/// Provider for refreshing suggested friends
final refreshSuggestedFriendsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Invalidate the cache to force a refresh
    ref.invalidate(suggestedFriendsProvider);
    // Wait for the new data to load
    await ref.read(suggestedFriendsProvider.future);
  };
}); 