import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A card that displays a feature that requires specific permissions
/// with appropriate visual styling and role requirements.
/// Use this to show locked features with upgrade paths.
class FeaturePermissionCard extends ConsumerWidget {
  /// The title of the feature
  final String title;
  
  /// The description of the feature
  final String description;
  
  /// The icon representing the feature
  final IconData icon;
  
  /// The minimum role required to access this feature
  final UserRole requiredRole;
  
  /// The current user's role
  final UserRole currentRole;
  
  /// Callback for when the upgrade button is pressed
  final VoidCallback? onUpgrade;
  
  /// Callback for when the feature is accessed (if available)
  final VoidCallback? onAccess;
  
  /// Creates a feature permission card
  const FeaturePermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredRole,
    required this.currentRole,
    this.onUpgrade,
    this.onAccess,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = _checkPermission();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPermission 
              ? AppColors.gold.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasPermission
                        ? AppColors.gold.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: hasPermission
                        ? AppColors.gold
                        : Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Feature details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Permission status section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasPermission
                  ? AppColors.gold.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Permission status icon
                Icon(
                  hasPermission ? Icons.check_circle_outline : Icons.lock_outline,
                  color: hasPermission ? AppColors.gold : Colors.white.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                
                // Role requirement text
                Expanded(
                  child: Text(
                    hasPermission
                        ? 'Available with your ${_getRoleName(currentRole)} account'
                        : 'Requires ${_getRoleName(requiredRole)} account',
                    style: GoogleFonts.inter(
                      color: hasPermission 
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Action button
                if (hasPermission && onAccess != null)
                  TextButton(
                    onPressed: onAccess,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      backgroundColor: AppColors.gold.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Access',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (!hasPermission && onUpgrade != null)
                  TextButton(
                    onPressed: onUpgrade,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Upgrade',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Check if the current role has the required permission
  bool _checkPermission() {
    final roleValues = {
      UserRole.public: 0,
      UserRole.verified: 1,
      UserRole.verifiedPlus: 2,
      UserRole.moderator: 3,
      UserRole.admin: 4,
    };
    
    return roleValues[currentRole]! >= roleValues[requiredRole]!;
  }
  
  // Get a user-friendly role name
  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.verified:
        return 'Verified';
      case UserRole.verifiedPlus:
        return 'Verified+';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
      default:
        return 'Public';
    }
  }
} 