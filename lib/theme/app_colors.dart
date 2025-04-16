import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  /// Primary dark background
  static const dark = Color(0xFF121212);
  
  /// Secondary dark background
  static const dark2 = Color(0xFF1E1E1E);
  
  /// Tertiary dark background
  static const dark3 = Color(0xFF252525);
  
  /// Primary gold color
  static const gold = Color(0xFFFFD700);
  
  /// Lighter gold variant
  static const goldLight = Color(0xFFFFE455);
  
  /// Darker gold variant
  static const goldDark = Color(0xFFCCAC00);
  
  /// Primary accent color
  static const primary = gold;
  
  /// Text color for dark theme
  static const textDark = Colors.white;
  
  /// Secondary text color for dark theme
  static const textDarkSecondary = Color(0xFFAAAAAA);
  
  /// Error color
  static const error = Color(0xFFE57373);
  
  /// Success color
  static const success = Color(0xFF81C784);
  
  /// Warning color
  static const warning = Color(0xFFFFD54F);
  
  /// Info color
  static const info = Color(0xFF64B5F6);
  
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
      const Color(0xFF1A1A1A).withOpacity(0.65),
      const Color(0xFF252525).withOpacity(0.6),
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
  static const Color black = Color(0xFF000000); // Pure black
  static const Color white = Color(0xFFFFFFFF);
  static const Color yellow = gold; // Same as gold, maintained for semantic naming

  // Background colors - dark gray and subtle variations
  static const Color surface = Color(0xFF000000); // Pure black background

  // Text colors
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xFFBFBFBF); // Standardized secondary text color
  static const Color textTertiary = Color(0x99FFFFFF); // white60 - ambient information
  static const Color textDisabled = Color(0x61FFFFFF); // white38

  // Input colors
  static const Color inputBackground = Color(0xFF080808); // Nearly black
  static const Color inputBorder = Color(0x33FFFFFF); // white20 - subtle borders
  static const Color inputFocused = gold; // Gold for focus states

  // Button colors
  static const Color buttonPrimary = white; // White filled buttons
  static const Color buttonSecondary = Color(0xFF151515); // Dark buttons for secondary actions
  static const Color buttonText = black; // Black text on white buttons
  static const Color buttonDisabled = Color(0x61FFFFFF); // white38

  // Card colors
  static const Color cardBackground = Color(0xFF090909); // Nearly black for cards
  static const Color cardBorder = Color(0x1AFFFFFF); // white10 - very subtle borders
  static const Color cardHighlight = Color(0xFF151515); // Slightly lighter for hover/highlight

  // Divider and separator colors
  static const Color divider = Color(0x14FFFFFF); // white8 - whisper dividers
  static const Color separator = Color(0x0AFFFFFF); // white4 - even more subtle

  // Overlay colors
  static const Color modalOverlay = Color(0xCC000000); // black80 - for modal overlays
  static const Color bottomSheetBackground = Color(0xFF000000); // Pure black background

  // Status colors - muted tones that don't overwhelm
  static const Color warningStatus = warning; // Muted orange
  static const Color infoStatus = info; // Muted blue

  // Interaction colors
  static const Color ripple = Color(0x14FFFFFF); // white8 - subtle ripple
  static const Color shimmerBase = Color(0xFF000000); // Pure black background
  static const Color shimmerHighlight = Color(0xFF151515); // Visible contrast for shimmer

  // Social proof colors - more reserved
  static const Color attending = Color(0xFF66BB6A); // More subtle green for RSVPs
  static const Color friendsAttending = Color(0xFF42A5F5); // More subtle blue for friends

  // University colors
  static const Color ubBlue = Color(0xFF005BBB); // University at Buffalo blue

  // New transparent color
  static const Color transparent = Colors.transparent;
}
