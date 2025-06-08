import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/widgets/profile/verification_badge.dart';
import 'package:hive_ui/features/profile/presentation/screens/verified_plus_request_page.dart';

/// Shows a dialog with verification status information and actions
Future<bool?> showVerificationDialog(
  BuildContext context, {
  required VerificationStatus currentStatus,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => VerificationDialog(
      currentStatus: currentStatus,
    ),
  );
}

/// Dialog that displays verification information and actions
class VerificationDialog extends ConsumerWidget {
  /// Current verification status
  final VerificationStatus currentStatus;

  /// Constructor
  const VerificationDialog({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.dark2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: currentStatus == VerificationStatus.verifiedPlus
                ? AppColors.gold.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildCurrentStatus(context),
            if (currentStatus != VerificationStatus.verifiedPlus)
              _buildUpgradePath(context),
            _buildBenefits(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// Header section showing title and description
  Widget _buildHeader(BuildContext context) {
    String title;
    
    // Determine title based on status
    switch (currentStatus) {
      case VerificationStatus.none:
        title = 'Verification Required';
        break;
      case VerificationStatus.verified:
        title = 'Verified Status';
        break;
      case VerificationStatus.verifiedPlus:
        title = 'Verified+ Status';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: currentStatus == VerificationStatus.verifiedPlus
                ? AppColors.gold.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your verification status determines what features you can access in HIVE.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Current status section showing the user's verification level
  Widget _buildCurrentStatus(BuildContext context) {
    String description;
    Color color;
    IconData icon;

    // Configure UI based on status
    switch (currentStatus) {
      case VerificationStatus.none:
        description = 'Your account is currently unverified. Verify your school email to access more features.';
        color = Colors.grey;
        icon = Icons.error_outline;
        break;
      case VerificationStatus.verified:
        description = 'You have verified your school email address. You can now access all standard features.';
        color = Colors.blue;
        icon = Icons.verified_user;
        break;
      case VerificationStatus.verifiedPlus:
        description = 'You have Verified+ status as a student leader. You can access all premium features.';
        color = AppColors.gold;
        icon = Icons.workspace_premium;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Status',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              VerificationBadge(
                status: currentStatus,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Upgrade path section showing how to improve verification status
  Widget _buildUpgradePath(BuildContext context) {
    String title;
    String description;
    String buttonText;
    VoidCallback onPressed;
    
    if (currentStatus == VerificationStatus.none) {
      title = 'Verify Your Email';
      description = 'Start the verification process by confirming your school email address.';
      buttonText = 'Verify Email';
      onPressed = () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
        // Here you would trigger the email verification process
      };
    } else {
      title = 'Upgrade to Verified+';
      description = 'Student leaders can apply for Verified+ status to gain additional privileges.';
      buttonText = 'Apply for Verified+';
      onPressed = () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
        // Navigate to verified+ request page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const VerifiedPlusRequestPage(),
          ),
        );
      };
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold.withOpacity(0.2),
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                ),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Benefits section showing verification perks
  Widget _buildBenefits(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits of Verification',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            icon: Icons.school,
            text: 'Access to campus-only content and features',
          ),
          _buildBenefitItem(
            icon: Icons.groups,
            text: 'Create spaces and host events for your community',
          ),
          _buildBenefitItem(
            icon: Icons.verified,
            text: 'Verified badge on your profile for credibility',
          ),
          if (currentStatus == VerificationStatus.verifiedPlus || currentStatus == VerificationStatus.verified)
            _buildBenefitItem(
              icon: Icons.public,
              text: 'Higher visibility in search results',
            ),
          if (currentStatus == VerificationStatus.verifiedPlus)
            _buildBenefitItem(
              icon: Icons.workspace_premium,
              text: 'Full moderation controls for your spaces',
              isGold: true,
            ),
          if (currentStatus == VerificationStatus.verifiedPlus)
            _buildBenefitItem(
              icon: Icons.analytics,
              text: 'Access to analytics for your spaces and events',
              isGold: true,
            ),
        ],
      ),
    );
  }

  /// Individual benefit item
  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    bool isGold = false,
  }) {
    final color = isGold ? AppColors.gold : Colors.white.withOpacity(0.7);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Footer with close and help buttons
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              // Navigate to help center or FAQ
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Learn More',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 