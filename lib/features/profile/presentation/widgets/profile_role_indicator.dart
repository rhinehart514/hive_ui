import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/auth.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A prominent role indicator for the profile page that shows the user's
/// current role, verification status, and provides upgrade options.
class ProfileRoleIndicator extends ConsumerWidget {
  /// Whether this is for the current user (allows upgrading)
  final bool isCurrentUser;
  
  /// The current verification level
  final VerificationLevel verificationLevel;
  
  /// The current verification status
  final VerificationStatus verificationStatus;
  
  /// Callback when upgrade button is tapped
  final VoidCallback? onUpgradeTap;
  
  /// Constructor
  const ProfileRoleIndicator({
    super.key,
    required this.isCurrentUser,
    required this.verificationLevel,
    required this.verificationStatus,
    this.onUpgradeTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map verification level to user role
    final userRole = _mapToUserRole(verificationLevel);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(userRole),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role badge row with status
          Row(
            children: [
              RoleBadge(
                role: userRole,
                size: RoleBadgeSize.large,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRoleTitle(userRole),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  VerificationStatusBadge(
                    status: verificationStatus,
                    level: verificationLevel,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Description of current role
          Text(
            _getRoleDescription(userRole),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          // For current user, show upgrade options if applicable
          if (isCurrentUser && _canShowUpgradeButton(verificationLevel, verificationStatus)) ...[
            const SizedBox(height: 16),
            _buildUpgradeButton(context),
          ],
        ],
      ),
    );
  }
  
  /// Build the upgrade button if appropriate
  Widget _buildUpgradeButton(BuildContext context) {
    // Get button text based on current state
    final buttonText = verificationLevel == VerificationLevel.public
        ? 'Verify Your Account'
        : 'Upgrade to Verified+';
        
    return GestureDetector(
      onTap: onUpgradeTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.5),
          ),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: GoogleFonts.outfit(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Map verification level to user role
  UserRole _mapToUserRole(VerificationLevel level) {
    switch (level) {
      case VerificationLevel.verified:
        return UserRole.verified;
      case VerificationLevel.verifiedPlus:
        return UserRole.verifiedPlus;
      default:
        return UserRole.public;
    }
  }
  
  /// Get border color based on role
  Color _getBorderColor(UserRole role) {
    switch (role) {
      case UserRole.verified:
        return Colors.white.withOpacity(0.2);
      case UserRole.verifiedPlus:
        return AppColors.gold.withOpacity(0.3);
      case UserRole.moderator:
        return Colors.blueAccent.withOpacity(0.3);
      case UserRole.admin:
        return Colors.purpleAccent.withOpacity(0.3);
      default:
        return Colors.white.withOpacity(0.1);
    }
  }
  
  /// Get role title
  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.verified:
        return 'Verified Account';
      case UserRole.verifiedPlus:
        return 'Verified+ Account';
      case UserRole.moderator:
        return 'Moderator Account';
      case UserRole.admin:
        return 'Administrator Account';
      default:
        return 'Public Account';
    }
  }
  
  /// Get role description
  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.verified:
        return 'You have a verified account with full access to RSVP to events and join spaces.';
      case UserRole.verifiedPlus:
        return 'You have enhanced privileges including creating and managing spaces and events.';
      case UserRole.moderator:
        return 'You have moderator privileges to help maintain community standards.';
      case UserRole.admin:
        return 'You have full administrative access to the platform.';
      default:
        return 'Public accounts have limited access. Verify your account to unlock full features.';
    }
  }
  
  /// Check if we can show upgrade button
  bool _canShowUpgradeButton(VerificationLevel level, VerificationStatus status) {
    // Can't upgrade if already verified+, or if verification is pending
    if (level == VerificationLevel.verifiedPlus) return false;
    if (status == VerificationStatus.pending) return false;
    
    // Public accounts can verify, verified accounts can upgrade to verified+
    return true;
  }
} 