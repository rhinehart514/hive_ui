import 'package:flutter/material.dart';

/// A helper class providing utilities for accessibility in the profile screen
class ProfileAccessibilityHelper {
  /// Creates a semantically-aware tab focus handler
  /// 
  /// This ensures that screenreaders and assistive technologies 
  /// properly focus and announce tab changes
  static Widget createAccessibleTabView({
    required TabController tabController, 
    required List<Widget> children,
    required List<String> tabLabels,
  }) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: TabBarView(
        controller: tabController,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          
          return ExcludeSemantics(
            // Only include semantics when tab is active
            excluding: tabController.index != index,
            child: Semantics(
              explicitChildNodes: true,
              label: 'Selected ${tabLabels[index]} tab content',
              selected: tabController.index == index,
              child: child,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Creates an accessible tab indicator with better contrast for visibility
  static Decoration createAccessibleTabIndicator({
    required Color color,
    required double size,
    double borderRadius = 3.0,
  }) {
    return UnderlineTabIndicator(
      borderSide: BorderSide(
        color: color,
        width: size,
      ),
      insets: EdgeInsets.symmetric(horizontal: borderRadius),
    );
  }

  /// Ensures sufficient touch target size for interactive elements
  static EdgeInsets getMobileFriendlyPadding({
    required bool isSmallScreen,
  }) {
    // Increase button padding on smaller screens to ensure 
    // at least 44x44 dp touch target (WCAG recommendation)
    return isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
  
  /// Helper method to create contrast-appropriate color for tabs
  static Color getTabLabelColor({
    required bool isSelected,
  }) {
    // Ensure at least 4.5:1 contrast ratio for accessibility
    return isSelected ? Colors.white : Colors.white.withOpacity(0.8);
  }
} 