import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/providers/profile_provider.dart';

/// Role types in the app
enum UserRole {
  /// Regular user
  user,
  
  /// Verified user with basic verification
  verified,
  
  /// Builder with additional permissions
  builder,
  
  /// Admin with complete permissions
  admin
}

/// Provider to check if the current user is a Builder
final isBuilderProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider).profile;
  
  // Temporary implementation:
  // Consider a user a builder if they are verified+ 
  // In a production environment, this would check actual builder status
  if (profile == null) return false;
  
  return profile.isVerifiedPlus;
});

/// Provider to get the current user's role
final userRoleProvider = Provider<UserRole>((ref) {
  final profile = ref.watch(profileProvider).profile;
  final currentUser = ref.watch(currentUserProvider);
  final isLoggedIn = currentUser != null;
  
  if (!isLoggedIn || profile == null) {
    return UserRole.user;
  }
  
  if (profile.isVerifiedPlus) {
    return UserRole.builder;
  }
  
  if (profile.isVerified) {
    return UserRole.verified;
  }
  
  return UserRole.user;
});

/// Check if the user has at least the specified role level
final hasRoleProvider = Provider.family<bool, UserRole>((ref, requiredRole) {
  final userRole = ref.watch(userRoleProvider);
  
  switch (requiredRole) {
    case UserRole.user:
      return true; // Everyone has at least user role
    case UserRole.verified:
      return userRole == UserRole.verified || 
             userRole == UserRole.builder || 
             userRole == UserRole.admin;
    case UserRole.builder:
      return userRole == UserRole.builder || 
             userRole == UserRole.admin;
    case UserRole.admin:
      return userRole == UserRole.admin;
  }
}); 