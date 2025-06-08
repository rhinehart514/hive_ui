import 'dart:ui';
import 'package:flutter/material.dart';

/// HIVE Navigation System Implementation
/// Ultra-minimal, adaptive navigation that embodies HIVE's "invisible until needed" philosophy
/// 
/// Design Principles:
/// • Desktop: Slender vertical rail hugging left edge  
/// • Mobile: Floating bottom dock with blur backdrop
/// • Icons: Line art → filled gold when active
/// • Labels: Hidden by default, appear on hover/first-use
/// • Live indicators: Animated rings for real-time content
/// • Premium craft: Spring taps, soft focus, haptic feedback

// Interaction Tokens for consistent timing
class NavigationTokens {
  static const Duration microDuration = Duration(milliseconds: 150);
  static const Duration transitionDuration = Duration(milliseconds: 300);
  static const Duration springDuration = Duration(milliseconds: 400);
}

// Navigation Item Data Class
class NavigationItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final bool hasLiveContent;
  final int? badgeCount;

  const NavigationItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.hasLiveContent = false,
    this.badgeCount,
  });
}

// HIVE Navigation Rail (Desktop)
class HiveNavigationRail extends StatefulWidget {
  final List<NavigationItemData> items;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool showLabels;
  final double width;

  const HiveNavigationRail({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.showLabels = false,
    this.width = 72,
  });

  @override
  State<HiveNavigationRail> createState() => _HiveNavigationRailState();
}

class _HiveNavigationRailState extends State<HiveNavigationRail> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isSelected = index == widget.selectedIndex;
            final isHovered = index == _hoveredIndex;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _buildRailItem(item, isSelected, isHovered, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRailItem(NavigationItemData item, bool isSelected, bool isHovered, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: NavigationTokens.microDuration,
        curve: Curves.easeOut,
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
            ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.3))
            : isHovered 
              ? Border.all(color: Colors.white.withOpacity(0.1))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDestinationSelected?.call(index),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icon with animated switcher
                AnimatedSwitcher(
                  duration: NavigationTokens.microDuration,
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
                    size: 22,
                  ),
                ),
                // Live indicator
                if (item.hasLiveContent && isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Badge count
                if (item.badgeCount != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // Label on hover
                if ((widget.showLabels || isHovered) && isHovered)
                  Positioned(
                    left: 56,
                    child: AnimatedOpacity(
                      opacity: isHovered ? 1.0 : 0.0,
                      duration: NavigationTokens.microDuration,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HIVE Navigation Dock (Mobile)
class HiveNavigationDock extends StatefulWidget {
  final List<NavigationItemData> items;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool hapticFeedback;

  const HiveNavigationDock({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.hapticFeedback = true,
  });

  @override
  State<HiveNavigationDock> createState() => _HiveNavigationDockState();
}

class _HiveNavigationDockState extends State<HiveNavigationDock> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isSelected = index == widget.selectedIndex;
                
                return _buildDockItem(item, isSelected, index);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(NavigationItemData item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        // Trigger haptic feedback if enabled
        if (widget.hapticFeedback) {
          // HapticFeedback.lightImpact(); // Uncomment for real haptic
        }
        widget.onDestinationSelected?.call(index);
      },
      child: AnimatedContainer(
        duration: NavigationTokens.microDuration,
        curve: Curves.easeOut,
        width: 48,
        height: 48,
        transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring for selected
            if (isSelected)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            // Icon
            AnimatedSwitcher(
              duration: NavigationTokens.microDuration,
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
                size: 24,
              ),
            ),
            // Live indicator
            if (item.hasLiveContent && isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            // Badge count
            if (item.badgeCount != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Adaptive Navigation Wrapper
class HiveAdaptiveNavigation extends StatelessWidget {
  final List<NavigationItemData> items;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget child;
  final double breakpoint;

  const HiveAdaptiveNavigation({
    super.key,
    required this.items,
    required this.child,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.breakpoint = 768,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= breakpoint;

    if (isDesktop) {
      return Row(
        children: [
          HiveNavigationRail(
            items: items,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          Expanded(child: child),
        ],
      );
    } else {
      return Scaffold(
        body: child,
        bottomNavigationBar: HiveNavigationDock(
          items: items,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      );
    }
  }
}

// Sample Usage Demo for Design System
class HiveNavigationShowcase extends StatefulWidget {
  const HiveNavigationShowcase({super.key});

  @override
  State<HiveNavigationShowcase> createState() => _HiveNavigationShowcaseState();
}

class _HiveNavigationShowcaseState extends State<HiveNavigationShowcase> {
  int _selectedIndex = 0;

  final List<NavigationItemData> _navigationItems = [
    const NavigationItemData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Feed',
      route: '/feed',
      hasLiveContent: true,
    ),
    const NavigationItemData(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Spaces',
      route: '/spaces',
      hasLiveContent: false,
    ),
    const NavigationItemData(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event_rounded,
      label: 'Calendar',
      route: '/calendar',
      hasLiveContent: true,
    ),
    const NavigationItemData(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      label: 'Alerts',
      route: '/alerts',
      hasLiveContent: true,
      badgeCount: 3,
    ),
    const NavigationItemData(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
      hasLiveContent: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Desktop Navigation Rail Demo
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              HiveNavigationRail(
                items: _navigationItems,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFF0D0D0D),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _navigationItems[_selectedIndex].selectedIcon,
                          color: const Color(0xFFFFD700),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_navigationItems[_selectedIndex].label} Content',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Mobile Navigation Dock Demo
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              // Background content area
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E1E1E).withOpacity(0.8),
                      const Color(0xFF0D0D0D),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _navigationItems[_selectedIndex].selectedIcon,
                        color: const Color(0xFFFFD700),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_navigationItems[_selectedIndex].label} Mobile View',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating dock at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: HiveNavigationDock(
                  items: _navigationItems,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 