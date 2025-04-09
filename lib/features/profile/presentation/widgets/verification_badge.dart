import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/domain/entities/verification_status.dart';

class VerificationBadge extends StatelessWidget {
  final VerificationLevel level;
  final double size;
  final bool showLabel;
  final bool showTooltip;
  
  const VerificationBadge({
    super.key,
    required this.level,
    this.size = 20,
    this.showLabel = false,
    this.showTooltip = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (level == VerificationLevel.public) {
      return const SizedBox.shrink();
    }
    
    final Widget badge = _buildBadgeIcon();
    
    Widget result = badge;
    
    if (showLabel) {
      result = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(width: 4),
          Text(
            _getLevelName(),
            style: GoogleFonts.poppins(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w500,
              color: _getBadgeColor(),
            ),
          ),
        ],
      );
    }
    
    if (showTooltip) {
      result = Tooltip(
        message: _getTooltipMessage(),
        child: result,
      );
    }
    
    return result;
  }
  
  Widget _buildBadgeIcon() {
    switch (level) {
      case VerificationLevel.public:
        return const SizedBox.shrink();
      case VerificationLevel.verified:
        return Icon(
          Icons.check_circle_outline_rounded,
          color: _getBadgeColor(),
          size: size,
        );
      case VerificationLevel.verifiedPlus:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.verified_rounded,
              color: _getBadgeColor(),
              size: size,
            ),
            Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: size * 0.6,
            ),
          ],
        );
    }
  }
  
  Color _getBadgeColor() {
    switch (level) {
      case VerificationLevel.public:
        return Colors.grey;
      case VerificationLevel.verified:
        return Colors.blue;
      case VerificationLevel.verifiedPlus:
        return AppColors.gold;
    }
  }
  
  String _getLevelName() {
    switch (level) {
      case VerificationLevel.public:
        return '';
      case VerificationLevel.verified:
        return 'Verified';
      case VerificationLevel.verifiedPlus:
        return 'Verified+';
    }
  }
  
  String _getTooltipMessage() {
    switch (level) {
      case VerificationLevel.public:
        return 'Public user with limited access';
      case VerificationLevel.verified:
        return 'Verified user with full access';
      case VerificationLevel.verifiedPlus:
        return 'Student leader with enhanced verification';
    }
  }
}

/// Status badge that shows the current verification status
class VerificationStatusBadge extends StatelessWidget {
  final VerificationStatus status;
  final double size;
  
  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.size = 12,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.5, vertical: size * 0.25),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: _getStatusColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: size,
          ),
          SizedBox(width: size * 0.25),
          Text(
            _getStatusText(),
            style: GoogleFonts.poppins(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Colors.grey;
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.rejected:
        return Colors.red;
      case VerificationStatus.verified:
        return Colors.green;
    }
  }
  
  IconData _getStatusIcon() {
    switch (status) {
      case VerificationStatus.notVerified:
        return Icons.cancel_outlined;
      case VerificationStatus.pending:
        return Icons.hourglass_empty;
      case VerificationStatus.rejected:
        return Icons.error_outline;
      case VerificationStatus.verified:
        return Icons.check_circle_outline;
    }
  }
  
  String _getStatusText() {
    switch (status) {
      case VerificationStatus.notVerified:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.verified:
        return 'Verified';
    }
  }
}

/// Combined widget that shows both level and status badge
class VerificationDetailBadge extends ConsumerWidget {
  final UserVerification verification;
  
  const VerificationDetailBadge({
    super.key,
    required this.verification,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            VerificationBadge(
              level: verification.level,
              showLabel: true,
              size: 18,
            ),
            const Spacer(),
            VerificationStatusBadge(
              status: verification.status,
              size: 14,
            ),
          ],
        ),
        if (verification.isRejected && verification.rejectionReason != null) ...[
          const SizedBox(height: 8),
          Text(
            'Reason: ${verification.rejectionReason}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red.shade300,
            ),
          ),
        ],
        if (verification.isPending) ...[
          const SizedBox(height: 8),
          Text(
            'Submitted: ${_formatDate(verification.submittedAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.orange.shade300,
            ),
          ),
        ],
        if (verification.isVerified && verification.verifiedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Verified: ${_formatDate(verification.verifiedAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.green.shade300,
            ),
          ),
        ],
        if (verification.level == VerificationLevel.verifiedPlus && 
            verification.connectedSpaceId != null) ...[
          const SizedBox(height: 8),
          Text(
            'Student Leader',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
        ],
      ],
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 