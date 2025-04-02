import 'package:flutter/material.dart';

/// Utility class for responsive design in messaging components
class ResponsiveUtils {
  /// Breakpoints for different device sizes
  static const double kMobileBreakpoint = 600;
  static const double kTabletBreakpoint = 1200;
  static const double kDesktopBreakpoint = 1440;
  
  /// Get the device type based on width
  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < kMobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < kTabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  /// Get responsive value based on device size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T defaultValue,
    T? tablet,
    T? desktop,
  }) {
    DeviceType deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? defaultValue;
      case DeviceType.tablet:
        return tablet ?? defaultValue;
      case DeviceType.mobile:
      default:
        return defaultValue;
    }
  }
  
  /// Get responsive padding based on device size
  static EdgeInsets getResponsivePadding({
    required BuildContext context,
    required EdgeInsets defaultPadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: defaultPadding,
      tablet: tabletPadding,
      desktop: desktopPadding,
    );
  }
  
  /// Get responsive font size based on device size
  static double getResponsiveFontSize({
    required BuildContext context,
    required double defaultSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: defaultSize,
      tablet: tabletSize,
      desktop: desktopSize,
    );
  }
  
  /// Get responsive dimensions for containers based on device size
  static double getResponsiveWidth({
    required BuildContext context,
    required double defaultWidth,
    double? tabletWidth,
    double? desktopWidth,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: defaultWidth,
      tablet: tabletWidth,
      desktop: desktopWidth,
    );
  }
  
  /// Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Get safe area bottom padding
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
  
  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
  
  /// Get available height (screen height minus app bar, bottom bar, etc.)
  static double getAvailableHeight(
    BuildContext context, {
    double appBarHeight = kToolbarHeight,
    double bottomBarHeight = 0,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return screenHeight - appBarHeight - bottomBarHeight - topPadding - bottomPadding;
  }
}

/// Device type enumeration
enum DeviceType {
  /// Mobile device (phone)
  mobile,
  
  /// Tablet device
  tablet,
  
  /// Desktop/large screen device
  desktop,
} 