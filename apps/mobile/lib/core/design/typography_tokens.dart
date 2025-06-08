import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/hive_colors.dart';

/// HIVE Typography System - 2025-Ready, Tech-Sleek Stack
/// 
/// This system implements the modern typography stack with Inter Tight for displays,
/// General Sans for body text, and proper scaling/rhythm following HIVE brand guidelines.
/// 
/// Font Stack:
/// - Display/H1-H2: Inter Tight (variable) - Ultra-compact counters for bold headlines
/// - Body/UI: General Sans (with Inter fallback) - Humanist grotesque with tall x-height
/// - Code/Metrics: JetBrains Mono - Punched-out "0" for tool composition
/// - Editorial Accent: Space Grotesk Semibold (optional) - For ritual countdowns
/// 
/// Scale follows 4-pt baseline rhythm with proper tracking for dark mode OLED displays.
class TypographyTokens {
  
  // ===============================
  //        FONT FAMILIES
  // ===============================
  
  /// Primary display font - Inter Tight for ultra-compact headlines
  static String get displayFont => GoogleFonts.interTight().fontFamily ?? 'Inter Tight';
  
  /// Body and UI font - General Sans with Inter fallback
  /// Note: Using Inter as General Sans is not available in Google Fonts
  static String get bodyFont => GoogleFonts.inter().fontFamily ?? 'Inter';
  
  /// Code and metrics font - JetBrains Mono for tool composition
  static String get codeFont => GoogleFonts.jetBrainsMono().fontFamily ?? 'JetBrains Mono';
  
  /// Editorial accent font - Space Grotesk for ritual countdowns
  static String get accentFont => GoogleFonts.spaceGrotesk().fontFamily ?? 'Space Grotesk';
  
