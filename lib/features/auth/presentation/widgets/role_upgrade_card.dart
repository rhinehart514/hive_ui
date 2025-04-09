import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/features/auth/presentation/widgets/role_badge.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A card that displays role upgrade options and explains the verification process.
/// Used in profile pages and other locations where users can upgrade their roles.
class RoleUpgradeCard extends ConsumerWidget {
  /// The current role of the user
  final UserRole currentRole;
  
  /// The target role for upgrade
  final UserRole targetRole;
  
  /// Callback when the upgrade button is pressed
  final VoidCallback onUpgrade;
  
  /// Whether the card is in a loading state
  final bool isLoading;
  
  /// Creates a role upgrade card
  const RoleUpgradeCard({
    super.key,
    required this.currentRole,
    required this.targetRole,
    required this.onUpgrade,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with role badges
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role Upgrade Available',
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getUpgradeDescription(),
                  style: GoogleFonts.inter(
                    color: AppColors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    RoleBadge(role: currentRole),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.white.withOpacity(0.7),
                        size: 16,
                      ),
                    ),
                    RoleBadge(role: targetRole),
                  ],
                ),
              ],
            ),
          ),
          
          // Benefits list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefits Include:',
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._getBenefitsList().map((benefit) => _buildBenefitItem(benefit)),
              ],
            ),
          ),
          
          // Process steps
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Process:',
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVerificationStep(1, _getStepOneText()),
                _buildVerificationStep(2, _getStepTwoText()),
                _buildVerificationStep(3, 'Wait for verification (typically 1-2 days)'),
              ],
            ),
          ),
          
          // Action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () {
                  HapticFeedback.mediumImpact();
                  onUpgrade();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: AppColors.gold.withOpacity(0.3),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Start Verification Process',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build a benefit list item
  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.gold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build a verification step
  Widget _buildVerificationStep(int stepNumber, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.inter(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to get the description based on role upgrade
  String _getUpgradeDescription() {
    if (targetRole == UserRole.verified) {
      return 'Verify your student status to unlock more features';
    } else if (targetRole == UserRole.verifiedPlus) {
      return 'Upgrade to create spaces and manage events';
    }
    return 'Upgrade your account for additional access';
  }
  
  // Helper to get benefits list based on target role
  List<String> _getBenefitsList() {
    if (targetRole == UserRole.verified) {
      return [
        'RSVP to campus events',
        'Join exclusive spaces',
        'Engage with the campus community',
        'Personalized event recommendations',
      ];
    } else if (targetRole == UserRole.verifiedPlus) {
      return [
        'Create and manage spaces',
        'Create and host events',
        'Access to visibility tools (Boost, Honey Mode)',
        'Analytics for your spaces and events',
        'Priority support',
      ];
    }
    return ['Additional features and access'];
  }
  
  // Helper for first verification step text
  String _getStepOneText() {
    if (targetRole == UserRole.verified) {
      return 'Verify your university email address';
    } else if (targetRole == UserRole.verifiedPlus) {
      return 'Submit proof of organization leadership';
    }
    return 'Submit verification request';
  }
  
  // Helper for second verification step text
  String _getStepTwoText() {
    if (targetRole == UserRole.verified) {
      return 'Complete your student profile information';
    } else if (targetRole == UserRole.verifiedPlus) {
      return 'Link your organization or space';
    }
    return 'Complete required information';
  }
} 