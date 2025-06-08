import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/hive_colors.dart';

/// Centralized color definitions for HIVE UI
/// Following the dark theme with gold accent aesthetic defined in brand_aesthetic.md
/// 
/// MIGRATION NOTE: This class is now deprecated in favor of HiveColors.
/// Use HiveColors directly for new code.
@Deprecated('Use HiveColors instead for new code')
class AppColors {
  // --- Core Palette (brand_aesthetic.md Section 8.1) ---
  static const Color primaryBackground = HiveColors.primaryBackground;
  static const Color textPrimary = HiveColors.textPrimary;
  static const Color accentGold = HiveColors.accent; 

  // Text hierarchy colors (using opacity on white/black)
  static const Color textSecondary = Color(0xCCFFFFFF); // ~80% white
  static const Color textTertiary = Color(0x99FFFFFF); // ~60% white
  static const Color textDisabled = Color(0x61FFFFFF); // ~38% white

  // --- Gold Accent States (brand_aesthetic.md Section 8.2) ---
  static const Color goldDefault = accentGold;
  static const Color goldHoverFocus = Color(0xFFFFDF2B); // +8% lightness adjustment (approx)
  static const Color goldPressed = Color(0xFFCCAD00);    // -15% lightness adjustment (approx)
  static const Color goldDisabled = Color(0x80FFD700); // 50% opacity

  // --- Semantic Colors (brand_aesthetic.md Section 8.3) ---
  static const Color success = Color(0xFF8CE563);      // Confirmation Green
  static const Color error = Color(0xFFFF3B30);        // iOS Error Red
  static const Color warning = Color(0xFFFF9500);      // iOS Warning Orange
  static const Color info = Color(0xFF56CCF2);         // Info Blue

  // --- Surface Definitions (brand_aesthetic.md Section 4.1) ---
  static const Color canvasColor = primaryBackground; // Base canvas
  static const Color surfaceStart = Color(0xFF1E1E1E); // Start of surface gradient
  static const Color surfaceEnd = Color(0xFF2A2A2A);   // End of surface gradient
  static const Color surfaceCard = Color(0xFF2D2D2D); // Fallback card background if not using gradient

  /// Gradient for standard surfaces (#1E1E1E to #2A2A2A)
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft, // Example: adjust as needed per design
    end: Alignment.bottomRight,
    colors: [surfaceStart, surfaceEnd],
  );

  /// Gradient for Glass Layers (brand_aesthetic.md Section 4.1)
  /// Tint: rgba(13, 13, 13, 0.8) == Color(0xCC0D0D0D)
  static const Color glassTint = Color(0xCC0D0D0D); 
  // Note: Blur and Gold streak overlay would be implemented via BackdropFilter/Shaders

  // --- Interactive states ---
  static Color overlayWhite = textPrimary.withOpacity(0.1);      // Touch/hover overlay on dark
  static Color overlayBlack = primaryBackground.withOpacity(0.1);  // Touch/hover overlay on light (if ever needed)
  static Color overlayGold = goldDefault.withOpacity(0.15); // Gold button overlay


  // --- Deprecated / To Be Refactored ---
  // Keeping old names temporarily for compatibility during refactor, pointing to new values
  @Deprecated('Use primaryBackground instead')
  static const Color black = primaryBackground;
  @Deprecated('Use surfaceCard or surfaceGradient instead')
  static const Color darkGray = surfaceCard;
  @Deprecated('Use textPrimary instead')
  static const Color white = textPrimary;
  @Deprecated('Use textSecondary instead')
  static const Color secondaryText = textSecondary; 
  @Deprecated('Use textTertiary instead')
  static const Color tertiaryText = textTertiary; 
  @Deprecated('Use accentGold instead')
  static const Color yellow = accentGold;
  @Deprecated('Use accentGold instead')
  static const Color gold = accentGold;
  @Deprecated('Use surfaceStart or surfaceGradient instead')
  static const Color surfacePrimary = surfaceStart;
  @Deprecated('Use surfaceEnd or surfaceGradient instead')
  static const Color surfaceSecondary = surfaceEnd;
  @Deprecated('Use accentGold states like goldDefault, goldHoverFocus etc.')
  static Color yelllowOverlay = overlayGold; 


  // --- Utility ---

  /// Generate a swatch from any color (standard Material utility)
  static MaterialColor createSwatch(Color color) {
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;
    
    return MaterialColor(color.value, {
      50: Color.fromRGBO(r, g, b, .1),
      100: Color.fromRGBO(r, g, b, .2),
      200: Color.fromRGBO(r, g, b, .3),
      300: Color.fromRGBO(r, g, b, .4),
      400: Color.fromRGBO(r, g, b, .5),
      500: Color.fromRGBO(r, g, b, .6),
      600: Color.fromRGBO(r, g, b, .7),
      700: Color.fromRGBO(r, g, b, .8),
      800: Color.fromRGBO(r, g, b, .9),
      900: Color.fromRGBO(r, g, b, 1),
    });
  }
  
  // Create swatch for primary accent color
  static final MaterialColor primarySwatch = createSwatch(accentGold);

  // --- Legacy / Potentially Unused ---
  // Review and remove these if they are not aligned with brand_aesthetic.md
  static const Color divider = Color(0x33FFFFFF); // ~20% White, adjust per spec
  static const Color shadowColor = Color(0x80000000); // Standard black shadow

  // Note: iOS constants should ideally live in a theme constants file, not colors.
  static const double iosCornerRadius = 13.0; // Example, use theme constants
  static const double iosButtonHeight = 56.0; // Example, use theme constants
  static const double iosSpacing = 16.0; // Example, use theme constants
  static const double iosBorderWidth = 0.5; // Example, use theme constants
} 