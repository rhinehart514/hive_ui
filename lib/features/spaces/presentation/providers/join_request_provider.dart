import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

/// Provider for retrieving join request status for a space and user
final joinRequestProvider = FutureProvider.family<Map<String, dynamic>, ({String spaceId, String userId})>(
  (ref, params) async {
    final repository = ref.watch(spaceRepositoryProvider);
    
    // Check if the user has a pending join request
    // Since there's no direct method to get a single join request status,
    // we'll check if the user is in the list of pending requests
    final pendingRequests = await repository.getJoinRequests(params.spaceId);
    
    if (pendingRequests.contains(params.userId)) {
      return {'status': 'pending', 'createdAt': DateTime.now().toString()};
    }
    
    // Check if the user is already a member
    final isMember = await repository.hasJoinedSpace(params.spaceId, userId: params.userId);
    
    if (isMember) {
      return {'status': 'approved', 'createdAt': DateTime.now().toString()};
    }
    
    // Default to no request
    return {'status': 'none', 'createdAt': DateTime.now().toString()};
  },
); 