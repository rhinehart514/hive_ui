import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';

/// Types of navigation bar styles available in HIVE UI
enum HiveNavigationBarStyle {
  /// Standard navigation bar with icons and optional labels
  standard,

  /// iOS-inspired navigation bar with pill indicators and blur effects
  ios,

  /// Minimal navigation bar with just icons
  minimal,

  /// Glassmorphic navigation bar with frosted glass effect
  glass
}

/// Configuration for the position and appearance of the navigation bar
enum HiveNavigationBarPosition {
  /// Bottom navigation bar
  bottom,

  /// Side navigation bar (typically used on larger screens)
  side
}

/// A standardized navigation destination for use with HiveNavigationBar
class HiveNavigationDestination {
  /// Icon to display when this destination is not selected
  final IconData icon;

  /// Icon to display when this destination is selected
  final IconData selectedIcon;

  /// Label to display for this destination
  final String label;

  /// Optional badge count to display on this destination
  final int? badgeCount;

  /// Whether this destination has a notification
  final bool hasNotification;

  /// Constructor
  const HiveNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
    this.hasNotification = false,
  });
}

/// A standardized navigation bar component for HIVE UI, supporting multiple styles and configurations
class HiveNavigationBar extends StatefulWidget {
  /// The currently selected index
  final int selectedIndex;

  /// Callback when a destination is selected
  final Function(int) onDestinationSelected;

  /// The destinations to display in the navigation bar
  final List<HiveNavigationDestination> destinations;

  /// The style of the navigation bar
  final HiveNavigationBarStyle style;

  /// The position of the navigation bar
  final HiveNavigationBarPosition position;

  /// Whether to show labels for destinations
  final bool showLabels;

  /// Whether to apply haptic feedback on selection
  final bool useHapticFeedback;

  /// Whether to use the glassmorphism effect (overridden if style is glass)
  final bool useGlassmorphism;

  /// Background color of the navigation bar
  final Color? backgroundColor;

  /// Selected item color
  final Color? selectedItemColor;

  /// Unselected item color
  final Color? unselectedItemColor;

  /// Constructor
  const HiveNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.style = HiveNavigationBarStyle.standard,
    this.position = HiveNavigationBarPosition.bottom,
    this.showLabels = true,
    this.useHapticFeedback = true,
    this.useGlassmorphism = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  State<HiveNavigationBar> createState() => _HiveNavigationBarState();
}

