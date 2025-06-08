import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Defines the text styles used throughout the HIVE application.
/// Adheres to the HIVE brand aesthetic guidelines.
class AppTypography {
  // Font Family (Define primary and fallback)
  static const String _primaryFontFamily = 'SF Pro Display'; // Or SF Pro Text depending on usage
  static const String _fallbackFontFamily = 'Inter';

  // Core Text Styles (Aligned with HIVE specs: 14, 17, 22, 28, 34 pt)

  /// Headline Large (e.g., Major screen titles) - SF Pro Display Medium 34pt
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _primaryFontFamily,
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 34,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textPrimary,
    height: 1.2, // Adjust for line spacing
    letterSpacing: 0.37,
  );
  
  /// Headline Medium (e.g., Onboarding Titles) - SF Pro Display Medium 28pt
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _primaryFontFamily,
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 28,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textPrimary,
    height: 1.21,
    letterSpacing: 0.36,
  );

  /// Title 1 (e.g., Card Titles, Section Headers) - SF Pro Display Regular 22pt
  static const TextStyle title1 = TextStyle(
    fontFamily: _primaryFontFamily,
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 22,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textPrimary,
    height: 1.27,
    letterSpacing: 0.35,
  );

  /// Title 2 / Body Emphasis (e.g., Button Text, Strong Body) - SF Pro Text Semibold 17pt
  static const TextStyle title2 = TextStyle(
    fontFamily: 'SF Pro Text', // Use Text variant for body sizes
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 17,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
    height: 1.29,
    letterSpacing: -0.41,
  );

  /// Body / Default Text - SF Pro Text Regular 17pt
  static const TextStyle body = TextStyle(
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 17,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textPrimary,
    height: 1.29,
    letterSpacing: -0.41,
  );

  /// Body Bold - SF Pro Text Semibold 17pt (Same as title2, potentially redundant)
  static const TextStyle bodyBold = title2;

  /// Callout (e.g., Secondary button text, emphasized captions) - SF Pro Text Regular 16pt (Closest allowed size)
  /// Note: 16pt is not in the primary scale (14, 17, 22...) but often used for callouts.
  /// Adjusting to 17pt for strict adherence or keeping 16pt if necessary.
  /// Let's use 17pt Regular slightly less prominent color.
  static const TextStyle callout = TextStyle(
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 17, // Using 17pt as 16 is not standard HIVE scale
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary, // Slightly less prominent
    height: 1.3,
    letterSpacing: -0.32,
  );

  /// Subheadline (e.g., List item subtitles) - SF Pro Text Regular 15pt
  /// Note: 15pt is not in the primary scale. Using 14pt instead.
  static const TextStyle subheadline = TextStyle(
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 14, // Using 14pt as 15 is not standard HIVE scale
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary,
    height: 1.3,
    letterSpacing: -0.24,
  );

  /// Caption / Small Text - SF Pro Text Regular 14pt
  static const TextStyle caption = TextStyle(
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary,
    height: 1.25,
    letterSpacing: -0.08,
  );
  
  /// Caption Bold / Small Emphasis - SF Pro Text Semibold 14pt
  static const TextStyle captionBold = TextStyle(
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: [_fallbackFontFamily],
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.08,
  );

  // Prevent instantiation
  AppTypography._();
} 