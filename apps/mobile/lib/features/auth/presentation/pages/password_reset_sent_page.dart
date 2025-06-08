import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:hive_ui/utils/feedback_util.dart';

class PasswordResetSentPage extends StatelessWidget {
  const PasswordResetSentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Check Your Email'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // No back button
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_read_outlined, color: AppColors.gold, size: 64),
                  const SizedBox(height: 32),
                  const Text(
                    "If an account exists for the email provided, we've sent a password reset link. Please check your inbox (and spam folder).",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56, // HIVE Button Height
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.gold.withOpacity(0.7)),
                        foregroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28), // HIVE Button Radius
                        ),
                      ),
                      onPressed: () {
                        FeedbackUtil.buttonTap();
                        context.go(AppRoutes.signIn);
                      },
                      child: const Text(
                        'Back to Sign In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Didn't receive an email?",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      FeedbackUtil.selection();
                      context.go(AppRoutes.passwordReset);
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 