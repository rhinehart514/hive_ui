import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles for the application based on the HIVE brand aesthetic
class AppTextStyles {
  /// Display: Large screen titles
  static TextStyle get displayLarge => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  /// Title: Large card titles, section headers
  static TextStyle get titleLarge => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      );

  /// Body: Primary text content
  static TextStyle get bodyLarge => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  /// Body: Secondary text content
  static TextStyle get bodyMedium => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );

  /// Caption: Timestamps, metadata
  static TextStyle get caption => GoogleFonts.inter(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      );

  /// Label: Interactive text for buttons and key actions
  static TextStyle get labelLarge => GoogleFonts.inter(
        color: AppColors.yellow,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  /// Label: Smaller interactive text, icon labels
  static TextStyle get labelMedium => GoogleFonts.inter(
        color: AppColors.yellow,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );
} 