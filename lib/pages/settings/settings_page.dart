import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/utils/glass_effect.dart';
import 'package:hive_ui/providers/settings_provider.dart'
    show settingsProvider, SettingsState, AppTheme;

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings provider to ensure it's initialized
    final settings = ref.watch(settingsProvider);

    // Performance tracking for settings page loading
    final Stopwatch loadStopwatch = Stopwatch()..start();

    // Debug log for tracking navigation flow
    debugPrint('⚙️ Settings page opened, initializing UI...');

    final scaffold = Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            debugPrint('⬅️ Returning from settings page');
            context.pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Gold accent gradient in background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.05),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Settings Section
                    _buildQuickSettings(context, ref, settings),
                    const SizedBox(height: 24),

                    // Account Section
                    _buildSectionHeader('Account & Privacy'),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      icon: HugeIcons.profile,
                      title: 'Profile Settings',
                      subtitle: 'Update your profile information',
                      onTap: () => context.goNamed('account_settings'),
                    ),
                    _buildSettingCard(
                      context,
                      icon: HugeIcons.lock,
                      title: 'Privacy & Security',
                      subtitle: 'Control your privacy and security settings',
                      onTap: () => context.goNamed('privacy_settings'),
                      showBadge: true,
                    ),

                    const SizedBox(height: 24),
                    // Preferences Section
                    _buildSectionHeader('App Settings'),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Customize your notifications',
                      onTap: () => context.goNamed('notification_settings'),
                    ),
                    _buildSettingCard(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Customize app theme and display',
                      onTap: () => context.goNamed('appearance_settings'),
                    ),

                    const SizedBox(height: 24),
                    // Support Section
                    _buildSectionHeader('Help & Support'),
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'Get help and contact support',
                      onTap: () => _showHelpCenterDialog(context),
                    ),
                    _buildSettingCard(
                      context,
                      icon: Icons.info_outline,
                      title: 'About HIVE',
                      subtitle: 'App information and legal',
                      onTap: () => _showAboutDialog(context),
                    ),

                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('Developer'),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        context,
                        icon: Icons.developer_mode,
                        title: 'Developer Tools',
                        subtitle: 'Debug and performance tools',
                        onTap: () => context.push(AppRoutes.developerTools),
                      ),
                    ],

                    const SizedBox(height: 24),
                    _buildLogoutButton(context, ref),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Log performance metrics
    loadStopwatch.stop();
    debugPrint(
        '✅ Settings page loaded in ${loadStopwatch.elapsedMilliseconds}ms');

    return scaffold;
  }

  Widget _buildQuickSettings(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Settings',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickSettingItem(
                context,
                icon: Icons.dark_mode,
                label: 'Dark Mode',
                isActive: settings.theme == AppTheme.dark,
                onTap: () => ref.read(settingsProvider.notifier).setTheme(
                    settings.theme == AppTheme.dark
                        ? AppTheme.system
                        : AppTheme.dark),
              ),
              _buildQuickSettingItem(
                context,
                icon: Icons.notifications,
                label: 'Notifications',
                isActive: settings.notificationsEnabled,
                onTap: () =>
                    ref.read(settingsProvider.notifier).toggleNotifications(),
              ),
              _buildQuickSettingItem(
                context,
                icon: Icons.data_saver_off,
                label: 'Data Saver',
                isActive: settings.dataSaverEnabled,
                onTap: () =>
                    ref.read(settingsProvider.notifier).toggleDataSaver(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold.withOpacity(0.1) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.gold : Colors.grey[700]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.gold : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? AppColors.gold : Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          debugPrint('🧭 Navigating to $title settings page');
          onTap();
        },
        child: RepaintBoundary(
          child: GlassContainer(
            opacity: 0.1,
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
                    child: Center(
                      child: Icon(
                        icon,
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
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      opacity: 0.05,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmationDialog(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: GoogleFonts.outfit(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
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
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Help Center',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you need assistance:',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@hiveapp.com',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.chat_bubble,
              title: 'Live Chat',
              subtitle: 'Available 9am-5pm ET',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.help_outline,
              title: 'FAQ',
              subtitle: 'Browse common questions',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'About HIVE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'HIVE',
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAboutItem(title: 'Version', value: '1.0.0'),
            _buildAboutItem(title: 'Build', value: '2023.06.15'),
            _buildAboutItem(
                title: 'Terms of Service', value: 'View', isLink: true),
            _buildAboutItem(
                title: 'Privacy Policy', value: 'View', isLink: true),
            _buildAboutItem(title: 'Licenses', value: 'View', isLink: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem({
    required String title,
    required String value,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isLink ? AppColors.gold : Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
