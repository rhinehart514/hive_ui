import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/providers/activity_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/components/buttons.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/widgets/profile/follow_button.dart';

/// A widget that displays the action buttons on a profile page
class ProfileActionButtons extends ConsumerStatefulWidget {
  /// The user profile associated with these buttons
  final UserProfile profile;

  /// Constructor
  const ProfileActionButtons({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<ProfileActionButtons> createState() =>
      _ProfileActionButtonsState();
}

class _ProfileActionButtonsState extends ConsumerState<ProfileActionButtons> {
  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = ref.watch(isCurrentUserProfileProvider);

    return Row(
      children: [
        if (isCurrentUser)
          Expanded(
            child: HiveButton(
              text: 'Edit Profile',
              variant: HiveButtonVariant.tertiary,
              size: HiveButtonSize.large,
              fullWidth: true,
              hapticFeedback: true,
              onPressed: () => navigateToEditProfile(context),
            ),
          )
        else
          Expanded(
            child: FollowButton(
              userId: widget.profile.id,
              onFollowStateChanged: (isFollowing) {
                // Optionally handle follow state changes
              },
            ),
          ),
        const SizedBox(width: 12),
        if (!isCurrentUser) ...[
          SizedBox(
            height: 54,
            width: 54,
            child: HiveButton(
              text: '',
              icon: AppIcons.message,
              variant: HiveButtonVariant.secondary,
              size: HiveButtonSize.large,
              hapticFeedback: true,
              onPressed: () => navigateToMessages(context),
            ),
          ),
          const SizedBox(width: 12),
        ],
        SizedBox(
          height: 54,
          width: 54,
          child: HiveButton(
            text: '',
            icon: Icons.share_outlined,
            variant: HiveButtonVariant.tertiary,
            size: HiveButtonSize.large,
            hapticFeedback: true,
            onPressed: () => shareProfile(context),
          ),
        ),
      ],
    );
  }

  void navigateToEditProfile(BuildContext context) {
    HapticFeedback.mediumImpact();
    // Navigation logic for edit profile
    context.push('/profile/edit');
  }

  void navigateToMessages(BuildContext context) {
    HapticFeedback.lightImpact();
    // Navigation logic for messages
    final chatId = widget.profile.id;
    context.push('/messages/$chatId');
  }

  void shareProfile(BuildContext context) {
    HapticFeedback.lightImpact();
    // Show share modal
    // Implementation in profile_page.dart
  }
}
