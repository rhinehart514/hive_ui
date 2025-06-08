import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application text styles
class TextStyles {
  /// Large heading style
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  /// Medium heading style
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
    letterSpacing: -0.25,
    height: 1.3,
  );
  
  /// Small heading style
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
    height: 1.4,
  );
  
  /// Large title style
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTextColor,
    height: 1.4,
  );
  
  /// Medium title style
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTextColor,
    height: 1.4,
  );
  
  /// Small title style
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTextColor,
    height: 1.4,
  );
  
  /// Large body text style
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryTextColor,
    height: 1.5,
  );
  
  /// Medium body text style
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryTextColor,
    height: 1.5,
  );
  
  /// Small body text style
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryTextColor,
    height: 1.5,
  );
  
  /// Caption text style
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryTextColor,
    height: 1.4,
  );
  
  /// Button text style
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.backgroundColor,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  /// Label text style
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryTextColor,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  /// Error text style
  static const TextStyle error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.errorColor,
    height: 1.4,
  );
} 