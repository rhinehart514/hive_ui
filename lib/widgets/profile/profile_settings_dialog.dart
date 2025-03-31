import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/scroll_settings_toggle.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/pages/settings/account_settings_page.dart';
import 'package:hive_ui/pages/settings/notification_settings_page.dart';
import 'package:hive_ui/pages/settings/appearance_settings_page.dart';
import 'package:go_router/go_router.dart';

/// Shows the settings page
void showProfileSettingsDialog(BuildContext context, WidgetRef ref) {
  HapticFeedback.mediumImpact();

  // Use GoRouter for navigation to ensure consistent app navigation
  context.push('/settings');
}

/// A dialog that displays profile settings options
class ProfileSettingsDialog extends ConsumerWidget {
  final WidgetRef ref;

  const ProfileSettingsDialog({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Section
            _buildSettingsSectionHeader('Profile'),

            // Account Settings option
            _buildSettingsNavItem(
              context: context,
              icon: Icons.account_circle,
              title: 'Account Settings',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage(),
                  ),
                );
              },
            ),

            // Privacy option - in account settings
            _buildSettingsNavItem(
              context: context,
              icon: Icons.privacy_tip,
              title: 'Privacy',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Preferences Section
            _buildSettingsSectionHeader('Preferences'),

            // Notification Settings option
            _buildSettingsNavItem(
              context: context,
              icon: Icons.notifications,
              title: 'Notification Settings',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),

            // Appearance option
            _buildSettingsNavItem(
              context: context,
              icon: Icons.palette,
              title: 'Appearance',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppearanceSettingsPage(),
                  ),
                );
              },
            ),

            // Scroll behavior setting
            _buildSettingsNavItem(
              context: context,
              icon: Icons.swipe,
              title: 'Scroll Behavior',
              trailing: const ScrollSettingsToggle(),
            ),

            const SizedBox(height: 20),

            // Support Section
            _buildSettingsSectionHeader('Support'),

            // Help Center option
            _buildSettingsNavItem(
              context: context,
              icon: Icons.help,
              title: 'Help Center',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                _showHelpCenterDialog(context);
              },
            ),

            // About option
            _buildSettingsNavItem(
              context: context,
              icon: Icons.info,
              title: 'About HIVE',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),

            // Logout Option
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                _showLogoutConfirmationDialog(context, ref);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red[300],
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Log Out',
                      style: GoogleFonts.inter(
                        color: Colors.red[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Helper method to build navigation items
  Widget _buildSettingsNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      )
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}

// Helper method to show help center dialog
void _showHelpCenterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Help Center',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.support_agent,
            color: AppColors.gold,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Need help with HIVE?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact our support team at support@hive.edu or visit our help center online.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.inter(
              color: AppColors.gold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Would open email app or browser in a real implementation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Support contact option would open here',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: Colors.grey[800],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
          ),
          child: Text(
            'Contact Support',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper method to show about dialog
void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Image.asset(
            'assets/images/hivelogo.png',
            height: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'About HIVE',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version 1.0.0',
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'HIVE is a platform designed to connect students with events, clubs, and other students on campus.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2023 HIVE Student Movement',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All rights reserved',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAboutButton(
                context,
                'Privacy Policy',
                Icons.privacy_tip,
              ),
              _buildAboutButton(
                context,
                'Terms of Service',
                Icons.description,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.inter(
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper to build about dialog buttons
Widget _buildAboutButton(BuildContext context, String title, IconData icon) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Would open $title',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.grey[800],
        ),
      );
    },
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// Helper to show logout confirmation
void _showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Log Out',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Are you sure you want to log out?',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: Colors.white70,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Close the dialog first
            Navigator.of(dialogContext).pop();

            // Store references to needed services before async gap
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // Sign out the user
            ref.read(authControllerProvider.notifier).signOut().then((_) {
              // Only proceed if the context is still valid
              if (context.mounted) {
                // Show feedback that logout worked - using stored reference
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'You have been logged out',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                );

                // In a real app, would navigate to login screen using the stored navigator
                // appNavigator.pushReplacementNamed(AppRoutes.landing);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[300],
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Log Out',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
