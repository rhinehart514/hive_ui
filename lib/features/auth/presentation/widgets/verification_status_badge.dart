import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A badge that displays the user's verification status with appropriate styling.
/// Shows different states for pending, rejected, and verified statuses.
class VerificationStatusBadge extends StatelessWidget {
  /// The verification status to display
  final VerificationStatus status;
  
  /// The verification level to display
  final VerificationLevel level;
  
  /// Whether to show in a condensed format
  final bool condensed;
  
  /// Creates a verification status badge
  const VerificationStatusBadge({
    super.key,
    required this.status,
    required this.level,
    this.condensed = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: _getTextColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: GoogleFonts.inter(
              color: _getTextColor(),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get the appropriate background color based on status
  Color _getBackgroundColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey.withOpacity(0.2);
      case VerificationStatus.pending:
        return AppColors.gold.withOpacity(0.1);
      case VerificationStatus.rejected:
        return Colors.redAccent.withOpacity(0.1);
      case VerificationStatus.verified:
        switch (level) {
          case VerificationLevel.verified:
            return Colors.green.withOpacity(0.1);
          case VerificationLevel.verifiedPlus:
            return AppColors.gold.withOpacity(0.1);
          default:
            return Colors.grey.withOpacity(0.2);
        }
    }
  }
  
  /// Get the appropriate border color based on status
  Color _getBorderColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey.withOpacity(0.2);
      case VerificationStatus.pending:
        return AppColors.gold.withOpacity(0.4);
      case VerificationStatus.rejected:
        return Colors.redAccent.withOpacity(0.4);
      case VerificationStatus.verified:
        switch (level) {
          case VerificationLevel.verified:
            return Colors.green.withOpacity(0.4);
          case VerificationLevel.verifiedPlus:
            return AppColors.gold.withOpacity(0.6);
          default:
            return Colors.grey.withOpacity(0.2);
        }
    }
  }
  
  /// Get the appropriate text color based on status
  Color _getTextColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey;
      case VerificationStatus.pending:
        return AppColors.gold;
      case VerificationStatus.rejected:
        return Colors.redAccent;
      case VerificationStatus.verified:
        switch (level) {
          case VerificationLevel.verified:
            return Colors.green;
          case VerificationLevel.verifiedPlus:
            return AppColors.gold;
          default:
            return Colors.grey;
        }
    }
  }
  
  /// Get the appropriate icon based on status
  IconData _getStatusIcon() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Icons.person_outline;
      case VerificationStatus.pending:
        return Icons.hourglass_empty;
      case VerificationStatus.rejected:
        return Icons.cancel_outlined;
      case VerificationStatus.verified:
        switch (level) {
          case VerificationLevel.verified:
            return Icons.check_circle_outline;
          case VerificationLevel.verifiedPlus:
            return Icons.star_outline;
          default:
            return Icons.person_outline;
        }
    }
  }
  
  /// Get the appropriate status text
  String _getStatusText() {
    switch (status) {
      case VerificationStatus.notVerified:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Verification Pending';
      case VerificationStatus.rejected:
        return 'Verification Rejected';
      case VerificationStatus.verified:
        switch (level) {
          case VerificationLevel.verified:
            return 'Verified';
          case VerificationLevel.verifiedPlus:
            return 'Verified+';
          default:
            return 'Public Account';
        }
    }
  }
} 