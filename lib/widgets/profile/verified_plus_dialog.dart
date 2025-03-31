import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Shows a dialog to upgrade to verified plus status
void showVerifiedPlusDialog(
    BuildContext context, WidgetRef ref, UserProfile profile) {
  showDialog(
    context: context,
    builder: (dialogContext) => VerifiedPlusDialog(
      ref: ref,
      profile: profile,
    ),
  );
}

/// A dialog for upgrading to verified plus status
class VerifiedPlusDialog extends ConsumerStatefulWidget {
  /// The WidgetRef for state access
  final WidgetRef ref;

  /// The user profile to upgrade
  final UserProfile profile;

  const VerifiedPlusDialog({
    super.key,
    required this.ref,
    required this.profile,
  });

  @override
  ConsumerState<VerifiedPlusDialog> createState() => _VerifiedPlusDialogState();
}

class _VerifiedPlusDialogState extends ConsumerState<VerifiedPlusDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold, width: 1),
      ),
      title: Text(
        "Verified+ Status",
        style: GoogleFonts.outfit(
          color: AppColors.gold,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.profile.accountTier == AccountTier.verifiedPlus
                ? "You already have Verified+ status."
                : "Would you like to upgrade to Verified+ status?",
            style: GoogleFonts.inter(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Verified+ members receive premium features and recognition in the Hive community.",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text(
            "Cancel",
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
        if (widget.profile.accountTier != AccountTier.verifiedPlus)
          _isProcessing
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: 24,
                  height: 24,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _upgradeToVerifiedPlus,
                  child: Text(
                    "Upgrade",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
      ],
    );
  }

  /// Handles the upgrade to verified plus
  Future<void> _upgradeToVerifiedPlus() async {
    if (_isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      // Update local state first (optimistic update)
      final updatedProfile = widget.profile.copyWith(
        accountTier: AccountTier.verifiedPlus,
      );

      // Show loading indicator in the dialog
      setState(() {});

      // Convert profile to JSON before updating
      await ref
          .read(profileProvider.notifier)
          .updateProfile(updatedProfile.toJson());

      if (mounted) {
        // Close the dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are now a Verified+ member!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close the dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upgrade: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