  /// Fallback chain for graceful degradation
  static const List<String> fallbackChain = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif'
  ];
  
  // ===============================
  //     BASE TEXT STYLES
  // ===============================
  
  /// Creates base text style with HIVE defaults
  static TextStyle _createBaseStyle({
    required String fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    required double lineHeight,
    required double letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackChain,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight / fontSize, // Convert to Flutter's height ratio
      letterSpacing: letterSpacing,
      color: color ?? HiveColors.textPrimary,
      textBaseline: TextBaseline.alphabetic,
    );
  }
  
  // ===============================
  //      DISPLAY STYLES
  // ===============================
  
  /// H1 Display - Inter Tight, 32pt, -1% tracking
  /// For major screen titles and hero headlines
  static TextStyle get h1 => _createBaseStyle(
    fontFamily: displayFont,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    lineHeight: 40,
    letterSpacing: -0.32, // -1% of font size
  );
  
  /// H2 Display - Inter Tight, 24pt, -0.5% tracking  
  /// For section headers and major divisions
  static TextStyle get h2 => _createBaseStyle(
    fontFamily: displayFont,
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semibold
    lineHeight: 32,
    letterSpacing: -0.12, // -0.5% of font size
  );
  
  /// H3 Display - Inter Tight, 20pt, 0% tracking
  /// For subsection headers
  static TextStyle get h3 => _createBaseStyle(
    fontFamily: displayFont,
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    lineHeight: 28,
    letterSpacing: 0,
  );
  
  // ===============================
  //       BODY STYLES
  // ===============================
  
  /// Body Large - General Sans (Inter), 16pt, 0.25% tracking
  /// Primary body text for comfortable reading
  static TextStyle get body => _createBaseStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    lineHeight: 24,
    letterSpacing: 0.04, // +0.25% for dark mode readability
  );
  
  /// Body Medium - General Sans (Inter), 14pt, 0.5% tracking
  /// Secondary text, descriptions, metadata
  static TextStyle get bodySecondary => _createBaseStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    lineHeight: 20,
    letterSpacing: 0.07, // +0.5% for smaller text
    color: HiveColors.textSecondary,
  );
  
  /// Caption - General Sans (Inter), 14pt, 1% tracking
  /// Small utility text, timestamps, labels
  static TextStyle get caption => _createBaseStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    lineHeight: 20,
    letterSpacing: 0.14, // +1% tracking for tight spaces
    color: HiveColors.textTertiary,
  );
  
  // ===============================
  //      CODE & METRICS
  // ===============================
  
  /// Code/Mono - JetBrains Mono, 13pt, 0% tracking
  /// For tool composition, metrics, technical displays
  static TextStyle get mono => _createBaseStyle(
    fontFamily: codeFont,
    fontSize: 13,
    fontWeight: FontWeight.w400, // Regular
    lineHeight: 20,
    letterSpacing: 0,
  );
  
  /// Code Bold - JetBrains Mono, 13pt, Medium weight
  /// For emphasized code elements and key values
  static TextStyle get monoBold => _createBaseStyle(
    fontFamily: codeFont,
    fontSize: 13,
    fontWeight: FontWeight.w500, // Medium
    lineHeight: 20,
    letterSpacing: 0,
  );
  
  // ===============================
  //     INTERACTIVE STYLES
  // ===============================
  
  /// Button Primary - General Sans (Inter), 16pt, Semibold
  /// For primary CTAs and important actions
  static TextStyle get buttonPrimary => _createBaseStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semibold
    lineHeight: 24,
    letterSpacing: 0.04,
    color: HiveColors.textOnAccent, // Black text on gold buttons
  );
  
  /// Button Secondary - General Sans (Inter), 14pt, Medium
  /// For secondary actions and smaller buttons
  static TextStyle get buttonSecondary => _createBaseStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    lineHeight: 20,
    letterSpacing: 0.07,
  );
  
  /// Link - General Sans (Inter), 16pt, Semibold, Gold accent
  /// For interactive links and text buttons
  static TextStyle get link => _createBaseStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semibold
    lineHeight: 24,
    letterSpacing: 0.04,
    color: HiveColors.accent,
  );
  
  // ===============================
  //    EDITORIAL ACCENT STYLES
  // ===============================
  
  /// Ritual Countdown - Space Grotesk, 20pt, Semibold
  /// For ritual countdowns and special announcements
  static TextStyle get ritualCountdown => _createBaseStyle(
    fontFamily: accentFont,
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    lineHeight: 28,
    letterSpacing: 0,
    color: HiveColors.accent,
  );
  
  /// Editorial Emphasis - Space Grotesk, 16pt, Medium
  /// For special callouts and featured content
  static TextStyle get editorialEmphasis => _createBaseStyle(
    fontFamily: accentFont,
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    lineHeight: 24,
    letterSpacing: 0.04,
  );
  
  // ===============================
  //        HELPER METHODS
  // ===============================
  
  /// Creates a "surging" variant of any text style
  /// Animates font-weight from 400→600 over 400ms for dynamic emphasis
  static TextStyle makeSurging(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: baseStyle.color ?? HiveColors.accent,
    );
  }
  
  /// Applies dark mode tuning: +2% tracking for text below 16px
  /// Helps combat glow-blur on OLED displays
  static TextStyle applyDarkModetuning(TextStyle style) {
    if ((style.fontSize ?? 16) < 16) {
      final currentSpacing = style.letterSpacing ?? 0;
      final additionalSpacing = (style.fontSize ?? 14) * 0.02; // +2%
      return style.copyWith(letterSpacing: currentSpacing + additionalSpacing);
    }
    return style;
  }
  
  /// Creates interactive variant with gold accent color
  static TextStyle makeInteractive(TextStyle style) {
    return style.copyWith(color: HiveColors.accent);
  }
  
  /// Creates disabled variant with reduced opacity
  static TextStyle makeDisabled(TextStyle style) {
    return style.copyWith(
      color: (style.color ?? HiveColors.textPrimary).withOpacity(0.38),
    );
  }
  
  /// Creates error variant with error color
  static TextStyle makeError(TextStyle style) {
    return style.copyWith(color: HiveColors.error);
  }
  
  /// Creates success variant with success color
  static TextStyle makeSuccess(TextStyle style) {
    return style.copyWith(color: HiveColors.success);
  }
  
  // ===============================
  //    FLUTTER THEME MAPPING
  // ===============================
  
  /// Maps HIVE typography to Flutter's TextTheme for system integration
  static TextTheme get flutterTextTheme => TextTheme(
    // Display styles
    displayLarge: h1,
    displayMedium: h2,
    displaySmall: h3,
    
    // Headline styles (aliased to display for consistency)
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    
    // Title styles
    titleLarge: h3,
    titleMedium: body.copyWith(fontWeight: FontWeight.w600),
    titleSmall: bodySecondary.copyWith(fontWeight: FontWeight.w600),
    
    // Body styles
    bodyLarge: body,
    bodyMedium: bodySecondary,
    bodySmall: caption,
    
    // Label styles
    labelLarge: buttonPrimary,
    labelMedium: buttonSecondary,
    labelSmall: caption.copyWith(fontWeight: FontWeight.w500),
  );
}

/// Animation helper for font weight transitions
/// Use with AnimatedDefaultTextStyle for smooth surging effects
class FontWeightTween extends Tween<FontWeight> {
  FontWeightTween({
    FontWeight? begin = FontWeight.w400,
    FontWeight? end = FontWeight.w600,
  }) : super(begin: begin, end: end);
  
  @override
  FontWeight lerp(double t) {
    final beginIndex = _fontWeightToIndex(begin!);
    final endIndex = _fontWeightToIndex(end!);
    final lerpedIndex = beginIndex + (endIndex - beginIndex) * t;
    return _indexToFontWeight(lerpedIndex.round());
  }
  
  int _fontWeightToIndex(FontWeight weight) {
    switch (weight) {
      case FontWeight.w100: return 0;
      case FontWeight.w200: return 1;
      case FontWeight.w300: return 2;
      case FontWeight.w400: return 3;
      case FontWeight.w500: return 4;
      case FontWeight.w600: return 5;
      case FontWeight.w700: return 6;
      case FontWeight.w800: return 7;
      case FontWeight.w900: return 8;
      default: return 3;
    }
  }
  
  FontWeight _indexToFontWeight(int index) {
    switch (index) {
      case 0: return FontWeight.w100;
      case 1: return FontWeight.w200;
      case 2: return FontWeight.w300;
      case 3: return FontWeight.w400;
      case 4: return FontWeight.w500;
      case 5: return FontWeight.w600;
      case 6: return FontWeight.w700;
      case 7: return FontWeight.w800;
      case 8: return FontWeight.w900;
      default: return FontWeight.w400;
    }
  }
} 