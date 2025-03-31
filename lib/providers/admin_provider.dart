import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/services/admin_service.dart';

/// Provider for tracking whether the current user is an admin
final adminStatusProvider = FutureProvider<bool>((ref) async {
  return AdminService.isUserAdmin();
});

/// Provider for checking admin status synchronously (cached result)
final cachedAdminStatusProvider = StateProvider<bool>((ref) {
  // Initialize to false, will be updated once the future provider resolves
  return false;
});

/// Provider that combines the cached and async admin status
final adminStatusNotifierProvider = Provider((ref) {
  // Watch the future provider for changes
  final adminStatus = ref.watch(adminStatusProvider);

  // Update the cached provider when the future resolves
  adminStatus.whenData((isAdmin) {
    ref.read(cachedAdminStatusProvider.notifier).state = isAdmin;
  });

  return adminStatus;
});

/// Provider to ensure admin-related routes/components are not included in builds for non-admin users
/// Use this when conditionally building parts of the UI that should only exist for admins
final adminFeaturesEnabledProvider = Provider<bool>((ref) {
  final status = ref.watch(cachedAdminStatusProvider);
  // By using the cached status, we avoid async loading states in the UI
  return status;
});
