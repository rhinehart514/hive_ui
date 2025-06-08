import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/widgets/common/hive_scaffold.dart';
import 'package:lottie/lottie.dart';
import 'package:hive_ui/widgets/hive_progress_indicator.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

/// Page shown when email verification via link is successful.
class VerifiedEmailPage extends ConsumerStatefulWidget {
  const VerifiedEmailPage({super.key});

  @override
  ConsumerState<VerifiedEmailPage> createState() => _VerifiedEmailPageState();
}

class _VerifiedEmailPageState extends ConsumerState<VerifiedEmailPage> with SingleTickerProviderStateMixin {
  Timer? _redirectTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isVerifying = true;
  bool _verificationSuccess = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _processVerification();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  Future<void> _processVerification() async {
    try {
      // Get action code (oobCode) from URL
      final router = GoRouter.of(context);
      final oobCode = router.routeInformationProvider.value.uri.queryParameters['oobCode'];

      if (oobCode == null || oobCode.isEmpty) {
        setState(() {
          _isVerifying = false;
          _verificationSuccess = false;
          _errorMessage = 'Invalid verification link. No verification code found.';
        });
        FeedbackUtil.error();
        _redirectToErrorPage();
        return;
      }

      // Apply the action code (verify the email)
      await ref.read(authRepositoryProvider).applyActionCode(oobCode);
      
      // Update verification status
      await ref.read(authRepositoryProvider).updateEmailVerificationStatus();
      
      // Update state with success
      setState(() {
        _isVerifying = false;
        _verificationSuccess = true;
      });
      
      // Add success haptic feedback
      FeedbackUtil.success();
      
      // Start redirect timer
      _startRedirectTimer();
    } catch (e) {
      debugPrint('Email verification error: $e');
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _errorMessage = e.toString();
      });
      FeedbackUtil.error();
      _redirectToErrorPage();
    }
  }

  void _redirectToErrorPage() {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go('/verification-error');
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startRedirectTimer() {
    _redirectTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // Check onboarding status
      final onboardingComplete = UserPreferencesService.hasCompletedOnboarding();

      // Add navigation haptic feedback
      FeedbackUtil.navigate();

      // Redirect based on status
      if (mounted) {
        if (onboardingComplete) {
          context.go('/home'); // Go to home feed path
        } else {
          context.go(AppRoutes.onboarding); // Go to onboarding
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HiveScaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isVerifying) ...[
                  // Loading state
                  const SizedBox(height: 24),
                  const Text(
                    'Verifying your email...',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const HiveProgressIndicator(
                    progress: 0.25,
                    size: 40,
                  ),
                ] else if (_verificationSuccess) ...[
                  // Success animation
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'assets/animations/success_check.json',
                      repeat: false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'You\'re in. Verified. ✅',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Redirecting you shortly...',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Progress indicator with gold accent
                  const HiveProgressIndicator(
                    progress: 0.5,
                    size: 40,
                  ),
                ] else ...[
                  // Error state
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verification Failed',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage.isNotEmpty 
                        ? _errorMessage 
                        : 'We couldn\'t verify your email. Please try again.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 