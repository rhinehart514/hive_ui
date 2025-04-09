import 'package:flutter/material.dart';

/// Helper class for creating accessible profile widgets
class ProfileAccessibilityHelper {
  /// Creates an accessible tab view with proper semantics and navigation
  static Widget createAccessibleTabView({
    required TabController tabController,
    required List<Widget> children,
    required List<String> tabLabels,
  }) {
    assert(children.length == tabLabels.length, 'Number of children must match number of tab labels');

    return Semantics(
      container: true,
      child: TabBarView(
        controller: tabController,
        children: List.generate(children.length, (index) {
          return Semantics(
            label: '${tabLabels[index]} tab content',
            selected: tabController.index == index,
            child: children[index],
          );
        }),
      ),
    );
  }
} 