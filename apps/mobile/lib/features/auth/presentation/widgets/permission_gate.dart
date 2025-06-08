import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/providers/role_checker_provider.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that conditionally renders content based on user role permissions.
/// Use this widget to implement role-based UI adaptation throughout the app.
class PermissionGate extends ConsumerWidget {
  /// The child widget to display if user has permission
  final Widget child;
  
  /// The minimum role required to view this content
  final UserRole requiredRole;
  
  /// Widget to show when user doesn't have permission (optional)
  /// If null, the [placeholderBuilder] will be used
  final Widget? fallbackWidget;
  
  /// Whether to show a visual indicator when permission is denied
  final bool showPlaceholder;
  
  /// Custom builder for the placeholder (optional)
  final Widget Function(BuildContext, UserRole)? placeholderBuilder;
  
  /// Whether this gate allows interaction with placeholder
  final bool allowPlaceholderInteraction;
  
  /// Callback when placeholder is tapped (only used if allowPlaceholderInteraction is true)
  final VoidCallback? onPlaceholderTap;
  
  /// Creates a permission gate
  const PermissionGate({
    super.key,
    required this.child,
    required this.requiredRole,
    this.fallbackWidget,
    this.showPlaceholder = true,
    this.placeholderBuilder,
    this.allowPlaceholderInteraction = true,
    this.onPlaceholderTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current user's role
    final userRoleAsync = ref.watch(currentUserRoleProvider);
    
    return userRoleAsync.when(
      data: (userRole) {
        // Check if user has permission
        final hasPermission = _checkPermission(userRole);
        
        if (hasPermission) {
          return child;
        }
        
        // If user doesn't have permission, show fallback or placeholder
        if (fallbackWidget != null) {
          return fallbackWidget!;
        }
        
        if (!showPlaceholder) {
          return const SizedBox.shrink();
        }
        
        // Show custom or default placeholder
        final placeholder = placeholderBuilder != null
            ? placeholderBuilder!(context, requiredRole)
            : _buildDefaultPlaceholder(context, requiredRole);
        
        if (allowPlaceholderInteraction && onPlaceholderTap != null) {
          return GestureDetector(
            onTap: onPlaceholderTap,
            child: placeholder,
          );
        }
        
        return placeholder;
      },
      loading: () => const SizedBox(
        height: 40,
        width: 40,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gold,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  /// Check if the current role has the required permission
  bool _checkPermission(UserRole currentRole) {
    final roleValues = {
      UserRole.public: 0,
      UserRole.verified: 1,
      UserRole.verifiedPlus: 2,
      UserRole.moderator: 3,
      UserRole.admin: 4,
    };
    
    return roleValues[currentRole]! >= roleValues[requiredRole]!;
  }
  
  /// Build the default placeholder widget
  Widget _buildDefaultPlaceholder(BuildContext context, UserRole requiredRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.gold.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            _getRoleRequirementMessage(requiredRole),
            style: TextStyle(
              color: AppColors.gold.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get a user-friendly message based on the required role
  String _getRoleRequirementMessage(UserRole role) {
    switch (role) {
      case UserRole.verified:
        return 'Verified account required';
      case UserRole.verifiedPlus:
        return 'Verified+ status required';
      case UserRole.moderator:
        return 'Moderator access required';
      case UserRole.admin:
        return 'Admin access required';
      default:
        return 'Permission required';
    }
  }
} 