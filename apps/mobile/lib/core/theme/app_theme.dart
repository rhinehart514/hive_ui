import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Need this for fontFamily
import '../design/design_tokens.dart';
// import 'package:google_fonts/google_fonts.dart'; // No longer needed directly here

/// Main theme definition for HIVE UI using the new Design Token system
/// Combines all design tokens into a ThemeData object
/// Aligned with brand_aesthetic.md
class AppTheme {
  
  /// Standard padding value (brand_aesthetic.md Section 10.1)
  static const double defaultPadding = 16.0;
  
  /// Creates the dark theme (primary theme for HIVE)
  static ThemeData darkTheme() {
    // Initialize design tokens (new system)
    final tokens = DesignTokens();
    
    // Define base text theme using the modernized 2025-ready typography system
    // Maps the new Inter Tight + Inter + JetBrains Mono stack to Flutter's TextTheme
    final typographySystem = TypographyTokens();
    
    final textTheme = TextTheme(
      // Display styles - Inter Tight for bold headlines  
      displayLarge: typographySystem.headlineLg,    // 32pt Inter Tight Bold
      displayMedium: typographySystem.headlineMd,   // 24pt Inter Tight Semibold
      displaySmall: typographySystem.headlineSm,    // 20pt Inter Tight Semibold
      
      // Headline styles (aliased to display for consistency)
      headlineLarge: typographySystem.headlineLg,   // 32pt Inter Tight Bold
      headlineMedium: typographySystem.headlineMd,  // 24pt Inter Tight Semibold
      headlineSmall: typographySystem.headlineSm,   // 20pt Inter Tight Semibold
      
      // Title styles - Mix of display and body fonts for hierarchy
      titleLarge: typographySystem.headlineSm,      // 20pt Inter Tight Semibold
      titleMedium: typographySystem.labelLg,        // 16pt Inter Semibold
      titleSmall: typographySystem.labelMd,         // 14pt Inter Medium
      
      // Body styles - Inter for comfortable reading with proper tracking
      bodyLarge: typographySystem.bodyLg,           // 16pt Inter Regular (+0.25% tracking)
      bodyMedium: typographySystem.bodyMd,          // 14pt Inter Regular (+0.5% tracking)
      bodySmall: typographySystem.bodySm,           // 14pt Inter Regular (+1% tracking)
      
      // Label styles - For interactive elements and UI labels
      labelLarge: typographySystem.labelLg,         // 16pt Inter Semibold
      labelMedium: typographySystem.labelMd,        // 14pt Inter Medium  
      labelSmall: typographySystem.labelSm,         // 14pt Inter Regular
    ).apply( // Apply default colors from design tokens
      bodyColor: tokens.colors.textPrimary, 
      displayColor: tokens.colors.textPrimary,
      decorationColor: tokens.colors.textPrimary,
    );
    
    return ThemeData(
      // Base theme properties
      brightness: Brightness.dark,
      primaryColor: tokens.colors.brandGold100, // New primary color
      scaffoldBackgroundColor: tokens.colors.bg800, // New primary surface background
      canvasColor: tokens.colors.bg900, // New root background
      fontFamily: TypographyTokens.inter, // Use Inter as base font family
      
      // Color scheme using new ColorTokens
      colorScheme: ColorScheme.dark(
        primary: tokens.colors.brandGold100,
        secondary: tokens.colors.brandGold100, // Often same as primary in dark themes
        surface: tokens.colors.bg700, // Secondary surface
        background: tokens.colors.bg800, // Primary surface
        error: tokens.colors.stateError,
        onPrimary: tokens.colors.textOnAccent, // Black text on Gold
        onSecondary: tokens.colors.textOnAccent, // Black text on Gold
        onSurface: tokens.colors.textPrimary, // White text on dark surfaces
        onBackground: tokens.colors.textPrimary, // White text on dark backgrounds
        onError: tokens.colors.textPrimary, // White text on Error color surfaces
      ),
      
      // Text theme 
      textTheme: textTheme,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.colors.bg800, // Match primary surface
        elevation: tokens.shadows.elevation1[0].blurRadius > 0 ? tokens.shadows.elevation1[0].blurRadius : 0, // Use shadow token elevation if needed
        titleTextStyle: tokens.typography.labelLg, // Use labelLarge for titles
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark, // For iOS
        ),
        iconTheme: IconThemeData(color: tokens.colors.textPrimary),
        actionsIconTheme: IconThemeData(color: tokens.colors.textPrimary),
      ),
      
