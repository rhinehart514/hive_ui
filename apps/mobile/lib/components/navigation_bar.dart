import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'dart:ui';

/// Types of navigation bar styles available in HIVE UI
enum HiveNavigationBarStyle {
  glass,
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

/// A standardized glassmorphic navigation bar component for HIVE UI.
class HiveNavigationBar extends StatefulWidget {
  /// The currently selected index
  final int selectedIndex;

  /// Callback when a destination is selected
  final Function(int) onDestinationSelected;

  /// The destinations to display in the navigation bar
  final List<HiveNavigationDestination> destinations;

  /// The position of the navigation bar
  final HiveNavigationBarPosition position;

  /// Whether to show labels for destinations
  final bool showLabels;

  /// Whether to apply haptic feedback on selection
  final bool useHapticFeedback;

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
    this.position = HiveNavigationBarPosition.bottom,
    this.showLabels = true,
    this.useHapticFeedback = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  }) : assert(destinations.length >= 3, 'Navigation bar requires at least 3 destinations.');

  @override
  State<HiveNavigationBar> createState() => _HiveNavigationBarState();
}

class _HiveNavigationBarState extends State<HiveNavigationBar>
    with TickerProviderStateMixin {
  // Only keep necessary controllers
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // Start entrance animation
    _entranceController.forward();
  }

  @override
  void didUpdateWidget(HiveNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
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
    // Style is always glass
    const HiveNavigationBarStyle effectiveStyle = HiveNavigationBarStyle.glass;
    // Glass effect is always true
    const bool isGlassEffect = true;

    // Use default background (transparent for glass) unless overridden
    Color bgColor = widget.backgroundColor ?? Colors.transparent;

    // Main container logic - the Row of items
    Widget navBarItems = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _buildItemsByStyle(effectiveStyle), // Pass the only style
    );

    // Apply glass effect
    Widget contentWithGlass = ClipRRect(
      borderRadius: _getBorderRadius(effectiveStyle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          color: bgColor, // Apply background color inside filter
          child: navBarItems,
        ),
      ),
    );

    // Decorate the main container
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
          child: Container(
          height: _getBarHeight(),
          margin: _getMargin(effectiveStyle),
            decoration: BoxDecoration(
            color: Colors.transparent, // Main container is transparent for glass
            borderRadius: _getBorderRadius(effectiveStyle),
            border: _getBorder(effectiveStyle),
            boxShadow: _getShadow(effectiveStyle),
          ),
          child: contentWithGlass,
        ),
      ),
    );
  }

  // --- Helper methods for style variations (simplified) ---

  double _getBarHeight() {
    // Simplified height logic
    if (widget.showLabels) return 65 + MediaQuery.of(context).padding.bottom;
    return 56 + MediaQuery.of(context).padding.bottom;
  }

  EdgeInsets _getMargin(HiveNavigationBarStyle style) {
    // Only glass style margin relevant
    return const EdgeInsets.fromLTRB(12, 0, 12, 12);
  }

  BorderRadius _getBorderRadius(HiveNavigationBarStyle style) {
    // Only glass style radius relevant
    return const BorderRadius.all(Radius.circular(16));
  }

  Border? _getBorder(HiveNavigationBarStyle style) {
    // Only glass style border relevant
    return Border.all(color: Colors.white.withOpacity(0.15), width: 0.5);
  }

  List<BoxShadow>? _getShadow(HiveNavigationBarStyle style) {
    // Only glass style shadow relevant
    return [BoxShadow(color: AppColors.gold.withOpacity(0.12), blurRadius: 8, spreadRadius: -2)];
  }

  /// Build the list of items (now only for glass style)
  List<Widget> _buildItemsByStyle(HiveNavigationBarStyle style) {
    List<Widget> items = [];
    for (int index = 0; index < widget.destinations.length; index++) {
      final destination = widget.destinations[index];
      final isSelected = index == widget.selectedIndex;

      // Determine icon size and color
      const double iconSize = 28; // Standard size for glass
      Color iconColor = isSelected
                      ? (widget.selectedItemColor ?? AppColors.gold)
          : (widget.unselectedItemColor ?? Colors.white.withOpacity(0.7));

      // Determine label style
      TextStyle labelStyle = TextStyle(
        color: iconColor,
        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      );

      // --- Build the core Icon ---
      Widget iconWidget = Icon(
          isSelected ? destination.selectedIcon : destination.icon,
          color: iconColor,
          size: iconSize,
      );

      // --- Apply Animations ---
      if (isSelected) {
         iconWidget = ScaleTransition(
           scale: _scaleAnimation,
           child: iconWidget,
         );
      }

      // --- Add Badges ---
      if (destination.badgeCount != null || destination.hasNotification) {
        iconWidget = _addBadgeToIcon(iconWidget, destination, style);
      }

      // --- Build the Label (if shown) ---
      Widget labelWidget = widget.showLabels
        ? Padding(
            padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      destination.label,
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
        : const SizedBox.shrink();

      // --- No Indicators for Glass Style ---

      // --- Assemble the Item ---
      Widget itemContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            labelWidget,
            // No extra spacing needed for indicators
          ],
      );

      items.add(
        Expanded(
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                _applyHapticFeedback();
                widget.onDestinationSelected(index);
              }
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Center(child: itemContent),
          ),
        ),
      );
    }
    return items;
  }

  // Helper to add badge overlay to an icon widget
  Widget _addBadgeToIcon(Widget iconWidget, HiveNavigationDestination destination, HiveNavigationBarStyle style) {
    const double topOffset = -5; // Standard offset
    const double rightOffset = -5;
    const double badgeSize = 16;
    double badgePadding = (destination.badgeCount != null) ? 4 : 3;
    const double fontSize = 10;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        iconWidget,
        Positioned(
          top: topOffset,
          right: rightOffset,
          child: Container(
            padding: EdgeInsets.all(badgePadding),
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: destination.badgeCount != null ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: destination.badgeCount != null ? BorderRadius.circular(8) : null,
              border: Border.all(color: Colors.black.withOpacity(0.5), width: 1),
            ),
            constraints: const BoxConstraints(
              minWidth: badgeSize,
              minHeight: badgeSize,
            ),
            child: destination.badgeCount != null
                ? Text(
                    destination.badgeCount! > 99 ? '99+' : destination.badgeCount!.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
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
