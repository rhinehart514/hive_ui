import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Layout constants for onboarding process
/// These values help maintain consistency across all onboarding screens
/// following the HIVE Brand Aesthetic & UI/UX Architecture Guide
class OnboardingLayout {
  // Base spacing unit according to HIVE brand guide (section 5.1 and 5.2)
  static const double baseUnit = 8.0;
  
  // Spacing tokens as defined in section 5.1
  static const double spacingXXS = 4.0;
  static const double spacingXS = baseUnit; // 8px
  static const double spacingSM = 12.0;
  static const double spacingMD = baseUnit * 2; // 16px
  static const double spacingLG = baseUnit * 3; // 24px
  static const double spacingXL = baseUnit * 4; // 32px
  
  // Corner radius (conforming to Apple-like UI aesthetics)
  static const double buttonRadius = 28.0; // More pill-shaped for buttons like sign-in page
  static const double inputRadius = 12.0; // Match sign-in page's text field radius
  static const double cardRadius = 12.0; // Slightly larger radius to match text fields
  static const double itemRadius = 12.0; // For selection items
  
  // Paddings (using multiples of base unit)
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0); // Match sign-in/create account pages
  static const EdgeInsets contentPadding = EdgeInsets.all(spacingMD); // 16px
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(
    horizontal: spacingMD, // 16px
    vertical: spacingXS * 1.5, // 12px
  );
  
  // Size constraints (match sign-in/create account pages)
  static const double maxContentWidth = 500;
  static const double buttonHeight = 56.0; // Match sign-in/create account buttons
  static const double minTappableSize = 44;
  
  // Animation durations (from section 7.1)
  static const Duration instantDuration = Duration(milliseconds: 0);
  static const Duration shortDuration = Duration(milliseconds: 180); // Slightly faster
  static const Duration standardDuration = Duration(milliseconds: 280); // Slightly faster
  static const Duration longDuration = Duration(milliseconds: 450); // Slightly faster
  
  // Animation curves (from section 7.2)
  static const Curve standardCurve = Cubic(0.4, 0.0, 0.2, 1.0); // cubic-bezier(0.4, 0, 0.2, 1)
  static const Curve exitCurve = Cubic(0.4, 0.0, 1.0, 1.0); // cubic-bezier(0.4, 0, 1, 1)
  static const Curve entryCurve = Cubic(0.0, 0.0, 0.2, 1.0); // cubic-bezier(0.0, 0, 0.2, 1)
  static const Curve linearCurve = Curves.linear;
  
  // Typography styles (matching sign-in/create account pages)
  static TextStyle get h1Style => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: Colors.white,
    letterSpacing: 1.5,
  );
  
  static TextStyle get h2Style => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Colors.white,
    letterSpacing: -0.3,
  );
  
  static TextStyle get h3Style => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: Colors.white,
    letterSpacing: -0.2,
  );
  
  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: Colors.white,
  );
  
  static TextStyle get smallStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Colors.white,
  );
  
  // Derived specific styles for onboarding components (matching sign-in/create account pages)
  static TextStyle get titleStyle => h1Style;
  
  static TextStyle get subtitleStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Colors.white70, // Match create account page
  );
  
  static TextStyle get inputLabelStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.7), // Match sign-in page label style
  );
  
  static TextStyle get inputTextStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white, // Match sign-in page input text
  );
  
  static TextStyle get buttonTextStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.0,
    color: Colors.black, // For contrast on white button
  );
  
  static TextStyle get optionLabelStyle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600, // Slightly bolder to match sign-in components
    color: Colors.white,
  );
  
  // Colors from section 3.1 (updated to match sign-in/create account style)
  static const Color primarySurface = Colors.black; // Pure black background like sign-in
  static const Color secondarySurface = Color(0xFF1E1E1E); // Match sign-in text field background
  static const Color deepLayer = Colors.black; // Pure Black
  static const Color textPrimary = Colors.white; // For primary text content
  static const Color textSecondary = Colors.white70; // Match create account subtitle
  static const Color textTertiary = Colors.white54; // For tertiary information
  static const Color textDisabled = Colors.white38; // For disabled elements
  
  // Selection indicators matching sign-in/create account gold accent theme
  static const Color activeIndicator = AppColors.gold; // Gold for active/focused elements
  static final Color activeIndicatorDim = AppColors.goldDark.withOpacity(0.6); // Dimmed gold for secondary elements
  static final Color inactiveElement = Colors.white.withOpacity(0.15); // Very subtle for inactive elements

  // Glass effect colors
  static final Color glassSurface = Colors.black.withOpacity(0.65); // More transparent for glass effect
  static final Color glassHighlight = Colors.white.withOpacity(0.07); // Subtle highlight for glass edges
  
  // Decoration for default input fields (matching sign-in page)
  static InputDecoration getInputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: inputLabelStyle,
      fillColor: secondarySurface,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingMD),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
  
  // Updated decorations for selection items with Apple-like styling
  static BoxDecoration get unselectedItemDecoration => BoxDecoration(
    color: secondarySurface,
    borderRadius: BorderRadius.circular(itemRadius),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
  );
  
  static BoxDecoration get selectedItemDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(itemRadius),
  );
  
  // Clean, minimal button styles matching sign-in/create account
  static ButtonStyle primaryButtonStyle({required bool isEnabled}) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled) || !isEnabled) {
          return Colors.white38; // Match sign-in page disabled style
        }
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withOpacity(0.9);
        }
        return Colors.white;
      }),
      foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled) || !isEnabled) {
          return Colors.black.withOpacity(0.5);
        }
        return Colors.black;
      }),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      elevation: MaterialStateProperty.all(0), // Flat design like sign-in
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.1)),
      padding: MaterialStateProperty.all(
        EdgeInsets.zero, // Let the SizedBox control the size
      ),
      minimumSize: MaterialStateProperty.all(const Size(double.infinity, buttonHeight)),
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.black.withOpacity(0.05);
        }
        if (states.contains(MaterialState.hovered)) {
          return Colors.black.withOpacity(0.02);
        }
        return Colors.transparent;
      }),
    );
  }
  
  static ButtonStyle secondaryButtonStyle({required bool isEnabled}) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
      foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled) || !isEnabled) {
          return textDisabled;
        }
        return textPrimary;
      }),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          side: BorderSide(
            color: isEnabled ? Colors.white.withOpacity(0.24) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      elevation: MaterialStateProperty.all(0),
      padding: MaterialStateProperty.all(
        EdgeInsets.zero, // Let the SizedBox control the size
      ),
      minimumSize: MaterialStateProperty.all(const Size(double.infinity, buttonHeight)),
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withOpacity(0.1);
        }
        if (states.contains(MaterialState.hovered)) {
          return Colors.white.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
    );
  }
} 