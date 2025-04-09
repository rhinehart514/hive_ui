import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions for HIVE UI
/// Based on the Inter font family with defined sizes, weights and colors
class AppTypography {
  // Display texts (large headlines)
  static TextStyle get displayLarge => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    letterSpacing: -0.5, // Slightly tighter tracking
  );
  
  static TextStyle get displayMedium => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static TextStyle get displaySmall => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );
  
  // Title texts
  static TextStyle get titleLarge => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    letterSpacing: -0.25,
  );
  
  static TextStyle get titleMedium => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );
  
  static TextStyle get titleSmall => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  
  // Body texts
  static TextStyle get bodyLarge => GoogleFonts.inter(
    color: AppColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    color: AppColors.secondaryText, // Lighter gray
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1, // Slightly looser for readability
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    color: AppColors.secondaryText,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );
  
  // Label texts (often used for buttons, tabs, interactive elements)
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semibold
    letterSpacing: 0.1,
  );
  
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.1,
  );
  
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  
  // Special styles
  static TextStyle get caption => GoogleFonts.inter(
    color: AppColors.tertiaryText, // Lowest contrast gray
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2, // Looser for small sizes
  );
  
  static TextStyle get overline => GoogleFonts.inter(
    color: AppColors.tertiaryText,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4, // Wider tracking for overlines
    textBaseline: TextBaseline.alphabetic,
  );
  
  // Interactive styles (yellow accents)
  static TextStyle get interactive => GoogleFonts.inter(
    color: AppColors.yellow,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  static TextStyle get interactiveSmall => GoogleFonts.inter(
    color: AppColors.yellow,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  // Helper methods to modify styles
  
  /// Creates a copy of a text style with the yellow/gold interactive color
  static TextStyle makeInteractive(TextStyle style) {
    return style.copyWith(color: AppColors.yellow);
  }
  
  /// Creates a copy of a text style with the secondary text color
  static TextStyle makeSecondary(TextStyle style) {
    return style.copyWith(color: AppColors.secondaryText);
  }
  
  /// Creates a copy of a text style with the tertiary text color
  static TextStyle makeTertiary(TextStyle style) {
    return style.copyWith(color: AppColors.tertiaryText);
  }
} 