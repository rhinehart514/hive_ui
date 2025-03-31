import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/space_entity.dart';
import 'space_repository_provider.dart';
import '../../../../providers/profile_provider.dart';

/// Provider for suggested spaces that can be displayed in the main feed
final suggestedSpacesProvider = FutureProvider.autoDispose<List<SpaceEntity>>((ref) async {
  final spaceRepository = ref.watch(spaceRepositoryProvider);
  final currentUser = ref.watch(profileProvider).profile;
  
  if (currentUser == null) {
    return [];
  }
  
  try {
    // Get spaces recommended for the user based on interests and location
    final suggestedSpaces = await spaceRepository.getSuggestedSpacesForUser(
      userId: currentUser.id,
      limit: 3, // Limit to 3 suggestions for the feed
    );
    
    return suggestedSpaces;
  } catch (e) {
    // Log error but don't crash the feed
    print('Error loading suggested spaces: $e');
    return [];
  }
});

/// Provider for refreshing suggested spaces
final refreshSuggestedSpacesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Invalidate the cache to force a refresh
    ref.invalidate(suggestedSpacesProvider);
    // Wait for the new data to load
    await ref.read(suggestedSpacesProvider.future);
  };
}); 