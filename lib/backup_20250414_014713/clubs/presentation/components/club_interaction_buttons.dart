import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/user_providers.dart';

/// Component for club interaction buttons
class ClubInteractionButtons extends ConsumerWidget {
  final Club club;
  final bool isUserManager;
  final VoidCallback onJoinClub;
  final VoidCallback onEditClub;
  final VoidCallback onShareClub;
  final VoidCallback onConvertToSpace;

  const ClubInteractionButtons({
    super.key,
    required this.club,
    required this.isUserManager,
    required this.onJoinClub,
    required this.onEditClub,
    required this.onShareClub,
    required this.onConvertToSpace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user data to check if already a member
    final userData = ref.watch(userProvider);
    final isMember = userData?.joinedClubs.contains(club.id) ?? false;

    return Column(
      children: [
        // Primary action row
        Row(
          children: [
            // Join/Leave button
            Expanded(
              flex: 3,
              child: _buildJoinButton(context, isMember),
            ),
            const SizedBox(width: 12),
            // Edit club button (for managers)
            if (isUserManager) ...[
              Expanded(
                flex: 1,
                child: _buildEditButton(context),
              ),
            ],
            // Share button
            Expanded(
              flex: 1,
              child: _buildShareButton(context),
            ),
          ],
        ),

        // Additional actions for managers only
        if (isUserManager) ...[
          const SizedBox(height: 12),
          _buildConvertToSpaceButton(context),
        ],
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context, bool isMember) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onJoinClub();
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isMember ? Colors.transparent : AppColors.gold,
        foregroundColor: isMember ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: isMember
              ? BorderSide(color: Colors.white.withOpacity(0.3), width: 1)
              : BorderSide.none,
        ),
      ),
      child: Text(
        isMember ? 'Leave Club' : 'Join Club',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onEditClub();
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
      ),
      child: const Icon(
        Icons.edit_outlined,
        size: 20,
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onShareClub();
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
      ),
      child: const Icon(
        Icons.share_outlined,
        size: 20,
      ),
    );
  }

  Widget _buildConvertToSpaceButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onConvertToSpace();
      },
      icon: const Icon(
        Icons.rocket_launch_outlined,
        size: 18,
      ),
      label: Text(
        'Add to Spaces',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: AppColors.gold.withOpacity(0.6), width: 1),
        ),
      ),
    );
  }
}
