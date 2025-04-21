import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/theme/app_colors.dart'; // Use actual import
// import 'package:hive_ui/core/theme/app_theme.dart'; // Assuming AppTheme provides text styles
import '../../state/space_membership_state.dart';
import '../../state/space_providers.dart';

// --- Placeholder AppColors removed ---

class JoinLeaveButton extends ConsumerWidget {
  final String spaceId;

  const JoinLeaveButton({required this.spaceId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipState = ref.watch(spaceMembershipProvider(spaceId));
    final membershipNotifier = ref.read(spaceMembershipProvider(spaceId).notifier);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final bool isLoading = membershipState.status == SpaceMembershipStatus.loading;
    final bool isJoined = membershipState.status == SpaceMembershipStatus.joined;

    Widget buttonChild;
    VoidCallback? onPressed = isLoading ? null : () {
      HapticFeedback.lightImpact(); // Basic haptic feedback
      if (isJoined) {
        membershipNotifier.leaveSpace();
      } else {
        membershipNotifier.joinSpace();
      }
    };

    if (isLoading) {
      buttonChild = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white), // Use actual AppColors.white
        ),
      );
    } else {
      buttonChild = Text(
        isJoined ? 'Joined' : 'Join',
        style: textTheme.bodyMedium?.copyWith(
          color: isJoined ? AppColors.black : AppColors.white, // Use actual AppColors
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Define styles based on HIVE design system
    final ButtonStyle primaryStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.white, // Primary: White background
      foregroundColor: AppColors.black, // Primary: Black text
      shape: const StadiumBorder(), // Pill shape
      minimumSize: const Size(80, 36), // Ensure min width and height
      padding: const EdgeInsets.symmetric(horizontal: 16), // TODO: Replace with Spacing.md
      elevation: 0, // No elevation per spec
      // Use AppColors.overlay for hover/pressed states consistent with theme
    ).copyWith(
       overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) return AppColors.overlayDark; // Dark overlay on white
            if (states.contains(MaterialState.hovered)) return AppColors.overlayDark.withOpacity(0.5);
            return null;
          },
        ),
    );

    final ButtonStyle secondaryStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.white, // Secondary: White text/border
      side: BorderSide(color: AppColors.white.withOpacity(0.3), width: 1), // 30% white border
      shape: const StadiumBorder(), // Pill shape
      minimumSize: const Size(80, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16), // TODO: Replace with Spacing.md
      // Use AppColors.overlay for hover/pressed states consistent with theme
    ).copyWith(
       overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) return AppColors.overlay;
            if (states.contains(MaterialState.hovered)) return AppColors.overlay.withOpacity(0.5);
            return null;
          },
        ),
    );

    // Focus highlight (common for both)
    final ButtonStyle focusedStyle = ButtonStyle(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.focused)) {
            // Use actual accent color
            return AppColors.accentGold.withOpacity(0.1);
          }
          return null;
        },
      ),
      // Note: Implementing the exact 2px glow might require a custom painter or wrapper widget
    );

    final ButtonStyle currentBaseStyle = isJoined ? primaryStyle : secondaryStyle;
    final ButtonStyle finalStyle = currentBaseStyle.merge(focusedStyle);

    // Handle Error State visually (optional, could show snackbar instead)
    if (membershipState.status == SpaceMembershipStatus.error) {
      // Optionally, change button appearance or show error nearby
      // For now, we rely on Snackbar/Dialog for errors
      // Consider showing a tooltip or disabling the button with an error icon
      print("Space Membership Error: ${membershipState.errorMessage}");
      // Example: Show a snackbar (requires ScaffoldMessenger)
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   if (ScaffoldMessenger.of(context).mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(content: Text(membershipState.errorMessage ?? 'An error occurred')),
      //       );
      //   }
      // });
    }

    return isJoined
        ? ElevatedButton(
            style: finalStyle,
            onPressed: onPressed,
            child: buttonChild,
          )
        : OutlinedButton(
            style: finalStyle,
            onPressed: onPressed,
            child: buttonChild,
          );
  }
} 