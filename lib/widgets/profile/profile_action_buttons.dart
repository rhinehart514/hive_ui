import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/providers/activity_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/components/buttons.dart';
import 'package:hive_ui/theme/app_icons.dart';

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
  /// Whether the current user is following this profile
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = ref.watch(isCurrentUserProfileProvider);

    return Row(
      children: [
        Expanded(
          child: HiveButton(
            text: isCurrentUser
                ? 'Edit Profile'
                : (_isFollowing ? 'Following' : 'Follow'),
            variant: isCurrentUser
                ? HiveButtonVariant.tertiary
                : HiveButtonVariant.primary,
            size: HiveButtonSize.large,
            fullWidth: true,
            hapticFeedback: true,
            onPressed: () {
              if (isCurrentUser) {
                navigateToEditProfile(context);
              } else {
                _toggleFollow();
              }
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

  void _toggleFollow() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFollowing = !_isFollowing;
    });

    // This would be implemented with actual activity tracking in a real app
    // Example placeholder code:
    if (_isFollowing) {
      // Show feedback toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Following ${widget.profile.username}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share ${widget.profile.username}\'s Profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.content_copy,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(context);
                    // Copy profile link logic
                  },
                ),
                _buildShareOption(
                  icon: Icons.qr_code,
                  label: 'QR Code',
                  onTap: () {
                    Navigator.pop(context);
                    // Show QR code logic
                  },
                ),
                _buildShareOption(
                  icon: AppIcons.message,
                  label: 'Message',
                  onTap: () {
                    Navigator.pop(context);
                    // Share via message logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
