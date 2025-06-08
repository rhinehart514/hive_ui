import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/settings_provider.dart';
import 'package:hive_ui/core/accessibility/accessibility_providers.dart';

/// Enum for app theme options - using the one from settings_provider.dart
// enum AppTheme {
//   system,
//   light,
//   dark,
//   highContrast,
// }

/// Enum for accent color options
enum AccentColor {
  gold,
  blue,
  green,
  purple,
  pink,
}

// Using central settings provider instead of local provider
// final appearanceSettingsProvider = StateNotifierProvider<AppearanceSettingsNotifier, AppearanceState>((ref) {
//   return AppearanceSettingsNotifier();
// });

/// Local state only for accent color and other UI aspects not in the central provider
final accentColorProvider =
    StateProvider<AccentColor>((ref) => AccentColor.gold);
final highContrastTextProvider = StateProvider<bool>((ref) => false);
final reduceAnimationsProvider = StateProvider<bool>((ref) => false);

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the central settings provider
    final settingsState = ref.watch(settingsProvider);

    // Use local state providers for settings not in the central provider
    final accentColor = ref.watch(accentColorProvider);
    final highContrastText = ref.watch(highContrastTextProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);

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
          'Appearance',
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
                // Theme section
                _buildSectionHeader('Theme'),
                const SizedBox(height: 16),

                // Theme selector - connects to central provider
                _buildThemeSelector(context, ref, settingsState.theme),

                const SizedBox(height: 24),

                // Text section
                _buildSectionHeader('Text'),
                const SizedBox(height: 16),

                // Font scale slider - connects to central provider
                _buildFontScaleSelector(context, ref, settingsState.fontScale),

                // High contrast text toggle - local state only
                const SizedBox(height: 16),
                _buildToggleSetting(
                  context,
                  title: 'High Contrast Text',
                  subtitle: 'Increase text contrast for better readability',
                  value: highContrastText,
                  onChanged: (value) {
                    ref.read(highContrastTextProvider.notifier).state = value;

                    // Show a message indicating this is a UI-only change
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'High contrast text setting is UI-only and not persisted yet',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: Colors.grey[800],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Accessibility section
                _buildSectionHeader('Accessibility'),
                const SizedBox(height: 16),

                // Reduce animations toggle
                _buildToggleSetting(
                  context,
                  title: 'Reduce Animations',
                  subtitle: 'Minimize animated effects throughout the app',
                  value: reduceAnimations,
                  onChanged: (value) {
                    ref.read(reduceAnimationsProvider.notifier).state = value;

                    // Show a message indicating this is a UI-only change
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Animation setting is UI-only and not persisted yet',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: Colors.grey[800],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Data saver toggle - connects to central provider
                _buildToggleSetting(
                  context,
                  title: 'Data Saver',
                  subtitle: 'Reduce data usage by loading lower quality images',
                  value: settingsState.dataSaverEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDataSaver();
                    HapticFeedback.selectionClick();
                  },
                ),

                const SizedBox(height: 24),

                // Accent Color section
                _buildSectionHeader('Accent Color'),
                const SizedBox(height: 16),

                // Accent color selector - local state only
                _buildAccentColorSelector(context, ref, accentColor),

                const SizedBox(height: 24),

                // Preview section
                _buildSectionHeader('Preview'),
                const SizedBox(height: 16),

                _buildPreview(context, ref),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated methods to connect to the central provider
  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, AppTheme currentTheme) {
    return Container(
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
            Text(
              'App Theme',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildThemeOption(
                  context,
                  'System',
                  Icons.smartphone,
                  currentTheme == AppTheme.system,
                  () => ref
                      .read(settingsProvider.notifier)
                      .setTheme(AppTheme.system),
                ),
                _buildThemeOption(
                  context,
                  'Dark',
                  Icons.dark_mode,
                  currentTheme == AppTheme.dark,
                  () => ref
                      .read(settingsProvider.notifier)
                      .setTheme(AppTheme.dark),
                ),
                _buildThemeOption(
                  context,
                  'Light',
                  Icons.light_mode,
                  currentTheme == AppTheme.light,
                  () => ref
                      .read(settingsProvider.notifier)
                      .setTheme(AppTheme.light),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontScaleSelector(
      BuildContext context, WidgetRef ref, double currentScale) {
    return Container(
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
                  'Text Size',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(currentScale * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: AppColors.gold,
                overlayColor: AppColors.gold.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: currentScale,
                min: 0.8,
                max: 1.3,
                divisions: 5,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setFontScale(value);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'A',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'A',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for the UI components
  Widget _buildAccentColorSelector(
      BuildContext context, WidgetRef ref, AccentColor currentColor) {
    return Container(
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
            Text(
              'Accent Color',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(
                    context, ref, AccentColor.gold, Colors.amber, currentColor),
                _buildColorOption(
                    context, ref, AccentColor.blue, Colors.blue, currentColor),
                _buildColorOption(context, ref, AccentColor.green, Colors.green,
                    currentColor),
                _buildColorOption(context, ref, AccentColor.purple,
                    Colors.purple, currentColor),
                _buildColorOption(
                    context, ref, AccentColor.pink, Colors.pink, currentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    WidgetRef ref,
    AccentColor color,
    Color displayColor,
    AccentColor currentColor,
  ) {
    final isSelected = currentColor == color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(accentColorProvider.notifier).state = color;

        // Show a message that this is a UI-only change
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Color setting is UI-only and not persisted yet',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }

  // Helper methods
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

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.gold.withOpacity(0.1) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.gold : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final highContrastText = ref.watch(highContrastTextProvider);
    final settingsState = ref.watch(settingsProvider);

    // Convert enum to color
    Color accentColorValue = AppColors.gold;
    switch (accentColor) {
      case AccentColor.gold:
        accentColorValue = AppColors.gold;
        break;
      case AccentColor.blue:
        accentColorValue = Colors.blue;
        break;
      case AccentColor.green:
        accentColorValue = Colors.green;
        break;
      case AccentColor.purple:
        accentColorValue = Colors.purple;
        break;
      case AccentColor.pink:
        accentColorValue = Colors.pink;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColorValue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: GoogleFonts.outfit(
              color: accentColorValue,
              fontSize: 20 * settingsState.fontScale,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is how your content will look with the selected settings.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(highContrastText ? 1.0 : 0.8),
              fontSize: 14 * settingsState.fontScale,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColorValue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: accentColorValue,
                  size: 20 * settingsState.fontScale,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Button and interactive elements will use the accent color',
                    style: GoogleFonts.inter(
                      color: Colors.white
                          .withOpacity(highContrastText ? 1.0 : 0.9),
                      fontSize: 13 * settingsState.fontScale,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColorValue,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Example Button',
              style: GoogleFonts.inter(
                fontSize: 14 * settingsState.fontScale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
