import 'package:flutter/material.dart';
import '../animation/animation_constants.dart';
import '../animation/hive_page_transition.dart';
import '../animation/staggered_animation_builder.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';
import 'glass_container.dart';
import 'responsive_layout.dart';

/// Central access point for all HIVE UI components and utilities
/// Makes it easy to access all UI elements from a single import
class HiveUI {
  /// Initialize the UI system (call in main.dart)
  static void initialize() {
    // Apply system UI styling (status bar, etc.)
    AppTheme.applySystemUIOverlayStyle();
  }
  
  /// Get the app's theme data
  static ThemeData get theme => AppTheme.darkTheme();
  
  /// Create a themed app with all the proper setup
  static Widget createThemedApp({
    required String title,
    required Widget home,
  }) {
    return MaterialApp(
      title: title,
      theme: theme,
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
  
  /// Navigation helpers
  
  /// Navigate to a new screen with the appropriate transition
  static Future<T?> navigateTo<T>({
    required BuildContext context,
    required Widget page,
    TransitionType transition = TransitionType.rightToLeft,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AnimationConstants.medium,
        reverseTransitionDuration: AnimationConstants.short,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: AnimationConstants.standardCurve,
          );

          switch (transition) {
            case TransitionType.fade:
              return FadeTransition(opacity: curve, child: child);
            case TransitionType.rightToLeft:
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(curve),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
                  child: child,
                ),
              );
            case TransitionType.leftToRight:
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(curve),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
                  child: child,
                ),
              );
            case TransitionType.bottomToTop:
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(curve),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
                  child: child,
                ),
              );
            case TransitionType.scale:
              return ScaleTransition(
                scale: Tween<double>(
                  begin: 0.95,
                  end: 1.0,
                ).animate(curve),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
                  child: child,
                ),
              );
            default:
              return FadeTransition(opacity: curve, child: child);
          }
        },
      ),
    );
  }
  
  /// Show a modal bottom sheet with glassmorphism style
  static Future<T?> showGlassBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: height,
          margin: const EdgeInsets.only(top: 60),
          child: GlassContainer.bottomSheet(
            child: builder(context),
          ),
        );
      },
    );
  }
  
  /// Show a dialog with glassmorphism style
  static Future<T?> showGlassDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: GlassContainer.modal(
            child: builder(context),
          ),
        );
      },
    );
  }
  
  /// Common components
  
  /// Create a standard card with HIVE styling
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
    bool useGlass = false,
  }) {
    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: useGlass ? Colors.transparent : AppColors.darkGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: child,
    );
    
    if (useGlass) {
      final Widget glassContent = GlassContainer(
        padding: padding,
        child: child,
      );
      
      return onTap != null
          ? InkWell(
              onTap: () {
                PlatformUtils.triggerHaptic(HapticType.light);
                onTap();
              },
              borderRadius: BorderRadius.circular(16),
              child: glassContent,
            )
          : glassContent;
    }
    
    return onTap != null
        ? InkWell(
            onTap: () {
              PlatformUtils.triggerHaptic(HapticType.light);
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: content,
          )
        : content;
  }
  
  /// Create a yellow/gold accent button for key actions like RSVP
  static Widget accentButton({
    required String text,
    required VoidCallback onPressed,
    bool isSmall = false,
    IconData? icon,
  }) {
    return TextButton(
      onPressed: () {
        PlatformUtils.triggerHaptic(HapticType.medium);
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.yellow,
        padding: isSmall
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: isSmall ? const Size(0, 36) : const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: isSmall ? AppTypography.interactiveSmall : AppTypography.interactive,
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed)) {
            return AppColors.yellow.withOpacity(0.15);
          }
          return null;
        }),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 18 : 22),
            SizedBox(width: isSmall ? 4 : 8),
          ],
          Text(text),
        ],
      ),
    );
  }
  
  /// Create a responsive layout wrapper
  static Widget responsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return ResponsiveLayout(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  /// Create a staggered animation list
  static Widget animatedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    StaggerDirection direction = StaggerDirection.bottomToTop,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return StaggeredAnimationBuilder.buildAnimatedItem(
          index: index,
          direction: direction,
          child: itemBuilder(context, index),
        );
      },
    );
  }
  
  /// Platform utilities
  
  /// Get platform-aware scroll physics
  static ScrollPhysics get scrollPhysics => PlatformUtils.getScrollPhysics();
  
  /// Trigger haptic feedback
  static void haptic(HapticType type) => PlatformUtils.triggerHaptic(type);
  
  /// Get screen padding based on device type
  static EdgeInsets getScreenPadding(BuildContext context) => 
      PlatformUtils.getScreenPadding(context);
} 