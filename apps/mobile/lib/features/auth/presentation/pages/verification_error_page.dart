import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/theme/app_layout.dart';

/// Page shown when email verification fails, designed for gentle interruption.
class VerificationErrorPage extends ConsumerStatefulWidget {
  const VerificationErrorPage({super.key});

  @override
  ConsumerState<VerificationErrorPage> createState() => _VerificationErrorPageState();
}

class _VerificationErrorPageState extends ConsumerState<VerificationErrorPage> {
  bool _isResending = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    FeedbackUtil.buttonTap();
    try {
      // Assuming sendEmailVerification exists on the repository
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (context.mounted) {
        FeedbackUtil.success();
        FeedbackUtil.showToast(context: context, message: 'Verification email resent.', isSuccess: true);
        // Optionally navigate back or to a confirmation page
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackUtil.error();
        FeedbackUtil.showToast(context: context, message: 'Failed to resend email: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary), // Muted close icon
            onPressed: () {
              FeedbackUtil.selection();
              context.go('/sign-in');
            },
          ),
        ),
        body: Padding(
          padding: AppLayout.pagePadding.copyWith(bottom: AppLayout.spacingLarge * 2),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Cracked Orb Visual
                const _CrackedOrbVisual(),
                const SizedBox(height: AppLayout.spacingXLarge * 2),
                
                Text(
                  'Link Expired or Invalid',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                
                const SizedBox(height: AppLayout.spacingMedium),
                
                Text(
                  'Let\'s get you a fresh one.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                
                const Spacer(),
                
                // Resend Button with Loading/Shake
                Animate(
                  target: _isResending ? 1 : 0,
                  effects: const [ShakeEffect(hz: 2, duration: Duration(milliseconds: 300))], // Gentle shake
                  child: HivePrimaryButton(
                    text: 'Resend Link',
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    isLoading: _isResending,
                    isFullWidth: true,
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

/// Visual element representing a cracked golden orb.
class _CrackedOrbVisual extends StatefulWidget {
  const _CrackedOrbVisual();

  @override
  State<_CrackedOrbVisual> createState() => _CrackedOrbVisualState();
}

class _CrackedOrbVisualState extends State<_CrackedOrbVisual> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      controller: _controller,
      effects: const [FadeEffect(duration: Duration(milliseconds: 500))],
      child: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: _CrackedOrbPainter(animation: _controller),
        ),
      ),
    );
  }
}

class _CrackedOrbPainter extends CustomPainter {
  final Animation<double> animation;

  _CrackedOrbPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final progress = animation.value;

    // Orb Gradient
    final orbPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [AppColors.gold.withOpacity(0.7), AppColors.goldDark.withOpacity(0.5)],
        [0.0, 1.0],
      );
    canvas.drawCircle(center, radius, orbPaint);

    // Crack Paint
    final crackPaint = Paint()
      ..color = AppColors.dark.withOpacity(0.6 * progress) // Crack fades in
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * progress;

    // Define crack paths (simplified)
    final path1 = Path();
    path1.moveTo(center.dx - radius * 0.3, center.dy - radius * 0.5);
    path1.quadraticBezierTo(
      center.dx + radius * 0.1, center.dy, 
      center.dx + radius * 0.6 * progress, center.dy + radius * 0.4 * progress
    );

    final path2 = Path();
    path2.moveTo(center.dx + radius * 0.4, center.dy - radius * 0.3);
    path2.quadraticBezierTo(
      center.dx, center.dy + radius * 0.2, 
      center.dx - radius * 0.5 * progress, center.dy + radius * 0.6 * progress
    );

    canvas.drawPath(path1, crackPaint);
    canvas.drawPath(path2, crackPaint);
    
    // Subtle inner glow
     final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 0.8,
        [Colors.transparent, AppColors.goldDark.withOpacity(0.1 * progress)],
        [0.8, 1.0],
      );
      canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CrackedOrbPainter oldDelegate) => false;
} 