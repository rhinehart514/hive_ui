import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/theme/app_colors.dart'; // Use actual import
import '../widgets/create_event_fab.dart';
import '../widgets/space_content_feed.dart';
import '../widgets/space_sliver_header.dart';
// Use relative imports for state within the feature
import '../../state/space_providers.dart';
import '../../state/space_membership_state.dart';

// --- Placeholder AppColors removed ---

class SpaceScreen extends ConsumerWidget {
  final String spaceId;

  const SpaceScreen({required this.spaceId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optional: Listen for errors from the membership provider to show Snackbars
    // Correctly typed listener using imported state classes
    ref.listen<SpaceMembershipState>(spaceMembershipProvider(spaceId),
      (SpaceMembershipState? previous, SpaceMembershipState next) {
        // Check if the status transitioned TO error
        if (previous?.status != SpaceMembershipStatus.error && next.status == SpaceMembershipStatus.error) {
          // Use a post-frame callback to ensure ScaffoldMessenger is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
             // Check context validity before showing Snackbar
             // Also check if state object still exists (though less likely here)
             if (ScaffoldMessenger.of(context).mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(next.errorMessage ?? 'An error occurred'),
                        backgroundColor: AppColors.error, // Use theme error color
                    ),
                );
             }
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBackground, // Use theme color #0D0D0D
      // Use AnnotatedRegion to control status bar style for this screen
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light, // Keep status bar icons light on dark background
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // iOS-style scroll physics
          slivers: [
            SpaceSliverHeader(spaceId: spaceId),
            SpaceContentFeed(spaceId: spaceId),
          ],
        ),
      ),
      floatingActionButton: CreateEventFAB(spaceId: spaceId),
    );
  }
}

// --- Placeholder imports removed --- 