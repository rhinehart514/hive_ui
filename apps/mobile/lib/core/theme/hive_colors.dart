import 'package:flutter/material.dart';

/// HIVE Color System - Brand Aesthetic Compliant
/// 
/// This class centralizes all color definitions following the HIVE brand aesthetic
/// guidelines defined in memory-bank/brand_aesthetic.md
/// 
/// Core Philosophy:
/// - Primary Background: #0D0D0D (Deep Matte Black)
/// - Secondary Surface: #1E1E1E to #2A2A2A gradient
/// - Text: Pure #FFFFFF
/// - Accent: #FFD700 (Gold) - Used ONLY for focus rings, live status, key triggers
class HiveColors {
  // ========================
  // CORE BRAND PALETTE
  // ========================
  
  /// Primary Background: Deep Matte Black (#0D0D0D)
  /// Used for: App root, splash screens, main canvas
  static const Color primaryBackground = Color(0xFF0D0D0D);
  
  /// Secondary Surface Start: #1E1E1E
  /// Used for: Gradient start for cards and surfaces
  static const Color surfaceStart = Color(0xFF1E1E1E);
  
  /// Secondary Surface End: #2A2A2A
  /// Used for: Gradient end for cards and surfaces
  static const Color surfaceEnd = Color(0xFF2A2A2A);
  
  /// Primary Text: Pure White (#FFFFFF)
  /// Used for: Headlines, vital data, primary text
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Gold Accent: #FFD700
  /// CRITICAL: Use ONLY for focus rings, live status, key triggers
  /// NEVER use for backgrounds, text, or decorative elements
  static const Color accent = Color(0xFFFFD700);
  
  // ========================
  // GOLD ACCENT STATES
  // ========================
  
  /// Default Gold State: #FFD700 at 100% opacity
  static const Color goldDefault = accent;
  
  /// Hover/Focus Gold State: #FFDF2B (+8% lightness)
  static const Color goldHover = Color(0xFFFFDF2B);
  
  /// Pressed Gold State: #CCAD00 (-15% lightness)
  static const Color goldPressed = Color(0xFFCCAD00);
  
  /// Disabled Gold State: #FFD700 at 50% opacity
  static const Color goldDisabled = Color(0x80FFD700);
  
  // ========================
  // TEXT HIERARCHY
  // ========================
  
  /// Secondary Text: Body copy, metadata
  /// Using white with reduced opacity instead of separate gray colors
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  /// Tertiary Text: Placeholder text, less important info
  static const Color textTertiary = Color(0xFF757575);
  
  /// Disabled Text: For disabled interface elements
  static const Color textDisabled = Color(0xFF666666);
  
  /// Text on Accent: Black text for use on gold backgrounds
  static const Color textOnAccent = Color(0xFF000000);
  
  // ========================
  // SEMANTIC COLORS
  // ========================
  
  /// Success: #8CE563 - Use sparingly for confirmations only
  static const Color success = Color(0xFF8CE563);
  
  /// Error: #FF3B30 - iOS standard, recognized instantly
  static const Color error = Color(0xFFFF3B30);
  
  /// Warning: #FF9500 - iOS standard, use for temporary issues
  static const Color warning = Color(0xFFFF9500);
  
  /// Info: #56CCF2 - For neutral alerts and notifications
  static const Color info = Color(0xFF56CCF2);
  
  // ========================
  // COMPONENT COLORS
  // ========================
  
  /// Card Background: Uses surface gradient, fallback to surfaceStart
  static const Color cardBackground = surfaceStart;
  
  /// Card Border: Subtle white border for active states only
  static const Color cardBorder = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  
  /// Input Background: Secondary surface for input fields
  static const Color inputBackground = surfaceStart;
  
  /// Input Border: Subtle white border for normal state
  static const Color inputBorder = Color(0x33FFFFFF); // 20% white
  
  /// Button Background: Uses surface gradient
  static const Color buttonBackground = surfaceStart;
  
  /// Divider: Subtle separation lines
  static const Color divider = Color(0x1AFFFFFF); // 10% white
  
  /// Modal Overlay: Black with 80% opacity for dimming
  static const Color modalOverlay = Color(0xCC000000);
  
  // ========================
  // INTERACTION COLORS
  // ========================
  
  /// Ripple Effect: Subtle touch feedback
  static const Color ripple = Color(0x14FFFFFF); // 8% white
  
  /// Shimmer Base: For loading states
  static const Color shimmerBase = primaryBackground;
  
