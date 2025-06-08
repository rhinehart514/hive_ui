import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Basic state provider for loading indicator
final _passwordResetLoadingProvider = StateProvider<bool>((ref) => false);

class PasswordResetPage extends ConsumerWidget {
  final String? initialEmail;
  
  const PasswordResetPage({
    super.key,
    this.initialEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(_passwordResetLoadingProvider);
    final emailController = TextEditingController(text: initialEmail); // Use provided email if available
    final formKey = GlobalKey<FormState>();

    Future<void> submitPasswordReset() async {
      if (formKey.currentState!.validate()) {
        FeedbackUtil.buttonTap();
        ref.read(_passwordResetLoadingProvider.notifier).state = true;
        try {
          // Actual Firebase auth call
          await FirebaseAuth.instance.sendPasswordResetEmail(
            email: emailController.text.trim(),
          );
          if (context.mounted) {
            // Add success feedback
            FeedbackUtil.success();
            context.go(AppRoutes.passwordResetSent);
          }
        } catch (e) {
          FeedbackUtil.error();
          if (context.mounted) {
            // Show error with better UI
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to send reset link: ${e is FirebaseAuthException ? e.message : "Please try again."}',
                  style: const TextStyle(color: AppColors.white),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          // Ensure loading state is always reset, even if context is lost mid-async gap
          ref.read(_passwordResetLoadingProvider.notifier).state = false;
        }
      } else {
        FeedbackUtil.error();
      }
    }

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Reset Password'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enter your account email address. We'll send you a link to reset your password.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: AppColors.gold.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.gold, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.error),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.error, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Taller HIVE Button Height for better touch targets
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28), // HIVE Button Radius
                          ),
                        ),
                        onPressed: isLoading ? null : submitPasswordReset,
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        FeedbackUtil.selection();
                        context.go(AppRoutes.signIn);
                      },
                      child: const Text(
                        'Back to Sign In',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
      ),
    );
  }
} 