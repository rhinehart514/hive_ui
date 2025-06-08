import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/hive_colors.dart';
// Remove direct imports of old theme files if they become redundant
// import '../theme/app_colors.dart'; 
// import '../theme/app_typography.dart';

/// Design Tokens: Central source of truth for HIVE's visual language.
/// Based on refined specs emphasizing hierarchy, accessibility, and brand narrative.
class DesignTokens {
  static final DesignTokens _instance = DesignTokens._internal();
  factory DesignTokens() => _instance;
  DesignTokens._internal();

  final ColorTokens colors = ColorTokens();
  final TypographyTokens typography = TypographyTokens();
  final SpacingTokens spacing = SpacingTokens();
  final RadiusTokens radius = RadiusTokens();
  final AnimationTokens animation = AnimationTokens();
  final ShadowTokens shadows = ShadowTokens();
  final OpacityTokens opacity = OpacityTokens(); // Keep opacity for specific cases
}

/// Extension for easy access: `context.tokens.colors.bg900`
extension DesignTokensExtension on BuildContext {
  DesignTokens get tokens => DesignTokens();
}

// ====================================
//      COLOR TOKENS (NEW SYSTEM)
// ====================================
class ColorTokens {
  // --- Backgrounds --- (Using HiveColors for brand compliance)
  /// App root, splash screens - Brand compliant #0D0D0D
  final Color bg900 = HiveColors.primaryBackground;
  /// Primary surfaces - Slightly lighter than primary
  final Color bg800 = const Color(0xFF0A0A0A);
  /// Secondary surfaces / cards - Brand compliant surface start
  final Color bg700 = HiveColors.surfaceStart;
  /// Input fields and buttons background - Slightly darker surface
  final Color bgButtonDark = const Color(0xFF111111);

  // --- Lines / Dividers ---
  /// Dividers, strokes, disabled elements - Brand compliant
  final Color line500 = HiveColors.divider;

  // --- Text --- (Using HiveColors for brand compliance)
  /// Headlines, vital data - Brand compliant white
  final Color textPrimary = HiveColors.textPrimary;
  /// Body copy, metadata - Brand compliant secondary
  final Color textSecondary = HiveColors.textSecondary;
  /// Placeholder text - Brand compliant disabled
  final Color textPlaceholder = HiveColors.textDisabled;
  /// Text color for use on Gold backgrounds - Brand compliant
  final Color textOnAccent = HiveColors.textOnAccent;

  // --- Brand Accent --- (Using HiveColors for brand compliance)
  /// Active states, CTA fills - Brand compliant gold
  final Color brandGold100 = HiveColors.accent;
  /// Hover state - Brand compliant hover gold
  final Color brandGold90 = HiveColors.goldHover;
  /// Focus rings, pressed states - Brand compliant with opacity
  final Color brandGold40 = HiveColors.gold40;

  // --- Semantic States --- (Using HiveColors for brand compliance)
  /// Confirmation, check-ins - Brand compliant success
  final Color stateSuccess = HiveColors.success;
  /// HIVE announcements, new-feature nudges - Brand compliant info
  final Color stateInfo = HiveColors.info;
  /// Errors, destructive actions - Brand compliant error
  final Color stateError = HiveColors.error;
  /// Warnings - Brand compliant warning
  final Color stateWarning = HiveColors.warning;

