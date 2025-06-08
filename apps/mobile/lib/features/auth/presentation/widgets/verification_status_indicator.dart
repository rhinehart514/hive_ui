import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays the current verification status
/// with appropriate visual styling and status messages.
class VerificationStatusIndicator extends StatelessWidget {
  /// The current verification status
  final VerificationStatus status;
  
  /// Optional verification level (only relevant for verified status)
  final VerificationLevel? level;
  
  /// Optional timestamp of when verification was requested
  final DateTime? requestedAt;
  
  /// Optional error message for rejected verification
  final String? rejectionReason;
  
  /// Creates a verification status indicator
  const VerificationStatusIndicator({
    super.key,
    required this.status,
    this.level,
    this.requestedAt,
    this.rejectionReason,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getIconColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusTitle(),
                style: GoogleFonts.outfit(
                  color: _getTextColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (status == VerificationStatus.pending)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _getIconColor(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Status description
          Text(
            _getStatusDescription(),
            style: GoogleFonts.inter(
              color: AppColors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          
          // Progress indicator for pending
          if (status == VerificationStatus.pending) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: null, // Indeterminate
              backgroundColor: Colors.white.withOpacity(0.1),
              color: AppColors.gold,
            ),
            const SizedBox(height: 8),
            _buildTimeInfo(),
          ],
          
          // Rejection reason if applicable
          if (status == VerificationStatus.rejected && rejectionReason != null) ...[
            const SizedBox(height: 16),
            Text(
              'Reason:',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                rejectionReason!,
                style: GoogleFonts.inter(
                  color: Colors.red.shade200,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Helper to build the time information section
  Widget _buildTimeInfo() {
    if (requestedAt == null) {
      return const SizedBox.shrink();
    }
    
    final now = DateTime.now();
    final difference = now.difference(requestedAt!);
    String timeText;
    
    if (difference.inDays > 0) {
      timeText = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      timeText = 'Just now';
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Request submitted: $timeText',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        Text(
          'Est. wait: 1-2 days',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  // Helper to get background color based on status
  Color _getBackgroundColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey.withOpacity(0.1);
      case VerificationStatus.pending:
        return AppColors.gold.withOpacity(0.1);
      case VerificationStatus.rejected:
        return Colors.red.withOpacity(0.1);
      case VerificationStatus.verified:
        return Colors.green.withOpacity(0.1);
    }
  }
  
  // Helper to get border color based on status
  Color _getBorderColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey.withOpacity(0.2);
      case VerificationStatus.pending:
        return AppColors.gold.withOpacity(0.3);
      case VerificationStatus.rejected:
        return Colors.red.withOpacity(0.3);
      case VerificationStatus.verified:
        return Colors.green.withOpacity(0.3);
    }
  }
  
  // Helper to get text color based on status
  Color _getTextColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.white;
      case VerificationStatus.pending:
        return AppColors.gold;
      case VerificationStatus.rejected:
        return Colors.red.shade300;
      case VerificationStatus.verified:
        return Colors.green.shade300;
    }
  }
  
  // Helper to get icon color based on status
  Color _getIconColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey;
      case VerificationStatus.pending:
        return AppColors.gold;
      case VerificationStatus.rejected:
        return Colors.red.shade300;
      case VerificationStatus.verified:
        return Colors.green.shade300;
    }
  }
  
  // Helper to get status icon based on status
  IconData _getStatusIcon() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Icons.person_outline;
      case VerificationStatus.pending:
        return Icons.hourglass_empty;
      case VerificationStatus.rejected:
        return Icons.error_outline;
      case VerificationStatus.verified:
        return Icons.check_circle_outline;
    }
  }
  
  // Helper to get status title based on status
  String _getStatusTitle() {
    switch (status) {
      case VerificationStatus.notVerified:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Verification in Progress';
      case VerificationStatus.rejected:
        return 'Verification Failed';
      case VerificationStatus.verified:
        if (level == VerificationLevel.verifiedPlus) {
          return 'Verified+ Account';
        }
        return 'Verified Account';
    }
  }
  
  // Helper to get status description based on status
  String _getStatusDescription() {
    switch (status) {
      case VerificationStatus.notVerified:
        return 'Your account has limited access. Verify your student status to unlock more features.';
      case VerificationStatus.pending:
        return 'Your verification request is being processed. This typically takes 1-2 business days.';
      case VerificationStatus.rejected:
        return 'Your verification request was not approved. Please see the reason below and try again.';
      case VerificationStatus.verified:
        if (level == VerificationLevel.verifiedPlus) {
          return 'Your account has enhanced verification status. You can create and manage spaces and events.';
        }
        return 'Your account is verified. You can now fully participate in campus events and spaces.';
    }
  }
} 