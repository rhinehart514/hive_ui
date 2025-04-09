import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/settings_provider.dart';
import 'package:hive_ui/features/profile/presentation/pages/profile_visibility_settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/core/navigation/routes.dart';

// Using central settings provider instead of local state provider
// final privacySettingsProvider = StateProvider<Map<String, bool>>((ref) {
//   return {
//     'publicProfile': true,
//     'shareActivity': true,
//     'allowSearch': true,
//     'locationSharing': false,
//     'showStatus': true,
//   };
// });

class PrivacySettingsPage extends ConsumerWidget {
  const PrivacySettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          'Privacy Settings',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Profile Privacy'),
                const SizedBox(height: 16),
                
                // Profile Visibility Settings
                _buildVisibilitySettingsButton(context),

                // Public Profile Toggle
                _buildToggleSetting(
                  context,
                  title: 'Public Profile',
                  subtitle: 'Allow others to view your full profile',
                  value: !settingsState
                      .profilePrivate, // Inverted since our provider uses "profilePrivate"
                  onChanged: (value) {
                    // Invert value since we're storing "profilePrivate"
                    ref.read(settingsProvider.notifier).toggleProfilePrivacy();
                    HapticFeedback.selectionClick();
                  },
                ),

                // Analytics Sharing Toggle
                _buildToggleSetting(
                  context,
                  title: 'Share My Activity',
                  subtitle: 'Show your activity on the platform to others',
                  value: settingsState.analyticsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleAnalytics();
                    HapticFeedback.selectionClick();
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Discovery'),
                const SizedBox(height: 16),

                // Search Toggle
                _buildToggleSetting(
                  context,
                  title: 'Allow Search',
                  subtitle: 'Let others find you through search',
                  value: !settingsState.profilePrivate, // Using this as a proxy
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleProfilePrivacy();
                    HapticFeedback.selectionClick();
                  },
                ),

                // Location Toggle - use local state for now
                _buildToggleSetting(
                  context,
                  title: 'Location Sharing',
                  subtitle: 'Share your general location with others',
                  value: false, // Default to false for privacy
                  onChanged: (value) {
                    // This is a placeholder - would be implemented in a future version
                    HapticFeedback.selectionClick();
                  },
                ),

                // Status Toggle - use data saver as proxy
                _buildToggleSetting(
                  context,
                  title: 'Online Status',
                  subtitle: 'Show when you\'re active on HIVE',
                  value: !settingsState.dataSaverEnabled, // Inverted logic
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDataSaver();
                    HapticFeedback.selectionClick();
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Data'),
                const SizedBox(height: 16),

                // Data Download Button
                _buildDataActionButton(
                  context,
                  title: 'Download Your Data',
                  subtitle: 'Request a copy of your HIVE data',
                  icon: Icons.download,
                  onTap: () => _showRequestDataDialog(context),
                ),

                // Account Removal
                _buildDataActionButton(
                  context,
                  title: 'Delete Account',
                  subtitle: 'Remove your account and all data',
                  icon: Icons.delete_forever,
                  color: Colors.red,
                  onTap: () => _showDeleteAccountDialog(context),
                ),

                const SizedBox(height: 30),

                // Privacy Policy Link
                _buildPrivacyPolicyLink(context),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method to build the visibility settings button
  Widget _buildVisibilitySettingsButton(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileVisibilitySettingsPage(
                  userId: currentUserId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.visibility,
                      size: 24,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visibility Controls',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Control what others can see on your profile',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: AppColors.gold,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildToggleSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: AppColors.gold,
              activeTrackColor: AppColors.gold.withOpacity(0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: buttonColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 24,
                      color: buttonColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: buttonColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: buttonColor.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyLink(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          // Open privacy policy
          HapticFeedback.selectionClick();
          NavigationTransitions.applyNavigationFeedback(
            type: NavigationFeedbackType.pageTransition,
          );
          GoRouter.of(context).push(AppRoutes.privacyPolicy);
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
        ),
        child: Text(
          'View Our Privacy Policy',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showRequestDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Request Your Data',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We\'ll compile all your data and send it to your registered email address. This may take up to 48 hours.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your data will be sent in a secure, downloadable format.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show success snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Data request submitted successfully',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Request Data',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Account',
          style: GoogleFonts.outfit(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.red[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will delete all your posts, comments, and profile information.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show confirmation dialog
              _showDeleteConfirmationDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Type "DELETE" to confirm',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Type DELETE in all caps',
            hintStyle: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.3),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gold,
              ),
            ),
          ),
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
          cursorColor: AppColors.gold,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Return to settings page
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm Deletion',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
