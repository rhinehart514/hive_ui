import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space_request.dart';

/// Provider for all space requests (both sent and received)
final spaceRequestsProvider = FutureProvider<List<SpaceRequest>>((ref) async {
  // TODO: Implement fetching from API
  // For now, return a dummy list
  return [];
});

/// Provider specifically for pending space requests and invitations
final pendingRequestsProvider = Provider<List<SpaceRequest>>((ref) {
  final requestsAsync = ref.watch(spaceRequestsProvider);

  // Extract only pending requests from the async value
  return requestsAsync.when(
    data: (requests) =>
        requests.where((r) => r.status == SpaceRequestStatus.pending).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
