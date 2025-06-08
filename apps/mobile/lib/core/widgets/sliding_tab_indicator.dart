import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

// Enum to define the indicator style
enum SlidingIndicatorStyle {
  underline,
  pill,
  backgroundHighlight,
  dot,
  none,
}

/// A TabBar that uses a custom sliding indicator.
/// Requires a [TabController].
class SlidingTabIndicator extends StatefulWidget {
  const SlidingTabIndicator({
    required this.tabController,
    required this.tabs,
    this.indicatorStyle = SlidingIndicatorStyle.underline,
    this.indicatorHeight = 3.0, // Used for underline/dot height
    this.indicatorColor = AppColors.gold,
    this.highlightColor = const Color(0x1AFFFFFF), // White 10% for background
    this.dotSize = 6.0,
    super.key,
  });

  final TabController tabController;
  final List<Widget> tabs;
  final SlidingIndicatorStyle indicatorStyle;
  final double indicatorHeight; // Used for underline height AND dot vertical position
  final Color indicatorColor; // Used for underline, pill, and dot
  final Color highlightColor; // Used for background highlight
  final double dotSize; // Diameter of the dot

  @override
  State<SlidingTabIndicator> createState() => _SlidingTabIndicatorState();
}

class _SlidingTabIndicatorState extends State<SlidingTabIndicator> {
  @override
  void initState() {
    super.initState();
    widget.tabController.animation?.addListener(_handleAnimationTick);
  }

  @override
  void didUpdateWidget(SlidingTabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabController != oldWidget.tabController) {
      oldWidget.tabController.animation?.removeListener(_handleAnimationTick);
      widget.tabController.animation?.addListener(_handleAnimationTick);
    }
  }

  @override
  void dispose() {
    widget.tabController.animation?.removeListener(_handleAnimationTick);
    super.dispose();
  }

  void _handleAnimationTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine text colors (can be overridden by wrapper for Style F)
    Color labelColor = AppColors.textPrimary;
    Color unselectedLabelColor = AppColors.textTertiary;

    // Hide the default indicator decoration if style is none
    final Decoration effectiveIndicator = widget.indicatorStyle == SlidingIndicatorStyle.none
      ? const BoxDecoration() // Essentially invisible indicator
      : _SlidingIndicatorDecoration(
          controller: widget.tabController,
          indicatorStyle: widget.indicatorStyle,
          indicatorHeight: widget.indicatorHeight,
          indicatorColor: widget.indicatorColor,
          highlightColor: widget.highlightColor,
          dotSize: widget.dotSize,
        );

    return TabBar(
      controller: widget.tabController,
      tabs: widget.tabs,
      isScrollable: false,
      indicatorWeight: 0,
      indicatorPadding: EdgeInsets.zero,
      indicator: effectiveIndicator,
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      // Style F might override label styles dynamically in the wrapper
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    );
  }
}

/// Custom Decoration for the sliding indicator.
class _SlidingIndicatorDecoration extends Decoration {
  const _SlidingIndicatorDecoration({
    required this.controller,
    required this.indicatorStyle,
    required this.indicatorHeight,
    required this.indicatorColor,
    required this.highlightColor,
    required this.dotSize,
  });

  final TabController controller;
  final SlidingIndicatorStyle indicatorStyle;
  final double indicatorHeight; // Underline height / Dot position reference
  final Color indicatorColor; // Underline/Pill/Dot color
  final Color highlightColor; // Background highlight color
  final double dotSize;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    // Return null painter if style is none (shouldn't be called due to build logic, but safe)
    if (indicatorStyle == SlidingIndicatorStyle.none) {
       return _NoOpPainter();
    }
    return _SlidingIndicatorPainter(
      this,
      controller,
      indicatorStyle,
      indicatorHeight,
      indicatorColor,
      highlightColor,
      dotSize,
      onChanged,
    );
  }
}

// A painter that does nothing, used when style is none.
class _NoOpPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    // No-op
  }
}