  // --- Gradients --- (Using HiveColors for brand compliance)
  /// Standard surface gradient - Brand compliant surface gradient
  LinearGradient get surfaceGradient => LinearGradient(
        colors: [bg700, bg800],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

// ====================================
//     TYPOGRAPHY TOKENS (MODERNIZED)
// ====================================
// Note: Full typography system is now in typography_tokens.dart
// This class provides convenient access to the new 2025-ready typography
class TypographyTokens {
  // Import the modern typography system
  static const String inter = 'Inter'; // Primary fallback
  static const String interTight = 'Inter Tight'; // Display font
  static const String jetBrainsMono = 'JetBrains Mono'; // Code font
  static const String spaceGrotesk = 'Space Grotesk'; // Editorial accent

  // Alias to modern typography system - these map to the 2025-ready stack
  final TextStyle headlineLg = const TextStyle(
    fontFamily: interTight,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    height: 40 / 32, // line-height / font-size
    letterSpacing: -0.32, // -1% tracking
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  final TextStyle headlineMd = const TextStyle(
    fontFamily: interTight,
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semibold
    height: 32 / 24,
    letterSpacing: -0.12, // -0.5% tracking
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  final TextStyle headlineSm = const TextStyle(
    fontFamily: interTight,
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    height: 28 / 20,
    letterSpacing: 0.0,
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  final TextStyle bodyLg = const TextStyle(
    fontFamily: inter,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 24 / 16,
    letterSpacing: 0.04, // +0.25% for dark mode
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  final TextStyle bodyMd = const TextStyle(
    fontFamily: inter,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 20 / 14,
    letterSpacing: 0.07, // +0.5% for smaller text
    color: Color(0xFFE5E5E5), // textSecondary
  );
  
  final TextStyle bodySm = const TextStyle(
    fontFamily: inter,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 20 / 14,
    letterSpacing: 0.14, // +1% for tight spaces
    color: Color(0xFFCCCCCC), // textTertiary
  );
  
  final TextStyle labelLg = const TextStyle(
    fontFamily: inter,
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semibold for buttons
    height: 24 / 16,
    letterSpacing: 0.04,
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  final TextStyle labelMd = const TextStyle(
    fontFamily: inter,
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 20 / 14,
    letterSpacing: 0.07,
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  final TextStyle labelSm = const TextStyle(
    fontFamily: inter,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 20 / 14,
    letterSpacing: 0.14,
    color: Color(0xFFCCCCCC), // textTertiary
  );
  
  // Code/Mono styles for tool composition
  final TextStyle mono = const TextStyle(
    fontFamily: jetBrainsMono,
    fontSize: 13,
    fontWeight: FontWeight.w400, // Regular
    height: 20 / 13,
    letterSpacing: 0.0,
    color: Color(0xFFFFFFFF), // textPrimary
  );
  
  // Editorial accent for ritual countdowns
  final TextStyle ritualCountdown = const TextStyle(
    fontFamily: spaceGrotesk,
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    height: 28 / 20,
    letterSpacing: 0.0,
    color: Color(0xFFFFD700), // brandGold100
  );
}

// ====================================
//      SPACING TOKENS (NEW SYSTEM)
// ====================================
class SpacingTokens {
  final double space1 = 4.0;
  final double space2 = 8.0;
  final double space3 = 12.0;
  final double space4 = 16.0; // Common default
  final double space5 = 20.0;
  final double space6 = 24.0; // Button Horizontal Padding
  final double spaceButtonVertical = 14.0; // Specific button vertical padding
  final double space7 = 32.0;
  final double space8 = 48.0;

  /// Standard content padding = 16pt
  double get contentPadding => space4;
  /// Minimum side padding = 16pt
  double get minSidePadding => space4;
  /// Maximum side padding = 24pt
  double get maxSidePadding => space6;
}

// ====================================
//      RADIUS TOKENS (NEW SYSTEM)
// ====================================
class RadiusTokens {
  final double radiusSm = 4.0;
  final double radiusMd = 8.0;
  final double radiusLg = 16.0;
  final double radiusXl = 24.0; // Old button radius
  final double radiusButton = 24.0; // Updated to match login UI (was 28)
  final double radiusCard = 20.0; // Specific for cards
  final double radiusInput = 24.0; // Updated to match login UI (was 12)
  final double radiusCircular = 1000.0; // Effective circle
}

// =====================================
//    ANIMATION TOKENS (NEW SYSTEM)
// =====================================
class AnimationTokens {
  // --- Durations ---
  final Duration durationPress = const Duration(milliseconds: 80); // Specific button press
  final Duration durationFast = const Duration(milliseconds: 150);
  final Duration durationMedium = const Duration(milliseconds: 250);
  final Duration durationSlow = const Duration(milliseconds: 400);
  final Duration durationPage = const Duration(milliseconds: 320); // Keep specific page transition

  // --- Easing Curves ---
  /// Standard Material curve
  final Curve standard = Curves.easeInOut; // Default fallback
  final Curve materialStandard = const Cubic(0.4, 0.0, 0.2, 1.0);
  final Curve decelerate = Curves.easeOut;
  final Curve accelerate = Curves.easeIn;
  final Curve linear = Curves.linear;

  // --- Physics ---
  /// Default spring description
  final SpringDescription standardSpring = const SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 15.0,
  );
}

// ====================================
//      SHADOW TOKENS (NEW SYSTEM)
// ====================================
class ShadowTokens {
  // Define ALL shadows using standard Flutter BoxShadow

  // Standard Elevation Shadows
  final List<BoxShadow> elevation1 = [
    const BoxShadow(
      color: Color(0x33000000), 
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  final List<BoxShadow> elevation2 = [
     const BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
  final List<BoxShadow> elevation3 = [
     const BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -1, 
    ),
  ];
  final List<BoxShadow> elevation4 = [
     const BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  // Refined for a more subtle, modern neumorphic raised effect.
  final List<BoxShadow> neumorphicDarkElevated = [
    // Top-Left Highlight (Opacity Increased for better visibility)
    const BoxShadow(
      color: Color(0x1AFFFFFF), // Colors.white.withOpacity(0.10) - Up from 0.05
      offset: Offset(-2, -2),
      blurRadius: 4,
      spreadRadius: 0, 
    ),
    // Bottom-Right Shadow (Opacity Increased for better visibility and blending)
    const BoxShadow(
      color: Color(0x66000000), // Colors.black.withOpacity(0.40) - Up from 0.25
      offset: Offset(3, 3),
      blurRadius: 6, // Kept blur for softness
      spreadRadius: 0, 
    ),
  ];
  
  // Refined simulation for "carved out" or "embossed" elements for a crisper, sharper falloff and better visibility.
  // Still a SIMULATION using outer shadows. For TRUE inset, use specInsetEmbossed with a package.
  final List<BoxShadow> neumorphicEmbossed = [
    // Darker shadow on TOP-LEFT inner edge (Opacity Increased)
    const BoxShadow(
      color: Color(0x73000000), // Colors.black.withOpacity(0.45) - Up from 0.3
      offset: Offset(-1.5, -1.5), 
      blurRadius: 1.5, // Kept reduced blur for sharper falloff
      spreadRadius: 0,
    ),
    // Lighter highlight on BOTTOM-RIGHT inner edge (Opacity Increased)
    const BoxShadow(
      color: Color(0x33FFFFFF), // Colors.white.withOpacity(0.20) - Up from 0.15
      offset: Offset(1.5, 1.5), 
      blurRadius: 1.5, // Kept reduced blur for sharper falloff
      spreadRadius: 0,
    ),
  ];

  // New: Specification for true INSET shadows based on user's CSS example.
  // Requires a package like 'flutter_inset_box_shadow' for actual implementation at the widget level.
  final List<BoxShadow> specInsetEmbossed = [
    // These are standard BoxShadows here for structure, comments define the INSET intent.
    // Intended Inset Shadow 1 (Dark): BoxShadow(color: Color(0x99000000), offset: Offset(2, 2), blurRadius: 4, inset: true)
    const BoxShadow(
      color: Color(0x99000000), // rgba(0, 0, 0, 0.6)
      offset: Offset(2, 2),     // as per CSS inset
      blurRadius: 4,            // as per CSS inset
      // spreadRadius: 0, // Standard BoxShadow, no 'inset' property here
    ),
    // Intended Inset Shadow 2 (Light): BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(-2, -2), blurRadius: 4, inset: true)
    const BoxShadow(
      color: Color(0x0DFFFFFF), // rgba(255, 255, 255, 0.05)
      offset: Offset(-2, -2),   // as per CSS inset
      blurRadius: 4,            // as per CSS inset
      // spreadRadius: 0, // Standard BoxShadow, no 'inset' property here
    ),
  ];
}

// ====================================
//      OPACITY TOKENS (RETAINED)
// ====================================
class OpacityTokens {
  double get low => 0.08;
  double get mediumLow => 0.12;
  double get medium => 0.50;
  double get high => 0.80;
  double get full => 1.0;

  /// For overlays like hover/pressed on Gold (#FFD70066)
  double get brandGoldOverlay => 0.40;

  /// For disabled states using line color (#2B2B2B)
  double get disabledContent => 0.5; // Example: 50% opacity on line500

  // Specific use cases from brand guide
  double get glassTint => 0.80;
  double get goldGlowStreak => 0.10;
  double get microGrain => 0.03; // Example: 3% for micro grain
} 