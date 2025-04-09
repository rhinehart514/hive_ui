import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/leadership_claim_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to display the current claim status of a space
class LeadershipClaimStatusWidget extends ConsumerWidget {
  /// The space entity to display claim status for
  final SpaceEntity space;
  
  /// Show claim button
  final bool showClaimButton;
  
  /// Callback when claim button is pressed
  final VoidCallback? onClaimPressed;
  
  /// Constructor
  const LeadershipClaimStatusWidget({
    Key? key,
    required this.space,
    this.showClaimButton = false,
    this.onClaimPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If space doesn't require a claim or status is not set, don't show anything
    if (!space.requiresLeadershipClaim || 
        space.claimStatus == SpaceClaimStatus.notRequired) {
      return const SizedBox.shrink();
    }
    
    final claimAsyncValue = ref.watch(spaceClaimProvider(space.id));
    
    return claimAsyncValue.when(
      data: (claim) {
        final Color statusColor = _getStatusColor(space.claimStatus);
        final IconData statusIcon = _getStatusIcon(space.claimStatus);
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: statusColor.withOpacity(0.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                space.claimStatusDescription,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (showClaimButton && 
                  space.claimStatus == SpaceClaimStatus.unclaimed) ...[
                const SizedBox(width: 8),
                _buildClaimButton(context),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  /// Build the claim button
  Widget _buildClaimButton(BuildContext context) {
    return InkWell(
      onTap: onClaimPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.gold.withOpacity(0.6),
        ),
        child: const Text(
          'Claim',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
  
  /// Get color based on claim status
  Color _getStatusColor(SpaceClaimStatus status) {
    switch (status) {
      case SpaceClaimStatus.unclaimed:
        return Colors.orange;
      case SpaceClaimStatus.pending:
        return Colors.blue;
      case SpaceClaimStatus.claimed:
        return Colors.green;
      case SpaceClaimStatus.notRequired:
        return Colors.grey;
    }
  }
  
  /// Get icon based on claim status
  IconData _getStatusIcon(SpaceClaimStatus status) {
    switch (status) {
      case SpaceClaimStatus.unclaimed:
        return Icons.person_add_outlined;
      case SpaceClaimStatus.pending:
        return Icons.hourglass_empty;
      case SpaceClaimStatus.claimed:
        return Icons.verified_user_outlined;
      case SpaceClaimStatus.notRequired:
        return Icons.check_circle_outline;
    }
  }
} 