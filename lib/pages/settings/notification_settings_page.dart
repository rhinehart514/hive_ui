import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/settings_provider.dart';

// Using central settings provider instead of local state provider
// final notificationSettingsProvider = StateProvider<Map<String, bool>>((ref) {
//   return {
//     'pushEnabled': true,
//     'emailEnabled': true,
//     'messagesNotif': true,
//     'eventsNotif': true,
//     'commentsNotif': true,
//     'tagsNotif': true,
//     'followersNotif': true,
//     'clubsNotif': true,
//     'marketingNotif': false,
//     'soundEnabled': true,
//     'vibrationEnabled': true,
//   };
// });

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

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
          'Notification Settings',
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
                _buildSectionHeader('General'),
                const SizedBox(height: 16),

                // Push Notifications Toggle
                _buildToggleSetting(
                  context,
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications on your device',
                  value: settingsState.pushNotificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .togglePushNotifications();
                    HapticFeedback.selectionClick();
                  },
                ),

                // Email Notifications Toggle
                _buildToggleSetting(
                  context,
                  title: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  value: settingsState.emailNotificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleEmailNotifications();
                    HapticFeedback.selectionClick();
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Notification Types'),
                const SizedBox(height: 16),

                // Messages Notifications - use generic notifications setting for now
                _buildToggleSetting(
                  context,
                  title: 'Messages',
                  subtitle: 'When you receive a new message',
                  value: settingsState.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleNotifications();
                    HapticFeedback.selectionClick();
                  },
                ),

                // Events Notifications - use generic notifications setting for now
                _buildToggleSetting(
                  context,
                  title: 'Events',
                  subtitle: 'Updates about events you\'re following',
                  value: settingsState.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleNotifications();
                    HapticFeedback.selectionClick();
                  },
                ),

                // Other notification type toggles - using local state for now as placeholders
                // In a real implementation, these would be connected to backend settings
                _buildPlaceholderToggleSetting(
                  context,
                  title: 'Comments & Replies',
                  subtitle: 'When someone replies to your content',
                  defaultValue: true,
                ),

                _buildPlaceholderToggleSetting(
                  context,
                  title: 'Tags & Mentions',
                  subtitle: 'When you\'re tagged in a post or comment',
                  defaultValue: true,
                ),

                _buildPlaceholderToggleSetting(
                  context,
                  title: 'New Followers',
                  subtitle: 'When someone follows you',
                  defaultValue: true,
                ),

                _buildPlaceholderToggleSetting(
                  context,
                  title: 'Clubs & Spaces',
                  subtitle: 'Updates from clubs you\'re a member of',
                  defaultValue: true,
                ),

                _buildPlaceholderToggleSetting(
                  context,
                  title: 'Marketing & Promotions',
                  subtitle: 'Offers, updates, and news from HIVE',
                  defaultValue: false,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Preferences'),
                const SizedBox(height: 16),

                // Sound and vibration toggles - placeholders for now
                _buildPlaceholderToggleSetting(
                  context,
                  title: 'Sound',
                  subtitle: 'Play sound when receiving notifications',
                  defaultValue: true,
                ),

                _buildPlaceholderToggleSetting(
                  context,
                  title: 'Vibration',
                  subtitle: 'Vibrate when receiving notifications',
                  defaultValue: true,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Quiet Hours'),
                const SizedBox(height: 16),

                // Quiet Hours Setting
                _buildQuietHoursSetting(context),

                const SizedBox(height: 30),

                // Reset Notification Settings
                _buildResetButton(context, ref),

                const SizedBox(height: 16),
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
              onChanged: onChanged,
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

  // Placeholder toggle setting for settings not yet connected to backend
  Widget _buildPlaceholderToggleSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool defaultValue,
  }) {
    return StatefulBuilder(builder: (context, setState) {
      bool value = defaultValue;

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
                  setState(() {
                    value = newValue;
                  });
                  // Show a message that this is a placeholder
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This setting is not yet connected to the backend',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      backgroundColor: Colors.grey[800],
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
    });
  }

  Widget _buildQuietHoursSetting(BuildContext context) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quiet Hours',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: false, // Set default value
                  onChanged: (newValue) {
                    HapticFeedback.lightImpact();
                    // Handle quiet hours toggle
                  },
                  activeColor: AppColors.gold,
                  activeTrackColor: AppColors.gold.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mute notifications during specified hours',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '10:00 PM',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '7:00 AM',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showResetConfirmationDialog(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Reset to Default Settings',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reset Notifications',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all notification settings to default?',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
          ),
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
              // Reset all settings to defaults
              final settingsNotifier = ref.read(settingsProvider.notifier);

              // Toggle settings to ensure they're at default values
              if (!settingsNotifier.state.pushNotificationsEnabled) {
                settingsNotifier.togglePushNotifications();
              }

              if (!settingsNotifier.state.emailNotificationsEnabled) {
                settingsNotifier.toggleEmailNotifications();
              }

              if (!settingsNotifier.state.notificationsEnabled) {
                settingsNotifier.toggleNotifications();
              }

              Navigator.pop(context);

              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notification settings reset to default',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
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
              'Reset',
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
