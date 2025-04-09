import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

class AppTheme {
  // Spacing - 8pt system with 4pt subdivisions
  static const double spacing0 = 0;
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing52 = 52;
  static const double spacing56 = 56;
  static const double spacing64 = 64;

  // Border Radius
  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 28;
  static const double radiusFull = 999;

  // Text Styles - Modern sans-serif with breathing space
  static TextStyle get displayLarge => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0, // Tighter tracking for headings
        height: 1.2, // Tighter leading for headers
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0,
        height: 1.2,
      );

  static TextStyle get displaySmall => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0,
        height: 1.2,
      );

  static TextStyle get headlineSmall => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.3,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.3,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400, // Lighter weight for body
        height: 1.5, // More breathing room for body text
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      // Pure black background
      scaffoldBackgroundColor: Colors.black,
      primaryColor: AppColors.white,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.white,
        secondary: AppColors.gold,
        surface: Colors.black,
        background: Colors.black,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSecondary: AppColors.black,
        onSurface: AppColors.white,
        onBackground: AppColors.white,
      ),
      // Subtle dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5, // Thinner dividers
        space: spacing24,
      ),
      // Refined cards with minimal borders
      cardTheme: CardTheme(
        color: Colors.black, // Pure black cards
        elevation: 0, // No shadow elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(
              color: AppColors.cardBorder, width: 0.5), // Thinner borders
        ),
        margin: const EdgeInsets.all(spacing8),
      ),
      // Modals and sheets - pure black with subtle rounding
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.black,
        modalBackgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      // Input styling - minimal with focused accents
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(color: AppColors.inputBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(color: AppColors.inputBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.gold, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        errorStyle: GoogleFonts.inter(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      // Button themes - clean with moderate rounding
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: AppColors.buttonDisabled,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(radiusLg), // More refined radius
          ),
          minimumSize: const Size(double.infinity, spacing56),
          elevation: 0, // No shadow elevation
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(
              color: AppColors.inputBorder, width: 0.5), // Thinner border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          minimumSize: const Size(double.infinity, spacing56),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Snackbars - floating with subtle corners
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey600,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      // Dialog styling - pure black with content spacing
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
        titleTextStyle: displaySmall,
        contentTextStyle: bodyMedium,
      ),
      // Chip styling - minimal with breathing space
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedColor: AppColors.white,
        disabledColor: AppColors.buttonDisabled,
        labelStyle: labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      // Tab bar - clean with indicator
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.gold, // Reserved gold for indicators
        indicatorSize: TabBarIndicatorSize.label,
      ),
      // App bar - pure black with no elevation
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
        titleTextStyle: titleMedium,
        iconTheme: const IconThemeData(color: AppColors.white),
        actionsIconTheme: const IconThemeData(color: AppColors.white),
      ),
      // Icons - white with subtle opacity variations
      iconTheme: const IconThemeData(
        color: AppColors.white,
        size: 24.0,
      ),
      // List tiles - clean with subtle spacing
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: spacing16),
        iconColor: AppColors.white,
        textColor: AppColors.textPrimary,
      ),
      // Toggles - with gold accent
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.white; // White thumb when active
          }
          return AppColors.grey600; // Dark thumb when inactive
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.gold.withOpacity(0.5); // Gold track when active
          }
          return AppColors.grey700; // Dark track when inactive
        }),
      ),
      // Sliders - with gold accent
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold.withOpacity(0.5),
        inactiveTrackColor: AppColors.grey700,
        thumbColor: AppColors.white,
        trackHeight: 2, // Thinner track
      ),
      // Progress indicators - with gold accent
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.grey700,
        circularTrackColor: AppColors.grey700,
      ),
      // Tooltip - subtle dark with content padding
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.grey600,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        textStyle: bodySmall,
      ),
    );
  }

  // Light theme implementation
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      // Light background with dark text
      scaffoldBackgroundColor: AppColors.white,
      primaryColor: AppColors.black,
      colorScheme: const ColorScheme.light(
        primary: AppColors.black,
        secondary: AppColors.gold,
        surface: AppColors.white,
        background: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.black,
        onSurface: AppColors.black,
        onBackground: AppColors.black,
      ),
      // Subtle dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: spacing24,
      ),
      // Refined cards with minimal borders
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
        margin: const EdgeInsets.all(spacing8),
      ),
      // Input styling - minimal with focused accents
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: GoogleFonts.inter(
          color: AppColors.black,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.grey600, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.grey600, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.gold, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          minimumSize: const Size(double.infinity, spacing56),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
