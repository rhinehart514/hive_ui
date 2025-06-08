import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/hive_colors.dart';

/// Application color scheme - Brand Aesthetic Compliant
/// 
/// MIGRATION NOTE: This class maintains legacy compatibility but now uses
/// HiveColors as the source of truth. Consider using HiveColors directly.
class AppColors {
  /// Primary brand color - HIVE Gold
  static const Color primaryColor = HiveColors.accent;
  
  /// Secondary brand color - Not used in brand aesthetic, kept for compatibility
  @Deprecated('Not part of HIVE brand aesthetic')
  static const Color secondaryColor = Color(0xFF6A3DE8);
  
  /// Accent color - Using HIVE Gold per brand aesthetic
  static const Color accentColor = HiveColors.accent;
  
  /// Background color - Using brand compliant dark background
  static const Color backgroundColor = HiveColors.primaryBackground;
  
  /// Card background color - Using brand compliant surface
  static const Color cardColor = HiveColors.surfaceStart;
  
  /// Surface color - Using brand compliant surface end
  static const Color surfaceColor = HiveColors.surfaceEnd;
  
  /// Primary text color - Using brand compliant white
  static const Color primaryTextColor = HiveColors.textPrimary;
  
  /// Secondary text color - Using brand compliant secondary
  static const Color secondaryTextColor = HiveColors.textSecondary;
  
  /// Disabled text color - Using brand compliant disabled
  static const Color disabledTextColor = HiveColors.textDisabled;
  
  /// Divider color - Using brand compliant divider
  static const Color dividerColor = HiveColors.divider;
  
  /// Error color - Using iOS standard per brand aesthetic
  static const Color errorColor = HiveColors.error;
  
  /// Warning color - Using iOS standard per brand aesthetic
  static const Color warningColor = HiveColors.warning;
  
  /// Success color - Using brand compliant success
  static const Color successColor = HiveColors.success;
  
  /// Info color - Using brand compliant info
  static const Color infoColor = HiveColors.info;
  
  /// Gradient start color
  static const Color gradientStartColor = Color(0xFF8A2BE2);
  
  /// Gradient end color
  static const Color gradientEndColor = Color(0xFF00BFFF);
  
  /// Overlay color for dimming backgrounds
  static const Color overlayColor = Color(0x88000000);
  
  /// Shadow color
  static const Color shadowColor = Color(0x40000000);
  
  /// Border color
  static const Color borderColor = Color(0xFF444444);
} 