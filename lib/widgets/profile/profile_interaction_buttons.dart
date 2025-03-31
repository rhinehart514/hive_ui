import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/services/friend_service.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/providers/friend_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Widget for showing edit profile, friend request, message, and share buttons
class ProfileInteractionButtons extends ConsumerWidget {
  /// The user profile to render buttons for
  final UserProfile profile;

  /// Whether the profile being viewed belongs to the current user
  final bool isCurrentUser;

  /// Callback when edit profile is tapped
  final void Function(BuildContext context, UserProfile profile)? onEditProfile;

  /// Callback when request button is tapped
  final void Function(UserProfile profile)? onRequestFriend;

  /// Callback when message button is tapped
  final void Function(BuildContext context)? onMessage;

  /// Callback when share button is tapped
  final void Function(BuildContext context, UserProfile profile)?
      onShareProfile;

  const ProfileInteractionButtons({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onEditProfile,
    this.onRequestFriend,
    this.onMessage,
    this.onShareProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check friendship status using friend service
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    final params = (userId: currentUserId, friendId: profile.id);
    final isFriend = ref.watch(areFriendsProvider(params));
    final hasPendingRequest = ref.watch(hasPendingRequestProvider(params));

    return Row(
      children: [
        // Main action button (Edit Profile or Request)
        Expanded(
          flex: 5,
          child: _buildPrimaryButton(context, isFriend.asData?.value ?? false, hasPendingRequest.asData?.value ?? false),
        ),

        // Secondary action buttons (Message, Share)
        if (!isCurrentUser) ...[
          const SizedBox(width: 10),
          _buildIconButton(
            icon: HugeIcons.strokeRoundedMessageLock01,
            onPressed: () => onMessage?.call(context),
            isGold: true,
          ),
        ],

        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: _buildIconButton(
            icon: HugeIcons.share,
            onPressed: () => onShareProfile?.call(context, profile),
            isGold: false,
          ),
        ),
      ],
    );
  }

  /// Builds the primary action button with landing page styling
  Widget _buildPrimaryButton(BuildContext context, bool isFriend, bool hasPendingRequest) {
    if (isCurrentUser) {
      // Current user gets Edit Profile button - use HiveButton with updated style
      return SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          icon: const HugeIcon(
            icon: HugeIcons.pencilEdit,
            size: 24,
            color: AppColors.gold,
          ),
          label: Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            onEditProfile?.call(context, profile);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.only(left: 14, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(
                color: AppColors.gold,
                width: 1.0,
              ),
            ),
          ),
        ),
      );
    } else {
      // Other user gets Request button with different states
      String buttonText = 'Request';
      Color backgroundColor = Colors.white;
      Color textColor = Colors.black;
      
      if (isFriend) {
        buttonText = 'Friends';
        backgroundColor = Colors.transparent;
        textColor = AppColors.gold;
      } else if (hasPendingRequest) {
        buttonText = 'Requested';
        backgroundColor = Colors.grey[800]!;
        textColor = Colors.white;
      }
      
      return SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (!isFriend && !hasPendingRequest) {
              onRequestFriend?.call(profile);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: isFriend ? const BorderSide(color: AppColors.gold, width: 1.0) : BorderSide.none,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text(
            buttonText,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }

  /// Builds icon buttons for message and share functionality
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isGold,
  }) {
    return SizedBox(
      height: 44,
      width: 44,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isGold ? AppColors.gold : Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: isGold ? AppColors.gold : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
