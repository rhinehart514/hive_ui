import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/core/services/role_checker.dart';

/// Provider for the RoleChecker service to handle role-based access control
final roleCheckerProvider = Provider<RoleChecker>((ref) {
  return RoleChecker();
});

/// Provider that exposes the current user's role
final currentUserRoleProvider = FutureProvider<UserRole>((ref) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  if (currentUserId == null) {
    return UserRole.public;
  }
  
  return roleChecker.getUserRole(currentUserId);
});

/// Provider for the current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  // This would typically come from your authentication provider
  return ref.watch(authStateProvider).maybeWhen(
    data: (state) => state is AuthStateAuthenticated ? state.user.uid : null,
    orElse: () => null,
  );
});

/// Provider to check if the current user has a specific role
final hasRoleProvider = FutureProvider.family<bool, UserRole>((ref, minimumRole) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  return roleChecker.hasRole(minimumRole);
});

/// Provider to check if a user can edit a specific event
final canEditEventProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  if (currentUserId == null) {
    return false;
  }
  
  return roleChecker.canEditEvent(currentUserId, eventId);
});

/// Provider to check if a user is a leader of a specific space
final isSpaceLeaderProvider = FutureProvider.family<bool, String>((ref, spaceId) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  if (currentUserId == null) {
    return false;
  }
  
  return roleChecker.isSpaceLeader(currentUserId, spaceId);
});

/// Provider to check if a user can create a space of a specific type
final canCreateSpaceProvider = FutureProvider.family<bool, String>((ref, spaceType) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  if (currentUserId == null) {
    return false;
  }
  
  return roleChecker.canCreateSpace(currentUserId, spaceType);
});

/// Provider to check if a user can use boost functionality
final canUseBoostProvider = FutureProvider<bool>((ref) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  if (currentUserId == null) {
    return false;
  }
  
  return roleChecker.canUseBoost(currentUserId);
});

/// Provider to check if a user can use honey mode for a specific space
final canUseHoneyModeProvider = FutureProvider.family<bool, String>((ref, spaceId) async {
  final roleChecker = ref.watch(roleCheckerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  if (currentUserId == null) {
    return false;
  }
  
  return roleChecker.canUseHoneyMode(currentUserId, spaceId);
}); 