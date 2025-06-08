import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A badge that displays the user's role with appropriate styling.
/// Can be used in profiles, headers, or anywhere user role needs to be displayed.
class RoleBadge extends StatelessWidget {
  /// The role to display in this badge
  final UserRole role;
  
  /// The size variant of the badge
  final RoleBadgeSize size;
  
  /// Whether to use a condensed style for space constraints
  final bool condensed;
  
  /// Creates a role badge
  const RoleBadge({
    super.key,
    required this.role,
    this.size = RoleBadgeSize.medium,
    this.condensed = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // Define size-specific properties
    final height = _getHeight();
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();
    final paddingH = _getPaddingHorizontal();
    
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: paddingH,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getBadgeColor(),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(),
            size: iconSize,
            color: _getTextColor(),
          ),
          if (!condensed || role == UserRole.verifiedPlus || role == UserRole.admin) ...[
            const SizedBox(width: 4),
            Text(
              _getRoleLabel(),
              style: GoogleFonts.inter(
                color: _getTextColor(),
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Get appropriate badge background color based on role
  Color _getBadgeColor() {
    switch (role) {
      case UserRole.verified:
        return AppColors.black;
      case UserRole.verifiedPlus:
        return AppColors.black;
      case UserRole.moderator:
        return AppColors.black;
      case UserRole.admin:
        return AppColors.black;
      default:
        return Colors.transparent;
    }
  }
  
  /// Get appropriate border color based on role
  Color _getBorderColor() {
    switch (role) {
      case UserRole.verified:
        return Colors.white.withOpacity(0.2);
      case UserRole.verifiedPlus:
        return AppColors.gold.withOpacity(0.5);
      case UserRole.moderator:
        return Colors.blueAccent.withOpacity(0.5);
      case UserRole.admin:
        return Colors.purpleAccent.withOpacity(0.5);
      default:
        return Colors.white.withOpacity(0.1);
    }
  }
  
  /// Get appropriate text color based on role
  Color _getTextColor() {
    switch (role) {
      case UserRole.verified:
        return Colors.white;
      case UserRole.verifiedPlus:
        return AppColors.gold;
      case UserRole.moderator:
        return Colors.blueAccent;
      case UserRole.admin:
        return Colors.purpleAccent;
      default:
        return Colors.white.withOpacity(0.7);
    }
  }
  
  /// Get appropriate icon based on role
  IconData _getRoleIcon() {
    switch (role) {
      case UserRole.verified:
        return Icons.check_circle_outline;
      case UserRole.verifiedPlus:
        return Icons.star_outline_rounded;
      case UserRole.moderator:
        return Icons.shield_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }
  
  /// Get label text based on role
  String _getRoleLabel() {
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
  
  /// Get height based on size variant
  double _getHeight() {
    switch (size) {
      case RoleBadgeSize.small:
        return 20;
      case RoleBadgeSize.medium:
        return 24;
      case RoleBadgeSize.large:
        return 32;
    }
  }
  
  /// Get font size based on size variant
  double _getFontSize() {
    switch (size) {
      case RoleBadgeSize.small:
        return 10;
      case RoleBadgeSize.medium:
        return 12;
      case RoleBadgeSize.large:
        return 14;
    }
  }
  
  /// Get icon size based on size variant
  double _getIconSize() {
    switch (size) {
      case RoleBadgeSize.small:
        return 10;
      case RoleBadgeSize.medium:
        return 14;
      case RoleBadgeSize.large:
        return 18;
    }
  }
  
  /// Get horizontal padding based on size variant
  double _getPaddingHorizontal() {
    switch (size) {
      case RoleBadgeSize.small:
        return 6;
      case RoleBadgeSize.medium:
        return 8;
      case RoleBadgeSize.large:
        return 12;
    }
  }
}

/// Size variants for the role badge
enum RoleBadgeSize {
  /// Small badge for compact UIs (20px height)
  small,
  
  /// Medium badge for standard UIs (24px height)
  medium,
  
  /// Large badge for prominent displays (32px height)
  large,
} 