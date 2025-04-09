import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilities for platform-specific adaptations and device information
class PlatformUtils {
  /// Returns true if the app is running on iOS
  static bool get isIOS => Platform.isIOS;
  
  /// Returns true if the app is running on Android
  static bool get isAndroid => Platform.isAndroid;
  
  /// Returns the appropriate scroll physics based on platform
  static ScrollPhysics getScrollPhysics() {
    return isIOS 
        ? const BouncingScrollPhysics() 
        : const ClampingScrollPhysics();
  }
  
  /// Returns appropriate haptic feedback for interactions
  static void triggerHaptic(HapticType type) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
  
  /// Sets the status bar style to match HIVE's dark theme
  static void setStatusBarStyle({bool darkMode = true}) {
    SystemChrome.setSystemUIOverlayStyle(
      darkMode 
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: const Color(0xFF0A0A0A),
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }
  
  /// Returns screen dimensions accounting for safe areas
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Checks if the device has a notch
  static bool hasNotch(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;
    // If top padding is significantly larger than basic status bar
    return padding.top > 24;
  }
  
  /// Determines if the device is a tablet based on shortest side
  static bool isTablet(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return size.shortestSide > 600;
  }
  
  /// Returns appropriate screen padding based on device type
  static EdgeInsets getScreenPadding(BuildContext context) {
    final bool tablet = isTablet(context);
    return EdgeInsets.symmetric(
      horizontal: tablet ? 24.0 : 16.0,
      vertical: 16.0,
    );
  }
  
  /// Returns appropriate bottom inset accounting for navigation bar + safe area
  static double getBottomInset(BuildContext context) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    // Add extra padding for navigation bar if needed
    const navBarHeight = 56.0; // Standard bottom nav height
    return bottomSafeArea + navBarHeight;
  }
}

/// Types of haptic feedback used in the app
enum HapticType {
  light,
  medium,
  heavy,
  selection,
} 