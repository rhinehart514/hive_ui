import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Provides consistent styling for the onboarding UI components.
///
/// This class follows the Apple-influenced design approach with HIVE's dark
/// aesthetic and gold accents (#FFD700). It standardizes all styling for
/// the onboarding flow to ensure consistency across pages.
class OnboardingStyles {
  // Private constructor to prevent instantiation
  OnboardingStyles._();
  
  /// Spacing constants
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  
  /// Border radius constants
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusPill = 18.0;
  
  /// Component sizing
  static const double buttonHeight = 36.0;
  static const double inputHeight = 56.0;
  static const double selectionCardHeight = 72.0;
  static const double touchTargetMinimum = 44.0;
  
  /// Text styles
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static TextStyle get inputLabelStyle => const TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 1.3,
  );
  
  static TextStyle get inputTextStyle => const TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.normal,
    color: AppColors.white,
    height: 1.5,
  );
  
  static TextStyle get buttonTextStyle => const TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 1.5,
    letterSpacing: -0.2,
  );
  
  static TextStyle get secondaryButtonTextStyle => const TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.5,
    letterSpacing: -0.2,
  );
  
  static TextStyle get helperTextStyle => const TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static TextStyle get errorTextStyle => const TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.4,
  );
  
  /// Button styles
  static ButtonStyle primaryButtonStyle({bool isEnabled = true}) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppColors.white.withOpacity(0.5);
        }
        if (states.contains(MaterialState.pressed)) {
          return AppColors.grey200;
        }
        return AppColors.white;
      }),
      foregroundColor: MaterialStateProperty.all<Color>(AppColors.black),
      overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: BorderSide(
            color: isEnabled ? AppColors.inputBorder : AppColors.inputBorder.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      elevation: MaterialStateProperty.all<double>(0),
      minimumSize: MaterialStateProperty.all<Size>(
        const Size(double.infinity, buttonHeight),
      ),
      animationDuration: const Duration(milliseconds: 150),
    );
  }
  
  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.white,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: AppColors.inputBorder, width: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      minimumSize: const Size(double.infinity, buttonHeight),
      textStyle: secondaryButtonTextStyle,
      padding: const EdgeInsets.symmetric(horizontal: spacing16),
    ).copyWith(
      overlayColor: MaterialStateProperty.all<Color>(AppColors.white.withOpacity(0.1)),
    );
  }
  
  /// Input field decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    String? errorText,
    Widget? suffixIcon,
    TextStyle? labelStyle,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      suffixIcon: suffixIcon,
      labelStyle: labelStyle ?? inputLabelStyle.copyWith(color: AppColors.textTertiary),
      hintStyle: inputTextStyle.copyWith(color: AppColors.textTertiary),
      errorStyle: errorTextStyle,
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.inputBorder,
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.inputBorder,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.gold,
          width: 1.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 0.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.0,
        ),
      ),
    );
  }
  
  /// Selection card decoration
  static BoxDecoration selectionCardDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: isSelected ? AppColors.gold : AppColors.cardBorder,
        width: isSelected ? 1.5 : 0.5,
      ),
    );
  }
  
  /// Common padding
  static const EdgeInsets pagePadding = EdgeInsets.all(spacing24);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing16);
  
  /// Animation durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration standardDuration = Duration(milliseconds: 350);
  static const Duration longDuration = Duration(milliseconds: 500);
  
  /// Animation curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.fastOutSlowIn;
  static const Curve bounceCurve = Curves.easeOutBack;
  
  /// Haptic feedback helpers
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  static void errorImpact() {
    HapticFeedback.vibrate();
  }
} 