      // Card theme (brand_aesthetic.md Section 9.2)
      cardTheme: CardThemeData(
        color: tokens.colors.bg700, // Use secondary surface color for cards
        elevation: 0, // Shadows handled by decoration
        margin: EdgeInsets.symmetric(vertical: tokens.spacing.space2 / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusCard), 
        ),
      ),
      
      // Button themes (brand_aesthetic.md Section 9.1 - 36pt height, 24pt radius)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.colors.brandGold100, // Revert to simple gold color
          foregroundColor: tokens.colors.textOnAccent, // Black text on gold
          minimumSize: const Size(64, 36), 
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space6), // Restore padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius.radiusXl), // Use XL radius (24pt)
          ),
          textStyle: tokens.typography.labelLg, // Use standard label style
          elevation: 0, // No material elevation
        ).copyWith(
          // Define overlay using brandGold40
          overlayColor: MaterialStateProperty.all(tokens.colors.brandGold40),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.colors.textPrimary,
          minimumSize: const Size(64, 36),
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space6 - 1), // Adjust for border
          side: BorderSide(color: tokens.colors.line500, width: 1.0), // Use line color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius.radiusXl), // Use XL radius
          ),
          textStyle: tokens.typography.labelLg,
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) {
              return tokens.colors.textPrimary.withOpacity(0.1); 
            }
             if (states.contains(MaterialState.hovered)) {
               return tokens.colors.textPrimary.withOpacity(0.05);
            }
            return null;
          }),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.colors.brandGold100, // Gold color for text actions
          minimumSize: const Size(0, 36),
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius.radiusXl),
          ),
          // Use labelLg but override color
          textStyle: tokens.typography.labelLg.copyWith(color: tokens.colors.brandGold100),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            // Use brandGold40 for hover/pressed overlays
            if (states.contains(MaterialState.pressed) || states.contains(MaterialState.hovered)) {
              return tokens.colors.brandGold40;
            }
            return null;
          }),
        ),
      ),
      
      // Input decoration theme (brand_aesthetic.md Section 3.2 - 12pt radius)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.colors.bg700.withOpacity(0.5), // Secondary surface, slightly transparent
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.spacing.space4, vertical: 14), // 16pt horizontal
        hintStyle: tokens.typography.bodyLg.copyWith(color: tokens.colors.textSecondary),
        labelStyle: tokens.typography.bodyLg.copyWith(color: tokens.colors.textSecondary),
        floatingLabelStyle: tokens.typography.bodySm.copyWith(color: tokens.colors.textSecondary),
        errorStyle: tokens.typography.bodySm.copyWith(color: tokens.colors.stateError),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusInput), // 12pt radius
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusInput),
          borderSide: BorderSide(color: tokens.colors.line500, width: 1), // Use line color for border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusInput),
          borderSide: BorderSide(color: tokens.colors.brandGold100, width: 1.5), // Gold focus border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusInput),
          borderSide: BorderSide(color: tokens.colors.stateError, width: 1), // Error border
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusInput),
          borderSide: BorderSide(color: tokens.colors.stateError, width: 1.5), // Focused error border
        ),
        disabledBorder: OutlineInputBorder( // Added disabled state
           borderRadius: BorderRadius.circular(tokens.radius.radiusInput),
           borderSide: BorderSide(color: tokens.colors.line500.withOpacity(tokens.opacity.disabledContent), width: 1),
        ),
      ),
      
      // Tab bar theme (brand_aesthetic.md Section 9.3)
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: tokens.colors.brandGold100, 
              width: 2.0, 
            ),
          ),
        ),
        labelColor: tokens.colors.textPrimary, 
        unselectedLabelColor: tokens.colors.textSecondary, // Use new secondary text color
        labelStyle: tokens.typography.labelMd, // 14pt Medium
        unselectedLabelStyle: tokens.typography.labelMd, 
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.colors.bg900, // Use root background for contrast
        selectedItemColor: tokens.colors.brandGold100, 
        unselectedItemColor: tokens.colors.textSecondary,
        selectedLabelStyle: tokens.typography.labelSm.copyWith(fontSize: 10), // 10pt from old theme
        unselectedLabelStyle: tokens.typography.labelSm.copyWith(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 0, // No elevation
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Dialog theme (brand_aesthetic.md Section 4.3 - Modals)
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.colors.bg700, // Secondary surface
        elevation: 0, // Handled by decoration/shadows
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusCard), // Use card radius
        ),
        titleTextStyle: tokens.typography.headlineSm, 
        contentTextStyle: tokens.typography.bodyLg,
      ),

      // Tooltip Theme (brand_aesthetic.md Section 4.3)
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.colors.bg900.withOpacity(0.95), // Use root background
          borderRadius: BorderRadius.circular(tokens.radius.radiusSm), // Use small radius
        ),
        textStyle: tokens.typography.bodySm.copyWith(color: tokens.colors.textPrimary),
        preferBelow: true,
        verticalOffset: 18,
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space3, vertical: tokens.spacing.space2),
        waitDuration: tokens.animation.durationMedium,
        showDuration: const Duration(seconds: 3),
      ),

      // Define transition animations (brand_aesthetic.md Section 6.1)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Use CupertinoPageTransitionsBuilder for iOS-like transitions
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(), // Use iOS style on Android too for consistency
          // Add others if needed, e.g., FadeUpwardsPageTransitionsBuilder
        },
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: tokens.colors.line500, // Use line color token
        space: 1, 
        thickness: 1, // Standard thickness
      ),

      // Chip Theme (Matches button spec)
      chipTheme: ChipThemeData(
        backgroundColor: tokens.colors.bg700, // Secondary surface
        disabledColor: tokens.colors.bg700.withOpacity(tokens.opacity.disabledContent),
        selectedColor: tokens.colors.brandGold100,
        secondarySelectedColor: tokens.colors.brandGold100, // Usually same as selectedColor
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.space3, vertical: tokens.spacing.space2),
        labelStyle: tokens.typography.labelMd.copyWith(color: tokens.colors.textSecondary), // 14pt Medium Secondary
        secondaryLabelStyle: tokens.typography.labelMd.copyWith(color: tokens.colors.textOnAccent), // Black text on Gold
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.radiusXl), // Button radius
          // Use line500 for the default border as specified for lines/strokes
          side: BorderSide(color: tokens.colors.line500, width: 1), 
        ),
        // selectedBorderColor: tokens.colors.brandGold100, // This property doesn't exist
      ),

      // Add other theme definitions as needed (Slider, Switch, etc.)
    );
  }
  
  /// Applies global system UI overlay style
  static void applySystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        // Use bg900 for nav bar color to match bottom nav
        systemNavigationBarColor: ColorTokens().bg900, 
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
} 