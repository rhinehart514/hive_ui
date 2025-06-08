import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

/// Displays a verification badge based on the user's verification status.
/// Shows a checkmark for verified users and a kinetic shimmer effect for verified+ users.
class VerificationBadge extends ConsumerWidget {
  /// User ID to check verification status for. If null, uses the current user.
  final String? userId;
  
  /// Size of the badge. Defaults to 16.
  final double size;
  
  /// Color of the badge. Defaults to gold.
  final Color? color;
  
  /// Whether to animate the badge (for verified+). Defaults to true.
  final bool animate;
  
  /// Creates a verification badge.
  const VerificationBadge({
    Key? key,
    this.userId,
    this.size = 16.0,
    this.color,
    this.animate = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color badgeColor = color ?? AppColors.gold;
    
    if (userId != null) {
      // If userId is provided, fetch the user data from database
      // For implementation in this PR, we'll use a placeholder
      // Future implementation will use userProfileProvider(userId)
      const isVerified = true; // Placeholder, will be replaced with actual logic
      const isVerifiedPlus = false; // Placeholder, will be replaced with actual logic
      
      return _buildBadge(isVerified, isVerifiedPlus, badgeColor);
    } else {
      // Use current user's verification status
      final currentUser = ref.watch(currentUserProvider);
      
      // Get the verification status from the user object
      // For now, let's use a placeholder that will be properly implemented
      // when the auth service is updated with verification fields
      final isVerified = currentUser.isVerified ?? false;
      final isVerifiedPlus = currentUser.isVerifiedPlus ?? false;
      
      return _buildBadge(isVerified, isVerifiedPlus, badgeColor);
    }
  }
  
  Widget _buildBadge(bool isVerified, bool isVerifiedPlus, Color badgeColor) {
    if (!isVerified) {
      return const SizedBox.shrink(); // No badge for unverified users
    }
    
    if (isVerifiedPlus && animate) {
      return _AnimatedVerifiedPlusBadge(size: size, color: badgeColor);
    } else if (isVerifiedPlus) {
      return _VerifiedPlusBadge(size: size, color: badgeColor);
    } else {
      return _VerifiedBadge(size: size, color: badgeColor);
    }
  }
}

/// Standard verification badge (checkmark icon)
class _VerifiedBadge extends StatelessWidget {
  final double size;
  final Color color;
  
  const _VerifiedBadge({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.dark,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.check,
          size: size * 0.7,
          color: color,
        ),
      ),
    );
  }
}

/// Verified+ badge (gold shimmer effect)
class _VerifiedPlusBadge extends StatelessWidget {
  final double size;
  final Color color;
  
  const _VerifiedPlusBadge({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.dark,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '+',
          style: TextStyle(
            color: color,
            fontSize: size * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Animated verified+ badge with shimmer effect
class _AnimatedVerifiedPlusBadge extends StatefulWidget {
  final double size;
  final Color color;
  
  const _AnimatedVerifiedPlusBadge({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<_AnimatedVerifiedPlusBadge> createState() => _AnimatedVerifiedPlusBadgeState();
}

class _AnimatedVerifiedPlusBadgeState extends State<_AnimatedVerifiedPlusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Pulse animation for the glow effect
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.7)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);
    
    // Rotation animation for the shimmer effect
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full rotation in radians
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    // Start the animation when visibility changes (e.g., scrolled into view)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.dark,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 + (_pulseAnimation.value * 0.4)),
                blurRadius: 4 + (_pulseAnimation.value * 3),
                spreadRadius: 1 + (_pulseAnimation.value * 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: ShimmerPainter(
                    color: widget.color,
                    angle: _rotateAnimation.value,
                    pulseValue: _pulseAnimation.value,
                  ),
                ),
              ),
              // Plus symbol
              Center(
                child: Transform.scale(
                  scale: 1.0 + (_pulseAnimation.value * 0.1),
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: widget.size * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for shimmer effect
class ShimmerPainter extends CustomPainter {
  final Color color;
  final double angle;
  final double pulseValue;
  
  ShimmerPainter({
    required this.color,
    required this.angle,
    required this.pulseValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create a sweeping gradient for the shimmer effect
    final shader = SweepGradient(
      center: Alignment.center,
      startAngle: angle,
      endAngle: angle + 2 * 3.14159,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.1 * pulseValue),
        color.withOpacity(0.7 * pulseValue),
        color.withOpacity(0.1 * pulseValue),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(Rect.fromCircle(
      center: center,
      radius: radius,
    ));
    
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, paint);
  }
  
  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.angle != angle || 
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.color != color;
  }
} 