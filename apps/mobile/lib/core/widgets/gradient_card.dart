import 'package:flutter/material.dart';
import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:hive_ui/core/theme/animation_durations.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

/// A card component with gradient background following HIVE design specifications.
/// 
/// Implements the card design from brand_aesthetic.md Section 9.2:
/// - #1E1E1E → #2A2A2A gradient background
/// - 20pt corner radius
/// - No border by default, 1px white border with 6% opacity when active
/// - 16pt standard padding
/// - Tap animation: fade + compress + glow ring (inset)
/// - Hover animation: slight elevation + soft parallax (2px)
class GradientCard extends StatefulWidget {
  /// Child widget to display inside the card
  final Widget child;
  
  /// Whether the card is tappable
  final bool isInteractive;
  
  /// Callback when the card is tapped
  final VoidCallback? onTap;
  
  /// Whether to show the active state (with border)
  final bool isActive;
  
  /// Custom border radius (defaults to 20pt per HIVE specs)
  final BorderRadius? borderRadius;
  
  /// Custom padding (defaults to 16pt per HIVE specs)
  final EdgeInsetsGeometry? padding;
  
  /// Optional elevation for the card (0-6)
  final double elevation;
  
  /// Whether to add micro-grain texture (will be implemented in future)
  final bool enableGrainTexture;
  
  /// Whether to expand to fill available width
  final bool fullWidth;
  
  /// Whether to expand to fill available height
  final bool fullHeight;

  /// Creates a card with gradient background following HIVE design specifications.
  const GradientCard({
    super.key,
    required this.child,
    this.isInteractive = false,
    this.onTap,
    this.isActive = false,
    this.borderRadius,
    this.padding,
    this.elevation = 2.0,
    this.enableGrainTexture = true,
    this.fullWidth = false,
    this.fullHeight = false,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  final HapticFeedbackManager _hapticManager = HapticFeedbackManager();

  // Use nullable types
  AnimationController? _tapAnimationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    // Do NOT initialize here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize only if null
    if (_tapAnimationController == null) {
      final animationDurations = Theme.of(context).extension<AnimationDurations>() ?? 
                               const AnimationDurations();
      
      _tapAnimationController = AnimationController(
        duration: animationDurations.tapFeedback, 
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
        CurvedAnimation(
          parent: _tapAnimationController!,
          curve: AnimationCurves.tapFeedback, 
        ),
      );

      _indicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _tapAnimationController!,
          curve: Curves.easeOut, 
        ),
      );
    }
  }

  @override
  void dispose() {
    _tapAnimationController?.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationDurations = Theme.of(context).extension<AnimationDurations>() ?? 
                             const AnimationDurations();
    final cardRadius = widget.borderRadius ?? BorderRadius.circular(20.0);
    final border = widget.isActive 
        ? Border.all(color: AppColors.textPrimary.withOpacity(0.06), width: 1.0) 
        : Border.all(color: Colors.transparent);
    final cardWidth = widget.fullWidth ? double.infinity : null;
    final cardHeight = widget.fullHeight ? double.infinity : null;

    // Base card decoration
    Widget cardDecorationLayer = AnimatedContainer(
      duration: animationDurations.tapFeedback,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: cardRadius,
        border: border,
        boxShadow: _getCardShadow(),
      ),
    );

    // Card Content (Padded)
    final cardContent = Padding(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      child: widget.child,
    );

    // Top-right logo indicator - Use AnimatedBuilder safely again
    Widget logoIndicator = Positioned(
      top: 10, 
      right: 10,
      child: AnimatedBuilder(
        animation: _tapAnimationController ?? kAlwaysDismissedAnimation,
        builder: (context, child) {
          // Safely access animation value, default to 0.0 if null
          final currentOpacity = _indicatorAnimation?.value ?? 0.0;
          return Opacity(
            opacity: currentOpacity,
            child: child, 
          );
        },
        // The actual indicator content
        child: ColorFiltered( 
          colorFilter: ColorFilter.mode(
            AppColors.accentGold.withOpacity(0.8), 
            BlendMode.srcATop, 
          ),
          child: Image.asset(
            'assets/images/hivelogo.png',
            width: 24, 
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    // Combine decoration, content, and indicator
    Widget cardBody = Stack(
      children: [
        Positioned.fill(child: cardDecorationLayer),
        
        // Content fade using AnimatedBuilder (remains the same)
        AnimatedBuilder(
          animation: _tapAnimationController ?? kAlwaysDismissedAnimation,
          builder: (context, child) {
            final currentOpacity = _fadeAnimation?.value ?? 1.0;
            return Opacity(
              opacity: currentOpacity,
              child: child,
            );
          },
      child: cardContent,
        ),

        logoIndicator, 
      ],
    );
    
    // Add scale animation
    cardBody = AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: animationDurations.buttonPress,
        curve: AnimationCurves.buttonPress,
      child: cardBody,
      );

    // Clip to border radius
    Widget finalCard = ClipRRect(
      borderRadius: cardRadius,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: cardBody,
      ),
    );
    
    // Add interaction detectors if interactive
    if (widget.isInteractive) {
      finalCard = GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: () => _handleTapCancel(),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
        onEnter: (_) => _handleHoverEnter(),
        onExit: (_) => _handleHoverExit(),
        cursor: widget.onTap != null 
            ? SystemMouseCursors.click 
            : SystemMouseCursors.basic,
          child: finalCard,
        ),
      );
    }

    return finalCard;
  }

  List<BoxShadow> _getCardShadow() {
    if (widget.elevation <= 0) return [];
    double opacity = 0.1;
    if (_isHovered) opacity = 0.2;
    final double finalElevation = widget.elevation.clamp(0.0, 6.0);
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: finalElevation * 2,
        spreadRadius: finalElevation * 0.5,
        offset: _isHovered 
            ? const Offset(0, 2) 
            : const Offset(0, 1),
      ),
    ];
  }

  void _handleTapDown() {
    if (!widget.isInteractive || _tapAnimationController == null) return;
    setState(() {
      _isPressed = true;
    });
    _tapAnimationController!.forward();
    _hapticManager.lightTap();
  }

  void _handleTapUp() {
    if (!widget.isInteractive || !_isPressed || _tapAnimationController == null) return;
    setState(() {
      _isPressed = false;
    });
    _tapAnimationController!.reverse();
  }

  void _handleTapCancel() {
    if (!widget.isInteractive || !_isPressed || _tapAnimationController == null) return;
    setState(() {
      _isPressed = false;
    });
    _tapAnimationController!.reverse();
  }
  
  void _handleHoverEnter() {
    if (!widget.isInteractive) return;
    setState(() {
      _isHovered = true;
    });
  }
  
  void _handleHoverExit() {
    if (!widget.isInteractive) return;
    setState(() {
      _isHovered = false;
    });
  }
} 