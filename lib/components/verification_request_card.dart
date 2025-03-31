import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/verification_request.dart';
import 'package:hive_ui/providers/verification_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// A card that displays a verification request
class VerificationRequestCard extends ConsumerWidget {
  /// The verification request to display
  final VerificationRequest request;

  /// Callback for when the request status changes
  final Function()? onStatusChanged;

  /// Whether this card is for an admin view (shows approval buttons)
  final bool isAdminView;

  const VerificationRequestCard({
    super.key,
    required this.request,
    this.onStatusChanged,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status == VerificationRequestStatus.pending;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with object name and status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon for object type (space/organization)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      request.objectType == 'organization'
                          ? Icons.business
                          : Icons.group,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Object name and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.objectType.substring(0, 1).toUpperCase()}${request.objectType.substring(1)} Verification',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  _buildStatusBadge(),
                ],
              ),
            ),

            // Request message
            if (request.message != null && request.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  request.message!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 8),

            // Date info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Requested on ${dateFormat.format(request.createdAt)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),

            // Rejection reason (if rejected)
            if (request.status == VerificationRequestStatus.rejected &&
                request.rejectionReason != null &&
                request.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Reason: ${request.rejectionReason}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.red[300],
                  ),
                ),
              ),

            // Admin actions
            if (isAdminView && isPending) _buildAdminActions(context, ref),

            // User actions for pending requests
            if (!isAdminView && isPending) _buildUserActions(context, ref),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build the status badge based on request status
  Widget _buildStatusBadge() {
    // Determine color and text based on status
    Color badgeColor;
    String statusText;

    switch (request.status) {
      case VerificationRequestStatus.pending:
        badgeColor = Colors.amber;
        statusText = 'Pending';
        break;
      case VerificationRequestStatus.approved:
        badgeColor = Colors.green;
        statusText = 'Approved';
        break;
      case VerificationRequestStatus.rejected:
        badgeColor = Colors.red;
        statusText = 'Rejected';
        break;
      case VerificationRequestStatus.cancelled:
        badgeColor = Colors.grey;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  /// Build action buttons for admin users
  Widget _buildAdminActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Reject button
          OutlinedButton(
            onPressed: () => _showRejectDialog(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[300],
              side: BorderSide(color: Colors.red[300]!.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 12),

          // Approve button
          ElevatedButton(
            onPressed: () => _showApproveDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  /// Build action buttons for regular users
  Widget _buildUserActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel button
          OutlinedButton(
            onPressed: () => _cancelRequest(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  /// Show a dialog to confirm request rejection
  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Reject Verification Request',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject this verification request?',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                hintText: 'Why are you rejecting this request?',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Close the dialog
              Navigator.of(dialogContext).pop();

              // Reject the request
              final success = await ref
                  .read(verificationRequestNotifierProvider.notifier)
                  .rejectRequest(
                    request.id,
                    rejectionReason: reasonController.text.trim(),
                  );

              if (success && context.mounted) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request rejected'),
                    backgroundColor: Colors.red,
                  ),
                );

                // Call callback if provided
                if (onStatusChanged != null) {
                  onStatusChanged!();
                }
              }
            },
            child: Text(
              'Reject',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a dialog to confirm request approval
  void _showApproveDialog(BuildContext context, WidgetRef ref) {
    bool grantVerifiedPlus = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            'Approve Verification Request',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to approve this verification request?',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Verified+ option
              CheckboxListTile(
                title: Text(
                  'Grant Verified+ Status',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Enable premium features for this space',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                value: grantVerifiedPlus,
                onChanged: (value) {
                  setState(() {
                    grantVerifiedPlus = value ?? false;
                  });
                },
                activeColor: AppColors.gold,
                checkColor: Colors.black,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                // Close the dialog
                Navigator.of(dialogContext).pop();

                // Approve the request
                final success = await ref
                    .read(verificationRequestNotifierProvider.notifier)
                    .approveRequest(
                      request.id,
                      grantVerifiedPlus: grantVerifiedPlus,
                    );

                if (success && context.mounted) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        grantVerifiedPlus
                            ? 'Request approved with Verified+ status'
                            : 'Request approved',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Call callback if provided
                  if (onStatusChanged != null) {
                    onStatusChanged!();
                  }
                }
              },
              child: Text(
                'Approve',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cancel a verification request
  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: Text(
              'Cancel Request',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel this verification request?',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'No',
                  style:
                      GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Yes, Cancel',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // Cancel the request
      final success = await ref
          .read(verificationRequestNotifierProvider.notifier)
          .cancelRequest(request.id);

      if (success && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled'),
            backgroundColor: Colors.grey,
          ),
        );

        // Call callback if provided
        if (onStatusChanged != null) {
          onStatusChanged!();
        }
      }
    }
  }
}
