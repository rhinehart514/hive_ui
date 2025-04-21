import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/theme/app_colors.dart'; // Use actual import
// import 'package:hive_ui/core/theme/spacing.dart'; // Assuming Spacing exists
import '../../state/space_membership_state.dart';
import '../../state/space_providers.dart';

// --- Placeholder AppColors removed ---
// --- Placeholder Spacing removed (assuming defined elsewhere or used directly) ---

class CreateEventFAB extends ConsumerWidget {
  final String spaceId;

  const CreateEventFAB({required this.spaceId, super.key});

  // TODO: Replace with actual navigation logic to event creation screen
  void _navigateToCreateEvent(BuildContext context, String spaceId) {
    HapticFeedback.mediumImpact();
    print("Navigate to Create Event for Space: $spaceId");
    // Example: Navigator.push(context, CreateEventRoute(spaceId: spaceId));
    // Example: context.go('/spaces/$spaceId/create_event');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipState = ref.watch(spaceMembershipProvider(spaceId));

    // Only show FAB if the user is joined and has permission
    if (membershipState.status != SpaceMembershipStatus.joined ||
        !membershipState.canCreateEvents) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () => _navigateToCreateEvent(context, spaceId),
      backgroundColor: AppColors.secondaryBackground, // Use theme color #1E1E1E
      foregroundColor: AppColors.white,
      elevation: 4, // Subtle elevation
      focusColor: AppColors.accentGold.withOpacity(0.1), // Use accent for focus glow indication
      hoverColor: AppColors.overlay, // Use theme overlay
      splashColor: AppColors.overlay, // Use theme overlay
      tooltip: 'Create Event',
      // Ensure minimum touch target size is met intrinsically by FAB
      child: const Icon(Icons.add),
      // TODO: Potentially apply focus glow effect using a wrapper widget if ButtonStyle is insufficient
    );
  }
} 