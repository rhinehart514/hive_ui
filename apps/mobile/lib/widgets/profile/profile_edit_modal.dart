import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/widgets/profile/modern_profile_editor.dart';

/// A peeking bottom sheet for profile editing
class ProfileEditModal extends StatefulWidget {
  /// The profile to edit
  final UserProfile profile;

  /// Callback when the profile is updated
  final Function(UserProfile) onProfileUpdated;

  const ProfileEditModal({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<ProfileEditModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(
                0,
                MediaQuery.of(context).size.height *
                    0.4 *
                    _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildPeekingSheet(context),
            ),
          ),
        );
      },
    );
  }

  /// Build the peeking version of the sheet
  Widget _buildPeekingSheet(BuildContext context) {
    return Container(
      height: 190, // Reduced height since we removed the swipe indicator
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            'Edit Profile',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Quick edit options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickEditOption(
                icon: HugeIcons.profile,
                label: 'Bio',
                onTap: () => _openFullEditor(context),
              ),
              _buildQuickEditOption(
                icon: Icons.school,
                label: 'Details',
                onTap: () => _openFullEditor(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEditOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1,
              ),
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
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Open the full profile editor
  void _openFullEditor(BuildContext context) {
    HapticFeedback.mediumImpact();

    // Hide bottom navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );

    // Close the modal first
    Navigator.of(context).pop();

    // Then open the full profile editor
    showModernProfileEditor(
      context,
      widget.profile,
      (updatedProfile) async {
        // Forward to the callback
        await widget.onProfileUpdated(updatedProfile);

        // Restore bottom navigation bar
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      },
    );
  }
}

/// Shows a peeking edit profile modal
void showProfileEditModal(
  BuildContext context,
  UserProfile profile,
  Function(UserProfile) onProfileUpdated,
) {
  HapticFeedback.mediumImpact();

  // Hide bottom navigation bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top],
  );

  // Go directly to the full profile editor
  showModernProfileEditor(
    context,
    profile,
    (updatedProfile) async {
      // Forward to the callback
      await onProfileUpdated(updatedProfile);

      // Restore bottom navigation bar
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    },
  );
}
