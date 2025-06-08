import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/core/widgets/hive_secondary_button.dart';
import 'package:hive_ui/theme/app_layout.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// The Access Pass onboarding page collects minimal profile information
/// (first and last name) to grant initial access to the feed.
///
/// This is the first step in the onboarding flow after authentication.
class AccessPassPage extends ConsumerWidget {
  const AccessPassPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // No app bar for a more immersive feel
        body: SafeArea(
          child: Padding(
            padding: AppLayout.pagePadding.copyWith(bottom: AppLayout.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                // Access Pass Card with Animations
                _AccessPassCard(),
                const SizedBox(height: AppLayout.spacingXLarge),
                Text(
                  'Welcome to HIVE',
                  style: textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
                const SizedBox(height: AppLayout.spacingSmall),
                Text(
                  'This is your Access Pass. You\'re not just a student. You\'re part of the pulse.',
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
                const Spacer(flex: 3),
                // Dual CTAs
                Text(
                  'Verify your status or get invited:',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppLayout.spacingMedium),
                HivePrimaryButton(
                  text: 'Verify with .edu Email',
                  onPressed: () {
                    FeedbackUtil.buttonTap();
                    context.push('/onboarding/verify-edu'); // TODO: Update route
                  },
                  isFullWidth: true,
                ).animate().slideY(begin: 0.2, delay: 1200.ms, duration: 400.ms).fadeIn(),
                const SizedBox(height: AppLayout.spacingMedium),
                HiveSecondaryButton(
                  text: 'Start Building DNA',
                  onPressed: () {
                    FeedbackUtil.buttonTap();
                    context.push(AppRoutes.onboardingCampusDna);
                  },
                  isFullWidth: true,
                ).animate().slideY(begin: 0.2, delay: 1300.ms, duration: 400.ms).fadeIn(),
                const SizedBox(height: AppLayout.spacingLarge),
                
                // Add debug/testing skip button
                if (kDebugMode)
                  TextButton(
                    onPressed: () async {
                      // Mark onboarding as completed for testing
                      await UserPreferencesService.setOnboardingCompleted(true);
                      if (context.mounted) {
                        FeedbackUtil.buttonTap();
                        // Navigate directly to home
                        context.go(AppRoutes.home);
                      }
                    },
                    child: Text(
                      'Skip for Testing',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                    ),
                  ).animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The animated access pass card widget.
class _AccessPassCard extends StatefulWidget {
  @override
  __AccessPassCardState createState() => __AccessPassCardState();
}

class __AccessPassCardState extends State<_AccessPassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    FeedbackUtil.selection();
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    // Hover animation on load
    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [
        ShimmerEffect(duration: 2000.ms, color: AppColors.gold.withOpacity(0.1)),
        ScaleEffect(begin: const Offset(1,1), end: const Offset(1.02, 1.02), duration: 2000.ms, curve: Curves.easeInOut)
      ],
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * -math.pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: _controller.value >= 0.5 ? _buildCardBack() : _buildCardFront(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return AspectRatio(
      aspectRatio: 85.6 / 53.98, // Credit card ratio
      child: DarkSurface(
        surfaceType: SurfaceType.elevatedCard,
        borderRadius: BorderRadius.circular(AppLayout.radiusLarge),
        elevation: 4,
        padding: AppLayout.cardPadding,
        child: Stack(
          children: [
            // Subtle HIVE background pattern/logo
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset('assets/images/hive_pattern.png', fit: BoxFit.cover), // Placeholder pattern
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HIVE ACCESS PASS', style: TextStyle(color: AppColors.gold, fontSize: 10, letterSpacing: 1.5)),
                const Spacer(),
                Icon(Icons.qr_code_2, size: 40, color: AppColors.white.withOpacity(0.8)),
                const Spacer(),
                const Text('MEMBER', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
    Widget _buildCardBack() {
    // Rotated view for the back
    return Transform(
      transform: Matrix4.identity()..rotateY(math.pi), 
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: 85.6 / 53.98,
        child: DarkSurface(
          surfaceType: SurfaceType.elevatedCard,
          borderRadius: BorderRadius.circular(AppLayout.radiusLarge),
          elevation: 4,
          child: Container(
            color: AppColors.dark3, // Simple dark back
             alignment: Alignment.center,
            child: const Text('BACK', style: TextStyle(color: AppColors.textSecondary)), // Placeholder
          ),
        ),
      ),
    );
  }

} 