import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// A seamless, modern bottom navigation bar optimized for social platforms
/// with smooth transitions and minimal design
class HiveNavigationBar extends StatefulWidget {
  /// The currently selected index in the navigation bar
  final int selectedIndex;

  /// Callback function when a navigation item is selected
  final Function(int) onItemSelected;

  const HiveNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<HiveNavigationBar> createState() => _HiveNavigationBarState();
}

class _HiveNavigationBarState extends State<HiveNavigationBar>
    with TickerProviderStateMixin {
  // Initialize controllers and animations in initState instead of using late
  AnimationController? _controller;
  AnimationController? _entranceController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  int _previousIndex = 0;
  bool _animationsInitialized = false;

  // Navigation items with Material icons
  final List<_NavItemData> _navItems = [
    const _NavItemData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    const _NavItemData(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Spaces',
    ),
    const _NavItemData(
      icon: HugeIcons.profile,
      selectedIcon: HugeIcons.profile,
      label: 'Profile',
      isHugeIcon: true,
      iconSize: 40, // Huge size for profile icon
    ),
  ];

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    try {
      // Selection animation controller
      _controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: Curves.easeOutCubic,
        ),
      );
      _controller!.value = 1.0;

      // Entrance animation controller
      _entranceController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController!,
          curve: Curves.easeOutQuint,
        ),
      );

      // Start entrance animation
      _entranceController!.forward();
      _animationsInitialized = true;
    } catch (e) {
      _animationsInitialized = false;
      debugPrint('Error initializing navigation bar animations: $e');
    }
  }

  @override
  void didUpdateWidget(HiveNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        _animationsInitialized) {
      _previousIndex = oldWidget.selectedIndex;
      _controller!.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    if (_animationsInitialized) {
      _controller?.dispose();
      _entranceController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use simple version if animations aren't initialized properly
    if (!_animationsInitialized) {
      return _buildSimpleNavBar();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _entranceController!.drive(CurveTween(curve: Curves.easeOut)),
        child: _buildNavBarContent(),
      ),
    );
  }

  // Simple version without animations as fallback
  Widget _buildSimpleNavBar() {
    return _buildNavBarContent();
  }

  Widget _buildNavBarContent() {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey.shade900.withOpacity(0.3),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = widget.selectedIndex == index;
    final wasSelected = _previousIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index != widget.selectedIndex) {
            HapticFeedback.selectionClick();
            widget.onItemSelected(index);
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: _animationsInitialized
            ? _buildAnimatedNavItem(index, isSelected, wasSelected)
            : _buildSimpleNavItem(index, isSelected),
      ),
    );
  }

  // Animated version of the nav item
  Widget _buildAnimatedNavItem(int index, bool isSelected, bool wasSelected) {
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        // Calculate transition values
        double scale = 1.0;
        double opacity = 1.0;

        if (isSelected) {
          // Item is becoming selected
          scale = 0.8 + (0.2 * _controller!.value);
          opacity = 0.7 + (0.3 * _controller!.value);
        } else if (wasSelected) {
          // Item is becoming unselected
          scale = 1.0 - (0.1 * _controller!.value);
          opacity = 1.0 - (0.3 * _controller!.value);
        }

        return _buildNavItemContent(index, isSelected, scale, opacity);
      },
    );
  }

  // Simple version of the nav item without animations
  Widget _buildSimpleNavItem(int index, bool isSelected) {
    return _buildNavItemContent(
      index,
      isSelected,
      isSelected ? 1.0 : 0.9,
      isSelected ? 1.0 : 0.7,
    );
  }

  // Common content for both simple and animated versions
  Widget _buildNavItemContent(
      int index, bool isSelected, double scale, double opacity) {
    final navItem = _navItems[index];

    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: isSelected ? 12 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Icon and text
          Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon - uses Material Design icons or HugeIcons based on the item
                  navItem.isHugeIcon
                      ? Icon(
                          navItem.selectedIcon,
                          color: isSelected
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.7),
                          size: navItem.iconSize, // Use custom icon size
                        )
                      : Icon(
                          isSelected ? navItem.selectedIcon : navItem.icon,
                          color: isSelected
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.7),
                          size: navItem.iconSize,
                        ),

                  const SizedBox(height: 4),
                  Text(
                    navItem.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.gold
                          : Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified navigation item data class with Material icons
class _NavItemData {
  final IconData icon; // Icon for unselected state
  final IconData selectedIcon; // Icon for selected state
  final String label;
  final bool isHugeIcon; // Added to identify if it's a HugeIcon
  final double iconSize; // Added size property for custom sizing

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isHugeIcon = false,
    this.iconSize = 24,
  });
}
