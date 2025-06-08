import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_layout.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/animated_hive_logo_pulse.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

/// Page shown after a magic link has been sent, with animated feedback.
class MagicLinkSentPage extends ConsumerStatefulWidget {
  const MagicLinkSentPage({super.key});

  @override
  ConsumerState<MagicLinkSentPage> createState() => _MagicLinkSentPageState();
}

class _MagicLinkSentPageState extends ConsumerState<MagicLinkSentPage> {
  bool _isResending = false;
  bool _resendSuccess = false;
  String? _resendError;

  Future<void> _resendMagicLink(String email) async {
    if (_isResending) return;
    
    setState(() {
      _isResending = true;
      _resendSuccess = false;
      _resendError = null;
    });
    FeedbackUtil.buttonTap();
    
    try {
      await ref.read(authRepositoryProvider).sendSignInLinkToEmail(email);
      if (mounted) {
        setState(() {
          _resendSuccess = true;
          _isResending = false;
        });
        FeedbackUtil.success();
        // Optionally show a confirmation toast
        FeedbackUtil.showToast(context: context, message: 'Link resent successfully!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resendError = 'Failed to resend link. Please try again.';
          _isResending = false;
        });
        FeedbackUtil.error();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final email = UserPreferencesService.getEmailForSignIn();
    final maskedEmail = email.isNotEmpty ? _maskEmail(email) : 'your email';

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBarBuilder.buildAuthAppBar(
          context,
          onBackPressed: () {
            FeedbackUtil.navigate();
            context.go(AppRoutes.signIn);
          },
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Animated HIVE logo with pulse effect
                const AnimatedHiveLogoPulse(size: 90).animate()
                  .fadeIn(duration: 500.ms).scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: AppLayout.spacingXLarge * 2),
                
                Text(
                  'Check Your Inbox',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                
                const SizedBox(height: AppLayout.spacingMedium),
                
                Text(
                  'We\'ve sent a magic link to $maskedEmail',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                
                const Spacer(),
                
                // Resend / Change Email Options
                Text(
                  "Didn't get it?",
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppLayout.spacingSmall),
                
                AnimatedSwitcher(
                  duration: 300.ms,
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: _isResending
                    ? const SizedBox(
                        height: 36,
                        width: 36,
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.white)),
                      )
                    : _resendSuccess
                      ? const Icon(Icons.check_circle_outline, color: AppColors.success, size: 36)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HivePrimaryButton(
                              text: 'Resend Link',
                              onPressed: () => _resendMagicLink(email),
                              isFullWidth: true,
                            ),
                            const SizedBox(height: AppLayout.spacingSmall),
                            TextButton(
                              onPressed: () {
                                FeedbackUtil.selection();
                                context.go(AppRoutes.signIn); // Go back to change email
                              },
                              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                              child: const Text('Use a different email'),
                            ),
                          ],
                        ),
                ),

                if (_resendError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _resendError!,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ).animate().shake(hz: 2, duration: 300.ms),
                  ),
                  
                const SizedBox(height: AppLayout.spacingLarge), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Masks an email address for privacy
  /// Example: j***@example.com
  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) {
      return 'your email';
    }
    
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    
    if (name.length <= 1) {
      return '*@$domain';
    }
    
    return '${name[0]}${'*' * (name.length - 1)}@$domain';
  }
} 