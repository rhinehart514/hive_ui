import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions for HIVE UI
/// Based on the HIVE Brand Aesthetic guide (brand_aesthetic.md Section 5)
/// 
/// NOTE: Uses Inter as a practical cross-platform alternative to SF Pro.
/// Ensure font assets are included if SF Pro is strictly required.
class AppTypography {
  
  // Base font family
  // Ideally 'SF Pro Display' or 'SF Pro Text' depending on usage
  static const _baseFont = GoogleFonts.inter;
  
  // Type Scale (approximating brand_aesthetic.md 14/17/22/28/34)
  
  // Headlines (SF Pro Display / Medium - brand_aesthetic.md Section 5.2)
  static TextStyle get headlineLarge => _baseFont(
    color: AppColors.textPrimary,
    fontSize: 28, // Spec: 28pt (max)
    fontWeight: FontWeight.w500, // Medium
    // letterSpacing: -0.5, // Kern headlines at -1.8% - fine-tune if needed
  );
  
  static TextStyle get headlineMedium => _baseFont(
    color: AppColors.textPrimary,
    fontSize: 22, // Spec: 22pt 
    fontWeight: FontWeight.w500, // Medium
    // letterSpacing: -0.5,
  );

  // Display/Titles (Using remaining sizes, map as appropriate)
  static TextStyle get displayLarge => _baseFont(
    color: AppColors.textPrimary,
    fontSize: 34, // Spec: 34pt
    fontWeight: FontWeight.w700, // Bold for largest display
    // letterSpacing: -0.5,
  );
  
  static TextStyle get displayMedium => headlineLarge; // Alias to headlineLarge (28pt)
  static TextStyle get displaySmall => headlineMedium; // Alias to headlineMedium (22pt)
  
  static TextStyle get titleLarge => headlineMedium; // Alias to headlineMedium (22pt)
  static TextStyle get titleMedium => bodyLarge; // Alias to bodyLarge (17pt, Semibold)

  // Body (SF Pro Text / Regular / 17pt - brand_aesthetic.md Section 5.2)
  static TextStyle get bodyLarge => _baseFont(
    color: AppColors.textPrimary,
    fontSize: 17, // Spec: 17pt
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0,
  );
  
  static TextStyle get bodyMedium => _baseFont(
    color: AppColors.textSecondary, // Use secondary color
    fontSize: 17, // Keep 17pt, differentiate by color/weight
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // Caption (SF Pro Text / Regular / 14pt - brand_aesthetic.md Section 5.2)
  static TextStyle get caption => _baseFont(
    color: AppColors.textSecondary, // Use secondary color
    fontSize: 14, // Spec: 14pt
    fontWeight: FontWeight.w400, // Regular
    letterSpacing: 0.1, 
  );
  
  static TextStyle get bodySmall => caption; // Alias to caption (14pt)

  // Label / Interactive Elements (SF Pro Text / Semibold / 17pt for CTAs - brand_aesthetic.md Section 5.2)
  // Using 14pt Medium for tab labels as per spec
  static TextStyle get labelLarge => _baseFont(
    fontSize: 17, // Spec: 17pt for CTA Buttons
    fontWeight: FontWeight.w600, // Semibold
    letterSpacing: 0.1,
    color: AppColors.textPrimary, // Default label color
  );
  
  static TextStyle get labelMedium => _baseFont(
    fontSize: 14, // Spec: 14pt for Tab Labels
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.1,
    color: AppColors.textPrimary, // Default label color
  );
  
  static TextStyle get labelSmall => _baseFont(
    fontSize: 12, // Smaller utility label
    fontWeight: FontWeight.w500, // Medium
    letterSpacing: 0.2,
    color: AppColors.textPrimary, // Default label color
  );
  
  static TextStyle get titleSmall => labelLarge.copyWith(fontWeight: FontWeight.w600); // Use 17pt Semibold for small titles
  
  // Special styles
  // Overline not explicitly in brand_aesthetic.md spec scale, use caption or labelSmall
  static TextStyle get overline => labelSmall.copyWith(
    color: AppColors.textTertiary,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4, 
    textBaseline: TextBaseline.alphabetic,
  );
  
  // Interactive styles (Buttons, Links)
  // Use labelLarge (17pt Semibold) for primary CTAs
  static TextStyle get button => labelLarge;
  
  // Use accentGold for specific interactive text links
  static TextStyle get interactiveLink => _baseFont(
    color: AppColors.accentGold,
    fontSize: 17, // Match bodyLarge/labelLarge
    fontWeight: FontWeight.w600, // Semibold
    letterSpacing: 0.1,
  );

  @Deprecated('Use button or interactiveLink styles')
  static TextStyle get interactive => interactiveLink;

  @Deprecated('Use caption or labelSmall with makeInteractive if needed')
  static TextStyle get interactiveSmall => labelMedium.copyWith(color: AppColors.accentGold);
  
  // Helper methods to modify styles
  
  /// Creates a copy of a text style with the gold interactive color
  static TextStyle makeInteractive(TextStyle style) {
    return style.copyWith(color: AppColors.accentGold);
  }
  
  /// Creates a copy of a text style with the secondary text color
  static TextStyle makeSecondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }
  
  /// Creates a copy of a text style with the tertiary text color
  static TextStyle makeTertiary(TextStyle style) {
    return style.copyWith(color: AppColors.textTertiary);
  }

  /// Creates a copy of a text style with the error color
  static TextStyle makeError(TextStyle style) {
    return style.copyWith(color: AppColors.error);
  }
} 