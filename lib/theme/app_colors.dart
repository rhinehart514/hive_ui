import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color black =
      Color(0xFF000000); // Pure black
  static const Color white = Color(0xFFFFFFFF);
  static const Color gold =
      Color(0xFFFFD700); // Signal yellow, used for interactive elements
  static const Color yellow =
      Color(0xFFFFD700); // Same as gold, maintained for semantic naming

  // Background colors - dark gray and subtle variations
  static const Color grey600 = Color(0xFF151515); // Subtle shade for separation
  static const Color grey700 = Color(0xFF101010); // Very subtle contrast
  static const Color grey800 = Color(0xFF080808); // Nearly black
  static const Color surface = Color(0xFF000000); // Pure black background

  // Text colors
  static const Color textPrimary = white;
  static const Color textSecondary =
      Color(0xFFBFBFBF); // Standardized secondary text color
  static const Color textTertiary =
      Color(0x99FFFFFF); // white60 - ambient information
  static const Color textDisabled = Color(0x61FFFFFF); // white38

  // Input colors
  static const Color inputBackground =
      Color(0xFF080808); // Nearly black
  static const Color inputBorder =
      Color(0x33FFFFFF); // white20 - subtle borders
  static const Color inputFocused = gold; // Gold for focus states

  // Button colors
  static const Color buttonPrimary = white; // White filled buttons
  static const Color buttonSecondary =
      Color(0xFF151515); // Dark buttons for secondary actions
  static const Color buttonText = black; // Black text on white buttons
  static const Color buttonDisabled = Color(0x61FFFFFF); // white38

  // Card colors
  static const Color cardBackground =
      Color(0xFF090909); // Nearly black for cards
  static const Color cardBorder =
      Color(0x1AFFFFFF); // white10 - very subtle borders
  static const Color cardHighlight =
      Color(0xFF151515); // Slightly lighter for hover/highlight

  // Divider and separator colors
  static const Color divider = Color(0x14FFFFFF); // white8 - whisper dividers
  static const Color separator = Color(0x0AFFFFFF); // white4 - even more subtle

  // Overlay colors
  static const Color modalOverlay =
      Color(0xCC000000); // black80 - for modal overlays
  static const Color bottomSheetBackground =
      Color(0xFF000000); // Pure black background

  // Status colors - muted tones that don't overwhelm
  static const Color error = Color(0xFFE57373); // Muted red
  static const Color success = Color(0xFF81C784); // Muted green
  static const Color warning = Color(0xFFFFB74D); // Muted orange
  static const Color info = Color(0xFF64B5F6); // Muted blue

  // Interaction colors
  static const Color ripple = Color(0x14FFFFFF); // white8 - subtle ripple
  static const Color shimmerBase = Color(0xFF000000); // Pure black background
  static const Color shimmerHighlight =
      Color(0xFF151515); // Visible contrast for shimmer

  // Social proof colors - more reserved
  static const Color attending =
      Color(0xFF66BB6A); // More subtle green for RSVPs
  static const Color friendsAttending =
      Color(0xFF42A5F5); // More subtle blue for friends

  // University colors
  static const Color ubBlue = Color(0xFF005BBB); // University at Buffalo blue

  // New transparent color
  static const Color transparent = Colors.transparent;
}