  /// Shimmer Highlight: For loading states
  static const Color shimmerHighlight = surfaceStart;
  
  // ========================
  // GRADIENTS
  // ========================
  
  /// Standard Surface Gradient: #1E1E1E → #2A2A2A
  /// Used for: Cards, buttons, secondary surfaces
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceStart, surfaceEnd],
    stops: [0.0, 1.0],
  );
  
  /// Dark Background Gradient: Primary background variations
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBackground, Color(0xFF0A0A0A)],
    stops: [0.0, 1.0],
  );
  
  /// Gold Accent Gradient: For special highlighting
  /// Use sparingly and only for key interactive elements
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldDefault, goldPressed],
    stops: [0.0, 1.0],
  );
  
  /// Glass Layer Gradient: For glassmorphic effects
  /// Blur effects should be implemented separately with BackdropFilter
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCC0D0D0D), // rgba(13, 13, 13, 0.8)
      Color(0xB30D0D0D), // rgba(13, 13, 13, 0.7)
    ],
    stops: [0.0, 1.0],
  );
  
  // ========================
  // OPACITY HELPERS
  // ========================
  
  /// Creates a color with specified opacity while maintaining color integrity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// White with 10% opacity - for subtle overlays
  static Color get white10 => withOpacity(textPrimary, 0.1);
  
  /// White with 20% opacity - for borders and dividers
  static Color get white20 => withOpacity(textPrimary, 0.2);
  
  /// White with 30% opacity - for disabled buttons
  static Color get white30 => withOpacity(textPrimary, 0.3);
  
  /// Gold with 15% opacity - for gold overlays
  static Color get gold15 => withOpacity(accent, 0.15);
  
  /// Gold with 40% opacity - for focus states and hover
  static Color get gold40 => withOpacity(accent, 0.4);
  
  // ========================
  // MATERIAL COLOR SWATCH
  // ========================
  
  /// Creates a Material Design color swatch from any color
  static MaterialColor createMaterialSwatch(Color color) {
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;
    
    return MaterialColor(color.value, {
      50: Color.fromRGBO(r, g, b, 0.1),
      100: Color.fromRGBO(r, g, b, 0.2),
      200: Color.fromRGBO(r, g, b, 0.3),
      300: Color.fromRGBO(r, g, b, 0.4),
      400: Color.fromRGBO(r, g, b, 0.5),
      500: Color.fromRGBO(r, g, b, 0.6),
      600: Color.fromRGBO(r, g, b, 0.7),
      700: Color.fromRGBO(r, g, b, 0.8),
      800: Color.fromRGBO(r, g, b, 0.9),
      900: Color.fromRGBO(r, g, b, 1.0),
    });
  }
  
  /// Primary Material Swatch based on gold accent
  static final MaterialColor primarySwatch = createMaterialSwatch(accent);
  
  // ========================
  // LEGACY COMPATIBILITY
  // ========================
  // These aliases maintain backward compatibility while encouraging migration
  // to the new naming convention
  
  @Deprecated('Use HiveColors.primaryBackground instead')
  static const Color black = primaryBackground;
  
  @Deprecated('Use HiveColors.textPrimary instead')
  static const Color white = textPrimary;
  
  @Deprecated('Use HiveColors.accent instead')
  static const Color gold = accent;
  
  @Deprecated('Use HiveColors.accent instead')
  static const Color yellow = accent;
  
  @Deprecated('Use HiveColors.primaryBackground instead')
  static const Color dark = primaryBackground;
  
  @Deprecated('Use HiveColors.surfaceStart instead')
  static const Color dark2 = surfaceStart;
  
  @Deprecated('Use HiveColors.surfaceEnd instead')
  static const Color dark3 = surfaceEnd;
  
  // ========================
  // UNIVERSITY SPECIFIC
  // ========================
  
  /// University at Buffalo Blue - for institutional elements only
  static const Color ubBlue = Color(0xFF005BBB);
  
  // ========================
  // UTILITY COLORS
  // ========================
  
  /// Transparent color
  static const Color transparent = Colors.transparent;
  
  /// Pure black - only for text on light backgrounds (rare usage)
  static const Color pureBlack = Color(0xFF000000);
  
  /// Pure white - alias for textPrimary
  static const Color pureWhite = textPrimary;
}

/// Extended color methods for generating variations
extension HiveColorExtensions on Color {
  /// Creates a lighter version of the color
  Color lighter(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Creates a darker version of the color
  Color darker(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
} 