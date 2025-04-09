import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_empty_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_error_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_loading_state.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget that displays spaces a user has been invited to
class RequestsContent extends ConsumerWidget {
  /// Constructor
  const RequestsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitedSpacesAsync = ref.watch(invitedSpacesProvider);

    return invitedSpacesAsync.when(
      loading: () => const SpacesLoadingState(),
      error: (err, stack) => SpacesErrorState(error: err.toString()),
      data: (spaces) {
        if (spaces.isEmpty) {
          return const SpacesEmptyState(
            message: 'No pending invitations',
            subMessage: 'You don\'t have any space invitations at the moment',
            icon: Icons.mail_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: spaces.length,
          itemBuilder: (context, index) {
            final space = spaces[index];
            return _buildInvitationCard(context, ref, space);
          },
        );
      },
    );
  }

  Widget _buildInvitationCard(BuildContext context, WidgetRef ref, SpaceEntity space) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  radius: 24,
                  child: Icon(
                    space.icon,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        space.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'You\'ve been invited to join this space',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              space.description,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _handleDeclineInvitation(context, ref, space),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _handleAcceptInvitation(context, ref, space),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAcceptInvitation(BuildContext context, WidgetRef ref, SpaceEntity space) async {
    HapticFeedback.mediumImpact();
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      await repository.joinSpace(space.id);
      
      // Refresh the space providers
      ref.refresh(invitedSpacesProvider);
      ref.read(spacesProvider.notifier).refreshSpace(space.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have joined ${space.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining space: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleDeclineInvitation(BuildContext context, WidgetRef ref, SpaceEntity space) async {
    HapticFeedback.mediumImpact();
    
    // Here we would implement a way to decline an invitation
    // This would typically be a separate API call
    
    // For now, we'll show a snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation from ${space.name} declined'),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