/// Custom BoxPainter to draw the sliding indicator.
class _SlidingIndicatorPainter extends BoxPainter {
  _SlidingIndicatorPainter(
    this.decoration,
    this.controller,
    this.indicatorStyle,
    this.indicatorHeight,
    this.indicatorColor,
    this.highlightColor,
    this.dotSize,
    VoidCallback? onChanged,
  ) : super(onChanged);

  final _SlidingIndicatorDecoration decoration;
  final TabController controller;
  final SlidingIndicatorStyle indicatorStyle;
  final double indicatorHeight; // Used for underline height and dot vertical position
  final Color indicatorColor;
  final Color highlightColor;
  final double dotSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    // Added check for style == none early exit
    if (indicatorStyle == SlidingIndicatorStyle.none) return;
    
    assert(configuration.size != null);
    final Size size = configuration.size!;
    if (controller.length == 0) return;
    final double tabWidth = size.width / controller.length;

    final double animationValue = controller.animation?.value ?? controller.index.toDouble();
    final int startIndex = animationValue.floor().clamp(0, controller.length - 1);
    final int endIndex = (startIndex + 1).clamp(0, controller.length - 1);
    final double progress = animationValue - startIndex.toDouble();

    final double startX = offset.dx + startIndex * tabWidth;
    final double endX = offset.dx + endIndex * tabWidth;
    final double currentX = ui.lerpDouble(startX, endX, progress) ?? startX;

    final Paint paint = Paint()..style = PaintingStyle.fill;
    // Adjusted radius logic slightly
    final Radius radius = indicatorStyle == SlidingIndicatorStyle.pill 
                         ? Radius.circular(size.height / 2) 
                         : (indicatorStyle == SlidingIndicatorStyle.underline 
                             ? const Radius.circular(2.0) 
                             : Radius.zero); // Dot doesn't use RRect radius

    Rect indicatorRect;
    Color color;

    switch (indicatorStyle) {
      case SlidingIndicatorStyle.underline:
        indicatorRect = Rect.fromLTWH(
          currentX,
          offset.dy + size.height - indicatorHeight, // Use height for position
          tabWidth,
          indicatorHeight, // Use height for thickness
        );
        color = indicatorColor;
        paint.color = color;
        final RRect indicatorRRect = RRect.fromRectAndCorners(
          indicatorRect,
          topLeft: radius, topRight: radius,
        );
        canvas.drawRRect(indicatorRRect, paint);
        break;

      case SlidingIndicatorStyle.pill:
        const double pillPadding = 4.0;
        indicatorRect = Rect.fromLTWH(
          currentX + pillPadding / 2,
          offset.dy + pillPadding / 2,
          tabWidth - pillPadding,
          size.height - pillPadding,
        );
        color = indicatorColor;
        paint.color = color;
        final RRect indicatorRRect = RRect.fromRectAndCorners(
           indicatorRect, 
           topLeft: radius, topRight: radius, 
           bottomLeft: radius, bottomRight: radius
        );
        canvas.drawRRect(indicatorRRect, paint);
        break;

      case SlidingIndicatorStyle.backgroundHighlight:
        const double highlightPadding = 0;
        indicatorRect = Rect.fromLTWH(
          currentX + highlightPadding / 2,
          offset.dy + highlightPadding / 2,
          tabWidth - highlightPadding,
          size.height - highlightPadding,
        );
        color = highlightColor;
        paint.color = color;
        final RRect indicatorRRect = RRect.fromRectAndCorners(
           indicatorRect, 
           topLeft: radius, topRight: radius, 
           bottomLeft: radius, bottomRight: radius
        );
        canvas.drawRRect(indicatorRRect, paint);
        break;

      case SlidingIndicatorStyle.dot:
        // Calculate center X for the dot
        final double dotCenterX = currentX + tabWidth / 2;
        // Position dot below the tab baseline, using indicatorHeight as offset reference
        final double dotCenterY = offset.dy + size.height - indicatorHeight;
        final Offset center = Offset(dotCenterX, dotCenterY);
        color = indicatorColor;
        paint.color = color;
        canvas.drawCircle(center, dotSize / 2, paint);
        break;
        
      case SlidingIndicatorStyle.none: // Should not be reached due to checks
         break;
    }
  }
} 