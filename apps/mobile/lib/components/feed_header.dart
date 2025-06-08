import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show lerpDouble, ImageFilter;
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';

/// Modern, minimal header component for the HIVE social platform
class FeedHeader extends ConsumerStatefulWidget {
  /// Optional callback for when the create event button is tapped
  final VoidCallback? onCreateEventTap;

  /// Scroll controller for collapsing behavior
  final ScrollController scrollController;

  /// Constructor
  const FeedHeader({
    super.key,
    this.onCreateEventTap,
    required this.scrollController,
  });

  @override
  ConsumerState<FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends ConsumerState<FeedHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoToTextAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _logoToTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        // Use a more tech-styled curve
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    // Start animation immediately and set it to repeat
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create animation values based on scroll position
    return AnimatedBuilder(
        animation: widget.scrollController,
        builder: (context, child) {
          // Calculate collapse progress (0.0 - 1.0)
          final scrollPosition = widget.scrollController.hasClients
              ? widget.scrollController.offset
              : 0.0;
          final collapseProgress = (scrollPosition / 60).clamp(0.0, 1.0);

          // Calculate animated values
          final headerPadding = EdgeInsets.symmetric(
            horizontal: 16,
            vertical: lerpDouble(12, 8, collapseProgress)!,
          );

          final logoSize = lerpDouble(40, 32, collapseProgress)!;
          final textOpacity = lerpDouble(1.0, 0.8, collapseProgress)!;

          return _buildGlassmorphicHeader(
            context,
            Container(
              padding: headerPadding,
              child: Row(
                children: [
                  // Logo that transitions to text
                  AnimatedBuilder(
                    animation: _logoToTextAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with fading effect
                          Opacity(
                            opacity: 1.0 - _logoToTextAnimation.value,
                            child: SizedBox(
                              height: logoSize,
                              width: logoSize,
                              child: Image.asset(
                                'assets/images/hivelogo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          
                          // Small spacing
                          SizedBox(width: 4 * _logoToTextAnimation.value),

                          // Text with fading effect
                          Opacity(
                            opacity: _logoToTextAnimation.value * textOpacity,
                            child: Text(
                              'HIVE',
                              style: GoogleFonts.montserrat(
                                color: AppColors.white,
                                fontSize: lerpDouble(24, 20, collapseProgress),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // Messages icon in top right
                  IconButton(
                    constraints: BoxConstraints.tightFor(
                      width: lerpDouble(36, 32, collapseProgress)!,
                      height: lerpDouble(36, 32, collapseProgress)!,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      HugeIcons.strokeRoundedMessageLock01,
                      color: AppColors.white,
                      size: lerpDouble(20, 18, collapseProgress)!,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      // Navigate to messaging using the helper
                      _navigateToMessaging(context);
                    },
                  ),
                ],
              ),
            ),
            collapseProgress,
          );
        });
  }

  // Custom method to create a glassmorphic header container
  Widget _buildGlassmorphicHeader(
      BuildContext context, Widget child, double collapseProgress) {
    const blur = GlassmorphismGuide.kHeaderBlur;
    final opacity = lerpDouble(GlassmorphismGuide.kHeaderGlassOpacity,
        GlassmorphismGuide.kHeaderGlassOpacity * 0.8, collapseProgress)!;
    const borderRadius = GlassmorphismGuide.kRadiusMd;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  void _navigateToMessaging(BuildContext context) {
    context.push('/messaging');
  }
}
