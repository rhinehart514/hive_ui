import 'package:flutter/material.dart';

/// Defines standard spacing, radii, and other layout constants for HIVE UI.
class AppLayout {
  // --- Spacing --- Based on 8pt grid, with variations
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingSemixlg = 16.0; // Standard padding often
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // --- Padding --- 
  /// Standard page horizontal padding (16pt min, 24pt max - use 24pt default)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSemixlg);
  static const EdgeInsets mobilePagePadding = EdgeInsets.symmetric(horizontal: spacingSemixlg, vertical: spacingMedium); // Tighter for mobile
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingSemixlg); // Standard 16pt card padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium); // For primary/secondary buttons

  // --- Radii --- 
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0; // Standard card radius
  static const double radiusXXLarge = 24.0; // Standard button radius (height 36pt)
  static const double radiusFull = 999.0; // For circular elements

  // --- Borders --- 
  static const double borderWidthThin = 1.0;
  static const double borderWidthStandard = 1.5;
  static const double borderWidthThick = 2.0;

  // --- Component Dimensions --- 
  static const double buttonHeight = 36.0;
  static const double chipHeight = 32.0;
  static const double touchTarget = 44.0; // Minimum touch target size

  // --- Others --- 
  static const double defaultElevation = 2.0;
  static const double highElevation = 6.0;

  // Prevent instantiation
  AppLayout._();
} 