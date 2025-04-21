import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  /// Primary dark background - per brand aesthetic (0d0d0d)
  static const dark = Color(0xFF0D0D0D);
  
  /// Secondary dark background - for cards, secondary surfaces (1E1E1E)
  static const dark2 = Color(0xFF1E1E1E);
  
  /// Tertiary dark background
  static const dark3 = Color(0xFF252525);
  
  /// Primary gold color - HIVE accent for key interactive elements (#EEB700)
  static const gold = Color(0xFFEEB700);
  
  /// Lighter gold variant
  static const goldLight = Color(0xFFF7C735);
  
  /// Darker gold variant
  static const goldDark = Color(0xFFDAA500);
  
  /// Primary accent color
  static const primary = gold;
  
  /// Alias for accent color used in many places
  static const accent = gold;
  
  /// Text color for dark theme - Primary (#FFFFFF)
  static const textDark = Colors.white;
  
  /// Secondary text color for dark theme (#B0B0B0)
  static const textDarkSecondary = Color(0xFFB0B0B0);
  
  /// Tertiary text color for dark theme (#757575)
  static const textDarkTertiary = Color(0xFF757575);
  
  /// Error color (#FF5252)
  static const error = Color(0xFFFF5252);
  
  /// Success color (#4CAF50)
  static const success = Color(0xFF4CAF50);
  
  /// Warning color (#FFC107)
  static const warning = Color(0xFFFFC107);
  
  /// Info color (#2196F3)
  static const info = Color(0xFF2196F3);
  
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
  static final glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFF1A1A1A).withOpacity(0.75), // Using rgba(18,18,18,0.75) with 8px blur
      const Color(0xFF252525).withOpacity(0.7),
    ],
    stops: const [0.1, 1.0],
  );
  
  /// Gold gradient
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gold,
      goldDark,
    ],
    stops: [0.0, 1.0],
  );
  
  /// Dark gradient
  static final darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      dark.withOpacity(0.8),
      dark2.withOpacity(0.85),
    ],
    stops: const [0.0, 1.0],
  );

  // Primary colors
  static const Color black = Color(0xFF000000); // Pure black, reserved for persistent navigation only
  static const Color white = Color(0xFFFFFFFF);
  static const Color yellow = gold; // Same as gold, maintained for semantic naming

  // Background colors
  static const Color surface = Color(0xFF000000); // Pure black for persistent navigation

  // Text colors
  static const Color textPrimary = white; // Primary text
  static const Color textSecondary = Color(0xFFB0B0B0); // Secondary text
  static const Color textTertiary = Color(0xFF757575); // Tertiary information and hints
  static const Color textDisabled = Color(0xFF757575); // For disabled interface elements
  static const Color textLink = Color(0xFF80B9F3); // For link elements

  // Input colors
  static const Color inputBackground = dark2; // Secondary surface for inputs
  static const Color inputBorder = Color(0x33FFFFFF); // white20 - subtle borders
  static const Color inputFocused = gold; // Gold for focus states

  // Button colors
  static const Color buttonPrimary = white; // White filled buttons
  static const Color buttonSecondary = Color(0x33FFFFFF); // Transparent with 30% white border
  static const Color buttonText = black; // Black text on primary buttons
  static const Color buttonDisabled = Color(0x4DFFFFFF); // white30 for disabled buttons

  // Card colors
  static const Color cardBackground = dark2; // Secondary surface for cards (#1E1E1E)
  static const Color cardBorder = Color(0x1AFFFFFF); // white10 - very subtle borders
  static const Color cardHighlight = Color(0xFF252525); // Slightly lighter for hover/highlight

  // Divider and separator colors
  static const Color divider = Color(0x1AFFFFFF); // white10 for dividers
  static const Color separator = Color(0x0AFFFFFF); // white4 - even more subtle

  // Overlay colors
  static const Color modalOverlay = Color(0xCC000000); // black80 - for modal overlays
  static const Color bottomSheetBackground = Color(0xFF000000); // Pure black background

  // Status colors - per brand aesthetic
  static const Color warningStatus = warning; // #FFC107
  static const Color infoStatus = info; // #2196F3

  // Interaction colors
  static const Color ripple = Color(0x14FFFFFF); // white8 - subtle ripple
  static const Color shimmerBase = Color(0xFF0D0D0D); // Primary dark background
  static const Color shimmerHighlight = Color(0xFF1E1E1E); // Secondary surface for shimmer highlight

  // Social proof colors
  static const Color attending = success; // Success color for RSVPs
  static const Color friendsAttending = info; // Info color for friends

  // University colors
  static const Color ubBlue = Color(0xFF005BBB); // University at Buffalo blue

  // Transparent color
  static const Color transparent = Colors.transparent;
}
