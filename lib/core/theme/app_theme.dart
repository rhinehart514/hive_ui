import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'package:google_fonts/google_fonts.dart';

/// Main theme definition for HIVE UI
/// Combines all design tokens into a ThemeData object
class AppTheme {
  /// Creates the dark theme (primary theme for HIVE)
  static ThemeData darkTheme() {
    return ThemeData(
      // Base theme properties
      brightness: Brightness.dark,
      primaryColor: AppColors.white,
      primarySwatch: AppColors.primarySwatch,
      scaffoldBackgroundColor: AppColors.black,
      canvasColor: AppColors.black,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.white,
        secondary: AppColors.white,
        surface: Colors.black,
        background: Colors.black,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSecondary: AppColors.black,
        onSurface: AppColors.white,
        onBackground: AppColors.white,
      ),
      
      // Text theme using our typography styles
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.titleLarge,
        headlineMedium: AppTypography.titleMedium,
        headlineSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
        titleTextStyle: AppTypography.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: AppColors.darkGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.black),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 48),
          side: BorderSide(color: AppColors.white.withOpacity(0.3), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.labelLarge,
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.white.withOpacity(0.1);
            }
            return null;
          }),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.yellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTypography.interactive,
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.yellow.withOpacity(0.15);
            }
            return null;
          }),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.black.withOpacity(0.3),
        labelStyle: GoogleFonts.inter(
          color: AppColors.white.withOpacity(0.7),
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.white.withOpacity(0.2), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.white.withOpacity(0.2), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.white, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        errorStyle: GoogleFonts.inter(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Tab bar theme
      tabBarTheme: TabBarTheme(
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.gold,
              width: 2.0,
            ),
          ),
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.secondaryText,
        labelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.labelMedium,
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.black,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          side: BorderSide(
            color: AppColors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.white,
        textColor: AppColors.white,
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColors.white.withOpacity(0.1),
        thickness: 0.5,
        space: 1,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.white,
        size: 24,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        disabledColor: AppColors.surfaceSecondary.withOpacity(0.5),
        selectedColor: AppColors.gold,
        secondarySelectedColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: AppTypography.labelSmall,
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.black),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.surfaceSecondary,
        circularTrackColor: AppColors.surfaceSecondary,
      ),
    );
  }
  
  /// Applies global system UI overlay style
  static void applySystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
} 