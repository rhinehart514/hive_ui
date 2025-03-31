import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// A utility class to build consistent app bars across the app
class AppBarBuilder {
  /// Creates a transparent app bar with a back button for onboarding flows
  static PreferredSizeWidget buildOnboardingAppBar(
    BuildContext context, {
    VoidCallback? onBackPressed,
    bool showBackButton = true,
    double elevation = 0,
    Color backgroundColor = Colors.transparent,
    List<Widget>? actions,
    Widget? title,
    PreferredSizeWidget? bottom,
    double? titleSpacing,
  }) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.black.withOpacity(0.3),
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              onPressed: onBackPressed ??
                  () {
                    // Add haptic feedback for better user experience
                    HapticFeedback.lightImpact();

                    // Check if we can go back in the page controller (if we're in onboarding)
                    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
                    final FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }

                    Navigator.maybePop(context);
                  },
            )
          : null,
      actions: actions,
      title: title,
      centerTitle: title != null,
      titleSpacing: titleSpacing,
      bottom: bottom,
    );
  }

  /// Creates a standard app bar with proper mobile platform adaptations
  static PreferredSizeWidget buildStandardAppBar(
    BuildContext context, {
    required String title,
    VoidCallback? onBackPressed,
    bool showBackButton = true,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    double elevation = 0,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.black,
      elevation: elevation,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: onBackPressed ??
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.maybePop(context);
                  },
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: actions,
      bottom: bottom,
    );
  }

  /// Creates a transparent app bar with a circular back button for auth flows
  static PreferredSizeWidget buildAuthAppBar(
    BuildContext context, {
    String? destinationRoute,
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.black.withOpacity(0.3),
            border: Border.all(
              color: AppColors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: 20,
          ),
        ),
        onPressed: onBackPressed ??
            () {
              HapticFeedback.lightImpact();
              if (destinationRoute != null) {
                context.go(destinationRoute);
              } else {
                Navigator.maybePop(context);
              }
            },
      ),
    );
  }

  /// Creates a specialized app bar for the main feed
  static PreferredSizeWidget buildFeedAppBar(
    BuildContext context, {
    VoidCallback? onRefresh,
    VoidCallback? onSearch,
    VoidCallback? onNotifications,
    List<Widget>? actions,
    double elevation = 0,
    Color? backgroundColor,
    PreferredSizeWidget? bottom,
  }) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.black,
      elevation: elevation,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      title: Text(
        'HIVE',
        style: GoogleFonts.outfit(
          color: AppColors.gold,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
      actions: actions ??
          [
            if (onSearch != null)
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onSearch();
                },
              ),
            if (onNotifications != null)
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onNotifications();
                },
              ),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRefresh();
                },
              ),
            const SizedBox(width: 8),
          ],
      bottom: bottom,
    );
  }
}
