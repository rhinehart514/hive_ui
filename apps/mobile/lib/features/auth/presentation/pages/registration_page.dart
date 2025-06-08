import 'package:flutter/material.dart';
// For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/email_verification_sheet.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

/// Simple, web-optimized registration page
class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    if (!email.toLowerCase().endsWith('.edu')) {
      return 'Please use your .edu school email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      debugPrint('🔘 Creating account for: ${_emailController.text.trim()}');
      ref.read(authControllerProvider.notifier).createUserWithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _handlePasskeyRegistration() async {
    if (_emailController.text.isEmpty) {
      FeedbackUtil.showToast(context: context, message: 'Please enter your .edu email first', isError: true);
      FeedbackUtil.error();
      return;
    }
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
       FeedbackUtil.showToast(context: context, message: emailError, isError: true);
       FeedbackUtil.error();
       return;
    }

    FeedbackUtil.buttonTap();

    final isSupported = await ref.read(authRepositoryProvider).isPasskeySupported();
    if (!mounted) return;
    if (!isSupported) {
      FeedbackUtil.showToast(context: context, message: 'Passkeys are not supported on this device.', isError: true);
      FeedbackUtil.error();
      return;
    }

    ref.read(authControllerProvider.notifier).registerWithPasskey(
          _emailController.text.trim(),
        );
  }

  void _showVerificationSheet(String email) {
    FeedbackUtil.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => EmailVerificationSheet(
        email: email,
        onComplete: (success, message) {
           if (Navigator.canPop(context)) {
              Navigator.pop(context);
           }
           if (message.isNotEmpty) {
              FeedbackUtil.showToast(
                context: context,
                message: message,
                isSuccess: success,
                isError: !success,
              );
           }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final authOperationState = ref.watch(authControllerProvider);
    final isLoading = authOperationState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError && !(previous?.hasError ?? false)) {
        final error = next.error;
        String errorMessage = "Registration failed. Please try again.";
        if (error is FirebaseAuthException && error.code == 'email-already-in-use') {
          errorMessage = "Email already exists. Try logging in.";
        } else if (error.toString().contains('Passkey') && error.toString().contains('cancelled')) {
           errorMessage = "Passkey registration cancelled.";
        } else if (error.toString().contains('not supported')) {
          errorMessage = 'Passkeys are not supported on this device.';
        }

        FeedbackUtil.showToast(context: context, message: error?.toString() ?? errorMessage, isError: true);
        FeedbackUtil.error();
      }

      bool wasLoadingSignUp = previous is AsyncLoading &&
                             (previous.hashCode ?? 0) != (next.hashCode ?? 1);

      if (next is AsyncData && wasLoadingSignUp) {
         _showVerificationSheet(_emailController.text.trim());
      }
    });

    ref.listen<AsyncValue<AuthUser>>(authStateProvider, (previous, next) {
      if (next.hasValue) {
        final user = next.value;
        if (user != null && user.isNotEmpty) {
          final wasPreviouslyAuthenticated = previous?.hasValue ?? false && (previous?.value?.isNotEmpty ?? false);

          if (!wasPreviouslyAuthenticated) {
            // Add try-catch for UserPreferencesService to handle potential failures
            bool needsOnboarding = true;
            try {
              needsOnboarding = !UserPreferencesService.hasCompletedOnboarding();
            } catch (e) {
              debugPrint('⚠️ RegistrationPage: Error checking onboarding status: $e');
              // Default to showing onboarding if UserPreferencesService fails
              needsOnboarding = true;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FeedbackUtil.navigate();
                try {
                  NavigationTransitions.applyNavigationFeedback(
                    type: needsOnboarding ? NavigationFeedbackType.modalOpen : NavigationFeedbackType.pageTransition);
                } catch (e) {
                  debugPrint('⚠️ RegistrationPage: Navigation feedback error: $e');
                  // Continue even if feedback fails
                }

                final targetPath = needsOnboarding ? AppRoutes.onboarding : AppRoutes.home;
                try {
                  context.go(targetPath);
                } catch (e) {
                  debugPrint('⚠️ RegistrationPage: Navigation error: $e');
                  // Fallback navigation if go_router fails
                  try {
                    if (needsOnboarding) {
                      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                        '/onboarding', 
                        (route) => false
                      );
                    } else {
                      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false
                      );
                    }
                  } catch (e2) {
                    debugPrint('⚠️ RegistrationPage: Fallback navigation also failed: $e2');
                    // Show error dialog as last resort
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Navigation Error'),
                        content: Text('Unable to navigate to ${needsOnboarding ? 'onboarding' : 'home'}.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            });
          }
        }
      }
    });

    final linkStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.gold,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.gold.withOpacity(0.5),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go(AppRoutes.landing),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HIVE Logo
                    Center(
                      child: Image.asset(
                        'assets/images/hivelogo.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Join your campus community',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'University Email',
                        hintText: 'yourname@university.edu',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: _validateEmail,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password Field
                    TextFormField(
                controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                labelText: 'Password',
                        hintText: 'At least 8 characters',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                suffixIcon: IconButton(
                  icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white54,
                  ),
                  onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Create Account Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0D0D0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                          ? const SizedBox(
                                height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0D0D0D),
                                  ),
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.signIn),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Footer
                    Text(
                      'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
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