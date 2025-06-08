import 'package:flutter/material.dart';

/// Utility class for handling screen-specific adaptations
class ScreenUtils {
  /// Breakpoint for small mobile devices (phones)
  static const double smallMobileBreakpoint = 360.0;

  /// Breakpoint for medium mobile devices
  static const double mediumMobileBreakpoint = 480.0;

  /// Breakpoint for large mobile devices and small tablets
  static const double largeMobileBreakpoint = 600.0;

  /// Breakpoint for tablets
  static const double tabletBreakpoint = 768.0;

  /// Whether the device is a small mobile device
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < smallMobileBreakpoint;
  }

  /// Whether the device is a medium-sized mobile device
  static bool isMediumMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallMobileBreakpoint && width < mediumMobileBreakpoint;
  }

  /// Whether the device is a large mobile device
  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mediumMobileBreakpoint && width < largeMobileBreakpoint;
  }

  /// Whether the device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= largeMobileBreakpoint && width < tabletBreakpoint;
  }

  /// Whether the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Whether the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Calculate safe padding for bottom navigation
  static double calculateBottomPadding(BuildContext context) {
    // Adds padding for bottom nav bar and system navigation
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomNavBarHeight = 56.0; // Standard bottom nav bar height
    
    return bottomInset + bottomNavBarHeight;
  }

  /// Get profile image size based on screen dimensions
  static double getProfileImageHeight(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    if (isSmallMobile(context)) {
      return screenSize.height * 0.3; // Smaller percentage for small devices
    } else if (isMediumMobile(context) || isLargeMobile(context)) {
      return screenSize.height * 0.33; // Medium percentage for regular phones
    } else {
      return screenSize.height * 0.38; // Larger percentage for tablets
    }
  }

  /// Get tab height based on screen size for better touch targets
  static double getTabHeight(BuildContext context) {
    if (isSmallMobile(context) || isMediumMobile(context)) {
      return 60.0; // Taller tabs for smaller screens (better touch targets)
    } else {
      return 56.0; // Standard tab height
    }
  }

  /// Get appropriate padding for mobile
  static EdgeInsets getMobilePadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0);
    } else if (isMediumMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
    }
  }

  /// Get font size adjustments for different screen sizes
  static double getAdjustedFontSize(BuildContext context, double baseSize) {
    if (isSmallMobile(context)) {
      return baseSize - 1.0; // Smaller font for small screens
    } else if (isMediumMobile(context)) {
      return baseSize; // Base font size
    } else {
      return baseSize + 1.0; // Larger font for tablets
    }
  }
} 