import 'package:flutter/material.dart';

/// Centralized color definitions for HIVE UI
/// Following the dark theme with gold accent aesthetic
class AppColors {
  // Core palette
  static const Color black = Color(0xFF0A0A0A);       // Primary background
  static const Color darkGray = Color(0xFF1C1C1E);    // Card background
  static const Color white = Color(0xFFFFFFFF);       // Primary text & bright accents
  static const Color secondaryText = Color(0xFFBFBFBF); // Secondary text (80% white)
  static const Color tertiaryText = Color(0xFF808080); // Tertiary text (50% white)
  static const Color yellow = Color(0xFFFFD700);      // Interactive accent 
  static const Color gold = yellow;                   // Alias for yellow
  
  // Surface colors
  static const Color surfacePrimary = darkGray;       // Primary content surface
  static const Color surfaceSecondary = Color(0xFF2C2C2E); // Secondary surface, slightly lighter
  
  // Functional colors
  static const Color success = Color(0xFF4CAF50);     // Success states
  static const Color error = Color(0xFFE57373);       // Error states
  static const Color warning = Color(0xFFFFB74D);     // Warning states
  static const Color info = Color(0xFF64B5F6);        // Information states
  
  // Interactive states
  static Color overlay = white.withOpacity(0.1);      // Touch/hover overlay
  static Color overlayDark = black.withOpacity(0.1);  // Dark overlay
  static Color yelllowOverlay = yellow.withOpacity(0.15); // Yellow button overlay
  
  // Gradients
  static const LinearGradient blackFade = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFF0A0A0A),
      Color(0x000A0A0A),
    ],
  );
  
  // Elevation overlays (for card surfaces at different elevations)
  static Color elevationOverlay(double elevation) {
    // Map elevation to opacity
    final double opacity = _getOverlayOpacityFromElevation(elevation);
    return white.withOpacity(opacity);
  }
  
  // Helper to calculate overlay opacity based on elevation
  static double _getOverlayOpacityFromElevation(double elevation) {
    if (elevation <= 0) return 0.0;
    // Map elevation ranges to opacity values
    if (elevation < 1) return 0.02;
    if (elevation < 2) return 0.04;
    if (elevation < 4) return 0.06;
    if (elevation < 6) return 0.08;
    if (elevation < 8) return 0.10;
    return 0.12; // Max overlay opacity
  }
  
  /// Generate a swatch from any color
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
  
  // Create swatch for primary color
  static final MaterialColor primarySwatch = createSwatch(gold);

  /// Main app colors
  static const Color primaryDark = Color(0xFF1E1E1E);
  static const Color primaryBackground = Color(0xFF121212);
  static const Color secondaryBackground = Color(0xFF252525);
  
  /// Accent colors
  static const Color accentGold = gold;
  static const Color accentBlue = Color(0xFF64B5F6);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color accentRed = Color(0xFFE57373);
  
  /// Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textHint = Color(0xFF757575);
  
  /// Other UI colors
  static const Color divider = Color(0xFF424242);
  static const Color cardBackground = Color(0xFF2D2D2D);
  static const Color shadowColor = Color(0x80000000);
} 