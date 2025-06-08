import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_theme.dart' as main_theme;

/// Unified theme constants for the messaging feature
/// Inspired by Apple's Messages app with a cleaner black and white design
class AppTheme {
  // Spacing constants - reuse from main theme
  static const double spacing2 = main_theme.AppTheme.spacing2;
  static const double spacing4 = main_theme.AppTheme.spacing4;
  static const double spacing8 = main_theme.AppTheme.spacing8;
  static const double spacing10 = 10.0; // Added for input field padding
  static const double spacing12 = main_theme.AppTheme.spacing12;
  static const double spacing16 = main_theme.AppTheme.spacing16;
  static const double spacing20 = main_theme.AppTheme.spacing20;
  static const double spacing24 = main_theme.AppTheme.spacing24;
  static const double spacing32 = main_theme.AppTheme.spacing32;
  static const double spacing40 = main_theme.AppTheme.spacing40;
  static const double spacing48 = main_theme.AppTheme.spacing48;
  static const double spacing64 = main_theme.AppTheme.spacing64;

  // Border radius constants - refined for more iOS-like appearance
  static const double radiusNone = main_theme.AppTheme.radiusNone;
  static const double radiusXs = main_theme.AppTheme.radiusXs;
  static const double radiusSm = 12.0; // More rounded for bubbles
  static const double radiusMd = 18.0; // More rounded for bubbles
  static const double radiusLg = 24.0;
  static const double radiusXl = 28.0;
  static const double radiusXxl = 32.0;
  static const double radiusFull = main_theme.AppTheme.radiusFull;

  // Text styles - reuse from main theme
  static TextStyle get displayLarge => main_theme.AppTheme.displayLarge;
  static TextStyle get displayMedium => main_theme.AppTheme.displayMedium;
  static TextStyle get displaySmall => main_theme.AppTheme.displaySmall;
  static TextStyle get headlineSmall => main_theme.AppTheme.headlineSmall;
  static TextStyle get titleMedium => main_theme.AppTheme.titleMedium;
  static TextStyle get titleSmall => main_theme.AppTheme.titleSmall;
  static TextStyle get bodyLarge => main_theme.AppTheme.bodyLarge;
  static TextStyle get bodyMedium => main_theme.AppTheme.bodyMedium;
  static TextStyle get bodySmall => main_theme.AppTheme.bodySmall;
  static TextStyle get labelLarge => main_theme.AppTheme.labelLarge;
  static TextStyle get labelMedium => main_theme.AppTheme.labelMedium;
  static TextStyle get labelSmall => main_theme.AppTheme.labelSmall;

  // Messaging-specific constants - inspired by Apple Messages
  static const Color currentUserBubbleColor =
      Color(0xFF333333); // Dark gray instead of gold
  static const Color otherUserBubbleColor =
      Color(0xFF1A1A1A); // Darker for dark mode
  static const Color threadIndicatorColor =
      Color(0xFFEEBA2A); // Subtle yellow accent
  static const Color replyingToBackgroundColor = Color(0xFF1A1A1A);
  static const Color typingIndicatorColor =
      Color(0xFFEEBA2A); // Subtle yellow accent

  // Elevations - specific to messaging but using AppColors
  static List<BoxShadow> get shadowSm => [
        const BoxShadow(
          color: Color(0x12000000), // Less pronounced shadow
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        const BoxShadow(
          color: Color(0x14000000), // Less pronounced shadow
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

  // Animations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);
}
