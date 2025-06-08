import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/hive_colors.dart';

/// App color palette - Brand Aesthetic Compliant
/// 
/// This class now acts as a facade over HiveColors for backward compatibility
/// while encouraging migration to the new HiveColors system.
/// 
/// MIGRATION NOTE: Consider using HiveColors directly for new code.
class AppColors {
  /// Primary dark background - per brand aesthetic (#0D0D0D)
  static const dark = HiveColors.primaryBackground;
  
  /// Secondary dark background - for cards, secondary surfaces (#1E1E1E)
  static const dark2 = HiveColors.surfaceStart;
  
  /// Tertiary dark background - using surface end for gradient consistency
  static const dark3 = HiveColors.surfaceEnd;
  
  /// Primary gold color - HIVE accent for key interactive elements (#FFD700)
  static const gold = HiveColors.accent;
  
  /// Lighter gold variant (+8% lightness)
  static const goldLight = HiveColors.goldHover;
  
  /// Darker gold variant (-15% lightness)
  static const goldDark = HiveColors.goldPressed;
  
  /// Primary accent color
  static const primary = gold;
  
  /// Alias for accent color used in many places
  static const accent = gold;
  
  /// Text color for dark theme - Primary (#FFFFFF)
  static const textDark = HiveColors.textPrimary;
  
  /// Secondary text color for dark theme (#B0B0B0)
  static const textDarkSecondary = HiveColors.textSecondary;
  
  /// Tertiary text color for dark theme (#757575)
  static const textDarkTertiary = HiveColors.textTertiary;
  
  /// Error color (#FF3B30) - iOS standard per brand aesthetic
  static const error = HiveColors.error;
  
  /// Success color (#8CE563) - per brand aesthetic
  static const success = HiveColors.success;
  
  /// Warning color (#FF9500) - iOS standard per brand aesthetic
  static const warning = HiveColors.warning;
  
  /// Info color (#56CCF2) - per brand aesthetic
  static const info = HiveColors.info;
  
  /// Grey scale colors
  static const grey = Color(0xFF9E9E9E);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);
  
  /// Gradient for the glassmorphic container
  static const glassGradient = HiveColors.glassGradient;
  
  /// Gold gradient
  static const goldGradient = HiveColors.goldGradient;
  
  /// Dark gradient for backgrounds
  static const darkGradient = HiveColors.backgroundGradient;

  // Primary colors - using HiveColors for consistency
  static const Color black = HiveColors.pureBlack;
  static const Color white = HiveColors.textPrimary;
  static const Color yellow = gold; // Same as gold, maintained for semantic naming

  // Background colors
  static const Color surface = HiveColors.primaryBackground;

  // Text colors
  static const Color textPrimary = HiveColors.textPrimary;
  static const Color textSecondary = HiveColors.textSecondary;
  static const Color textTertiary = HiveColors.textTertiary;
  static const Color textDisabled = HiveColors.textDisabled;
  static const Color textLink = Color(0xFF80B9F3); // For link elements - keeping existing

  // Input colors
  static const Color inputBackground = HiveColors.inputBackground;
  static const Color inputBorder = HiveColors.inputBorder;
  static const Color inputFocused = gold; // Gold for focus states

  // Button colors
  static const Color buttonPrimary = white; // White filled buttons
  static const Color buttonSecondary = Color(0x33FFFFFF); // 20% white opacity
  static const Color buttonText = HiveColors.textOnAccent; // Black text on gold buttons
  static const Color buttonDisabled = Color(0x4DFFFFFF); // 30% white opacity

  // Card colors
  static const Color cardBackground = HiveColors.cardBackground;
  static const Color cardBorder = HiveColors.cardBorder;
  static const Color cardHighlight = HiveColors.surfaceEnd; // Slightly lighter surface

  // Divider and separator colors
  static const Color divider = HiveColors.divider;
  static const Color separator = Color(0x1AFFFFFF); // 10% white opacity

  // Overlay colors
  static const Color modalOverlay = HiveColors.modalOverlay;
  static const Color bottomSheetBackground = HiveColors.primaryBackground;

  // Status colors - per brand aesthetic
  static const Color warningStatus = warning;
  static const Color infoStatus = info;

  // Interaction colors
  static const Color ripple = HiveColors.ripple;
  static const Color shimmerBase = HiveColors.shimmerBase;
  static const Color shimmerHighlight = HiveColors.shimmerHighlight;

  // Social proof colors
  static const Color attending = success; // Success color for RSVPs
  static const Color friendsAttending = info; // Info color for friends

  // University colors
  static const Color ubBlue = HiveColors.ubBlue;

  // Transparent color
  static const Color transparent = HiveColors.transparent;
}
