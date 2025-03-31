import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/space_request.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';

/// A card widget that displays a space request or invitation
class SpaceRequestCard extends ConsumerWidget {
  final SpaceRequest request;

  const SpaceRequestCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status == SpaceRequestStatus.pending;
    final isInvitation = request.isInvitation;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Space image or icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: request.space?.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              request.space!.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            request.space?.icon ?? Icons.group,
                            color: AppColors.gold,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Space name and request type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.space?.name ?? 'Unknown Space',
                          style: AppTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isInvitation ? 'Invitation' : 'Request to Join',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
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

            // Optional message
            if (request.message != null && request.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  request.message!,
                  style: AppTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Buttons for pending requests
            if (isPending)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Reject button
                    OutlinedButton(
                      onPressed: () => _handleReject(ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 12),

                    // Accept button
                    ElevatedButton(
                      onPressed: () => _handleAccept(ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ),

            // Date for completed requests
            if (!isPending)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  '${_getStatusText()} · ${_formatDate(request.createdAt)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    switch (request.status) {
      case SpaceRequestStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Pending',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case SpaceRequestStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Approved',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case SpaceRequestStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Declined',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case SpaceRequestStatus.cancelled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Cancelled',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  String _getStatusText() {
    switch (request.status) {
      case SpaceRequestStatus.approved:
        return request.isInvitation ? 'Accepted' : 'Approved';
      case SpaceRequestStatus.rejected:
        return 'Declined';
      case SpaceRequestStatus.cancelled:
        return 'Cancelled';
      case SpaceRequestStatus.pending:
        return 'Pending';
    }
  }

  String _formatDate(DateTime date) {
    // Simple date formatting
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  void _handleAccept(WidgetRef ref) {
    // TODO: Implement accept request logic using providers
    debugPrint('Accept request: ${request.id}');
  }

  void _handleReject(WidgetRef ref) {
    // TODO: Implement reject request logic using providers
    debugPrint('Reject request: ${request.id}');
  }
}
