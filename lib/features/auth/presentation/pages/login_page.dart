import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/login_form.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/password_reset_sheet.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/social_auth_button.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Login page for the application
/// Refactored to use modular components for better maintainability
class LoginPage extends ConsumerStatefulWidget {
  /// Creates a login page
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _loginFormKey = GlobalKey<LoginFormState>();
  bool _isLoading = false;

  void _handleAuthResult(bool success, String message, bool needsOnboarding) {
    if (!success) {
      _showErrorSnackBar(message);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );

    // Brief delay to allow the success message to be seen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Check if there's a stored redirect path from social auth
        final redirectPath = UserPreferencesService.getSocialAuthRedirectPath();
        
        // Apply navigation feedback based on destination
        NavigationTransitions.applyNavigationFeedback(
          type: needsOnboarding
              ? NavigationFeedbackType.modalOpen
              : NavigationFeedbackType.pageTransition,
        );

        // Clear the stored redirect path after using it
        if (redirectPath.isNotEmpty) {
          UserPreferencesService.clearSocialAuthRedirectPath();
          // Navigate to the stored redirect path
          context.go(redirectPath);
        } else {
          // Navigate based on user onboarding status (default behavior)
          context.go(needsOnboarding ? '/onboarding' : '/home');
        }
      }
    });
  }

  void _showResetPasswordSheet() {
    final String email = _loginFormKey.currentState?.getEmail() ?? '';
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) => PasswordResetSheet(
        initialEmail: email,
        onComplete: (success, message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor:
                    success ? AppColors.bottomSheetBackground : AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    // Provide haptic feedback for error
    HapticFeedback.vibrate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the returnTo parameter from the route if it exists
    final String? returnToPath = GoRouterState.of(context).uri.queryParameters['return_to'];
    
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBarBuilder.buildAuthAppBar(
        context,
        destinationRoute: '/',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Hero(
                      tag: 'auth_logo',
                      child: Image.asset(
                        'assets/images/hivelogo.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Login Form
              LoginForm(
                key: _loginFormKey,
                isLoading: _isLoading,
                onAuthResult: _handleAuthResult,
              ),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showResetPasswordSheet,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Or Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.white.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: GoogleFonts.inter(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.white.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Google Sign In Button
              SocialAuthButton(
                provider: SocialAuthProvider.google,
                returnToPath: returnToPath,
                onAuthResult: (success, message, needsOnboarding) {
                  if (success) {
                    _handleAuthResult(success, message, needsOnboarding);
                  } else {
                    _showErrorSnackBar(message);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Create Account Link
              Hero(
                tag: 'auth_toggle_link',
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // Add transition feedback before navigation
                        NavigationTransitions.applyNavigationFeedback();

                        // Use push for smoother transition when navigating between auth screens
                        context.push('/create-account');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                      ),
                      child: Text(
                        "Don't have an account? Create one",
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
