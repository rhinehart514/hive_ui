import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

/// Breakpoint definitions for responsive layout
class ScreenBreakpoints {
  static const double mobileSmall = 320;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;
  static const double tablet = 768;
  static const double desktop = 1024;
}

/// Widget that provides different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        // Desktop layout
        if (maxWidth >= ScreenBreakpoints.desktop && desktop != null) {
          return desktop!;
        }
        
        // Tablet layout
        if (maxWidth >= ScreenBreakpoints.tablet && tablet != null) {
          return tablet!;
        }
        
        // Default to mobile layout
        return mobile;
      },
    );
  }
}

/// Widget that adjusts its layout based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSizeInfo sizeInfo) builder;
  
  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ScreenSizeInfo sizeInfo = _getSizeInfo(context, constraints);
        return builder(context, sizeInfo);
      },
    );
  }
  
  ScreenSizeInfo _getSizeInfo(BuildContext context, BoxConstraints constraints) {
    final double deviceWidth = constraints.maxWidth;
    final double deviceHeight = constraints.maxHeight;
    
    // Determine device type
    final bool isTablet = PlatformUtils.isTablet(context);
    
    // Determine size class
    SizeClass sizeClass;
    if (deviceWidth >= ScreenBreakpoints.desktop) {
      sizeClass = SizeClass.desktop;
    } else if (deviceWidth >= ScreenBreakpoints.tablet || isTablet) {
      sizeClass = SizeClass.tablet;
    } else if (deviceWidth >= ScreenBreakpoints.mobileLarge) {
      sizeClass = SizeClass.mobileLarge;
    } else if (deviceWidth >= ScreenBreakpoints.mobileMedium) {
      sizeClass = SizeClass.mobileMedium;
    } else {
      sizeClass = SizeClass.mobileSmall;
    }
    
    return ScreenSizeInfo(
      deviceWidth: deviceWidth,
      deviceHeight: deviceHeight,
      sizeClass: sizeClass,
      isTablet: isTablet,
    );
  }
}

/// Size classification for device screens
enum SizeClass {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tablet,
  desktop,
}

/// Contains information about the current screen size
class ScreenSizeInfo {
  final double deviceWidth;
  final double deviceHeight;
  final SizeClass sizeClass;
  final bool isTablet;
  
  const ScreenSizeInfo({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.sizeClass,
    required this.isTablet,
  });
  
  bool get isMobile => sizeClass == SizeClass.mobileSmall || 
                      sizeClass == SizeClass.mobileMedium || 
                      sizeClass == SizeClass.mobileLarge;
  
  bool get isDesktop => sizeClass == SizeClass.desktop;
  
  /// Returns a scalar value (0.8-1.2) for scaling UI elements based on device size
  double get scaleFactor {
    switch (sizeClass) {
      case SizeClass.mobileSmall:
        return 0.8;
      case SizeClass.mobileMedium:
        return 0.9;
      case SizeClass.mobileLarge:
        return 1.0;
      case SizeClass.tablet:
        return 1.1;
      case SizeClass.desktop:
        return 1.2;
    }
  }
} 