class _HiveNavigationBarState extends State<HiveNavigationBar>
    with TickerProviderStateMixin {
  // Animation controllers for various effects
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // For entrance animation (if needed)
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup scale animation for item selection
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      ),
    );

    // Setup entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start entrance animation
    _entranceController.forward();

    // Animate initially selected item
    _scaleController.forward();
  }

  @override
  void didUpdateWidget(HiveNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      // Animate on selection change
      _scaleController.reset();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// Apply haptic feedback when a destination is selected
  void _applyHapticFeedback() {
    if (widget.useHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildNavigationBarByStyle(),
      ),
    );
  }

  /// Build the navigation bar based on the selected style
  Widget _buildNavigationBarByStyle() {
    switch (widget.style) {
      case HiveNavigationBarStyle.ios:
        return _buildIOSStyleNavBar();
      case HiveNavigationBarStyle.minimal:
        return _buildMinimalNavBar();
      case HiveNavigationBarStyle.glass:
        return _buildGlassmorphicNavBar();
      case HiveNavigationBarStyle.standard:
        return _buildStandardNavBar();
    }
  }

  /// Build the standard style navigation bar
  Widget _buildStandardNavBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.black,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildNavigationItems(),
      ),
    );
  }

  /// Build the iOS-inspired navigation bar
  Widget _buildIOSStyleNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: (widget.backgroundColor ?? AppColors.black).withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 70, // Reduced height for smaller icons
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildIOSStyleItems(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a minimal navigation bar
  Widget _buildMinimalNavBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildMinimalNavigationItems(),
      ),
    );
  }

  /// Build the glassmorphic style navigation bar
  Widget _buildGlassmorphicNavBar() {
    // Add extra padding to the bottom to account for safe area
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(16), // Less rounded corners for stability
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15.0, // Reduced blur for stability
            sigmaY: 15.0,
          ),
          child: Container(
            height: 56 + bottomPadding, // Reduced height
            padding: EdgeInsets.only(bottom: bottomPadding, top: 2), // Minimal top padding
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.5), // More opaque for stability
              borderRadius: const BorderRadius.all(
                Radius.circular(16),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5, // Thinner border
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.12),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildSimpleNavigationItems(),
            ),
          ),
        ),
      ),
    );
  }

  /// Build simplified navigation items to prevent overflow
  List<Widget> _buildSimpleNavigationItems() {
    return List.generate(widget.destinations.length, (index) {
      final destination = widget.destinations[index];
      final isSelected = index == widget.selectedIndex;

      return Expanded(
        child: InkWell(
          onTap: () {
            if (index != widget.selectedIndex) {
              _applyHapticFeedback();
              widget.onDestinationSelected(index);
            }
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: 50, // Constrain height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pill indicator for selected items
                if (isSelected)
                  Container(
                    width: 20, // Narrower indicator
                    height: 2, // Shorter indicator
                    margin: const EdgeInsets.only(bottom: 2), // Smaller margin
                    decoration: BoxDecoration(
                      color: widget.selectedItemColor ?? AppColors.gold,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.selectedItemColor ?? AppColors.gold).withOpacity(0.4),
                          blurRadius: 5,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                
                // Icon - without scale animation to save space
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  color: isSelected
                      ? (widget.selectedItemColor ?? AppColors.gold)
                      : (widget.unselectedItemColor ?? AppColors.textSecondary),
                  size: 24, // Smaller icon size
                ),
              
                // Label with smaller text and padding
                if (widget.showLabels)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        color: isSelected
                            ? (widget.selectedItemColor ?? AppColors.gold)
                            : (widget.unselectedItemColor ?? AppColors.textSecondary),
                        fontSize: 10, // Smaller font size
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Build navigation items based on the destinations provided
  List<Widget> _buildNavigationItems({bool useGlass = false}) {
    return List.generate(widget.destinations.length, (index) {
      final destination = widget.destinations[index];
      final isSelected = index == widget.selectedIndex;

      return Expanded(
        child: InkWell(
          onTap: () {
            if (index != widget.selectedIndex) {
              _applyHapticFeedback();
              widget.onDestinationSelected(index);
            }
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show a pill indicator for selected items in iOS style
                if (useGlass && isSelected)
                  Container(
                    width: 24,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: widget.selectedItemColor ?? AppColors.gold,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.selectedItemColor ?? AppColors.gold).withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),

                // Icon with animation
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isSelected
                            ? destination.selectedIcon
                            : destination.icon,
                        color: isSelected
                            ? (widget.selectedItemColor ?? AppColors.white)
                            : (widget.unselectedItemColor ??
                                AppColors.textSecondary),
                        size: 32,
                      ),

                      // Show badge if needed
                      if (destination.badgeCount != null &&
                          destination.badgeCount! > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    widget.backgroundColor ?? AppColors.black,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              destination.badgeCount! > 99
                                  ? '99+'
                                  : '${destination.badgeCount}',
                              style: AppTheme.labelSmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (destination.hasNotification)
                        // Simple dot indicator for notifications
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    widget.backgroundColor ?? AppColors.black,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Label (if enabled)
                if (widget.showLabels)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        color: isSelected
                            ? (widget.selectedItemColor ?? AppColors.white)
                            : (widget.unselectedItemColor ??
                                AppColors.textSecondary),
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Build iOS-style navigation items with pill indicators
  List<Widget> _buildIOSStyleItems() {
    return List.generate(
      widget.destinations.length,
      (index) {
        final destination = widget.destinations[index];
        final isSelected = index == widget.selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (index != widget.selectedIndex) {
                _applyHapticFeedback();
                widget.onDestinationSelected(index);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pill indicator
                if (isSelected)
                  Container(
                    width: 20,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: widget.selectedItemColor ?? AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(height: 8),

                // All icons get consistent spacing
                const SizedBox(height: 2),

                _buildIcon(
                  icon:
                      isSelected ? destination.selectedIcon : destination.icon,
                  isSelected: isSelected,
                  hasBadge: destination.badgeCount != null ||
                      destination.hasNotification,
                  badgeCount: destination.badgeCount,
                  size: 28, // Consistent size for all icons
                ),

                if (widget.showLabels) ...[
                  // Consistent spacing for all icons
                  const SizedBox(height: 2),
                  Text(
                    destination.label,
                    style: TextStyle(
                      color: isSelected
                          ? (widget.selectedItemColor ?? AppColors.gold)
                          : (widget.unselectedItemColor ??
                              Colors.white.withOpacity(0.7)),
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build minimal navigation items (icons only)
  List<Widget> _buildMinimalNavigationItems() {
    return List.generate(
      widget.destinations.length,
      (index) {
        final destination = widget.destinations[index];
        final isSelected = index == widget.selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (index != widget.selectedIndex) {
                _applyHapticFeedback();
                widget.onDestinationSelected(index);
              }
            },
            child: _buildIcon(
              icon: isSelected ? destination.selectedIcon : destination.icon,
              isSelected: isSelected,
              hasBadge:
                  destination.badgeCount != null || destination.hasNotification,
              badgeCount: destination.badgeCount,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  /// Build an icon with optional badge
  Widget _buildIcon({
    required IconData icon,
    required bool isSelected,
    bool hasBadge = false,
    int? badgeCount,
    double size = 24,
  }) {
    // All icons will use the same size
    final double iconSize = size;

    Widget iconWidget = Icon(
      icon,
      color: isSelected
          ? (widget.selectedItemColor ?? AppColors.gold)
          : (widget.unselectedItemColor ?? Colors.white.withOpacity(0.7)),
      size: iconSize,
    );

    // Apply scale animation if selected
    if (isSelected) {
      iconWidget = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    // If no badge, return just the icon
    if (!hasBadge) {
      return iconWidget;
    }

    // Add a badge to the icon
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: EdgeInsets.all(badgeCount != null ? 4 : 3),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: badgeCount != null ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  badgeCount != null ? BorderRadius.circular(8) : null,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: badgeCount != null
                ? Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
