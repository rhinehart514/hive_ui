import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';
import '../theme/app_colors.dart';
import 'dart:ui';

/// Breakpoint definitions for responsive layout following HIVE aesthetic
class ScreenBreakpoints {
  static const double mobileSmall = 320;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
}

/// Widget that provides different layouts based on screen size
/// with HIVE's sophisticated dark infrastructure aesthetic
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? desktopLarge;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.desktopLarge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        // Desktop large layout
        if (maxWidth >= ScreenBreakpoints.desktopLarge && desktopLarge != null) {
          return desktopLarge!;
        }
        
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

/// Widget that adjusts its layout based on screen size with HIVE aesthetics
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
    if (deviceWidth >= ScreenBreakpoints.desktopLarge) {
      sizeClass = SizeClass.desktopLarge;
    } else if (deviceWidth >= ScreenBreakpoints.desktop) {
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
  desktopLarge,
}

/// Contains information about the current screen size with HIVE-specific insights
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
  
  bool get isDesktop => sizeClass == SizeClass.desktop || 
                        sizeClass == SizeClass.desktopLarge;

  /// Returns a scalar value for scaling UI elements based on device size
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
      case SizeClass.desktopLarge:
        return 1.3;
    }
  }
  
  /// Returns the appropriate blur intensity based on screen size following HIVE aesthetic
  double get blurIntensity {
    switch (sizeClass) {
      case SizeClass.mobileSmall:
      case SizeClass.mobileMedium:
      case SizeClass.mobileLarge:
        return 15.0; // More intense blur for smaller screens
      case SizeClass.tablet:
        return 20.0; 
      case SizeClass.desktop:
      case SizeClass.desktopLarge:
        return 25.0; // Subtler blur for larger screens
    }
  }
  
  /// Returns appropriate padding scale for the current device
  EdgeInsets get contentPadding {
    const base = 16.0;
    switch (sizeClass) {
      case SizeClass.mobileSmall:
        return const EdgeInsets.all(base * 0.75);
      case SizeClass.mobileMedium:
      case SizeClass.mobileLarge:
        return const EdgeInsets.all(base);
      case SizeClass.tablet:
        return const EdgeInsets.all(base * 1.5);
      case SizeClass.desktop:
        return const EdgeInsets.all(base * 2.0);
      case SizeClass.desktopLarge:
        return const EdgeInsets.all(base * 2.5);
    }
  }
  
  /// Gets appropriate card elevation based on device size
  double get cardElevation {
    switch (sizeClass) {
      case SizeClass.mobileSmall:
      case SizeClass.mobileMedium:
      case SizeClass.mobileLarge:
        return 2.0;
      case SizeClass.tablet:
        return 3.0;
      case SizeClass.desktop:
      case SizeClass.desktopLarge:
        return 4.0;
    }
  }
  
  /// Returns appropriate transition duration based on device size
  Duration get transitionDuration {
    // Slightly faster transitions on mobile, standard on larger screens
    return Duration(milliseconds: isMobile ? 300 : 400);
  }
  
  /// Returns appropriate haptic feedback intensity
  HapticFeedbackType get defaultHapticFeedback {
    return isMobile ? HapticFeedbackType.light : HapticFeedbackType.medium;
  }
}

/// Haptic feedback types for various interactions
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  success,
  error,
}

/// A responsive container that adapts to screen size with HIVE aesthetics
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double? maxWidth;
  final Alignment alignment;
  final bool applyGlassmorphism;
  
  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.maxWidth,
    this.alignment = Alignment.center,
    this.applyGlassmorphism = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        final container = Container(
          width: width,
          height: height,
          padding: padding ?? sizeInfo.contentPadding,
          alignment: alignment,
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          decoration: BoxDecoration(
            gradient: applyGlassmorphism ? 
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfacePrimary.withOpacity(0.8),
                  AppColors.surfaceSecondary.withOpacity(0.7),
                ],
              ) : null,
            borderRadius: BorderRadius.circular(16.0),
            border: applyGlassmorphism ?
              Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 0.5,
              ) : null,
          ),
          child: child,
        );
        
        if (applyGlassmorphism) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: sizeInfo.blurIntensity,
                sigmaY: sizeInfo.blurIntensity,
              ),
              child: container,
            ),
          );
        }
        
        return container;
      },
    );
  }
} 