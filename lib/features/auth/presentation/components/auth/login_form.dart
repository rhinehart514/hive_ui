import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Callback for authentication results
typedef AuthResultCallback = void Function(
    bool success, String message, bool needsOnboarding);

/// A form component for handling email/password login
class LoginForm extends ConsumerStatefulWidget {
  /// Callback when auth is complete
  final AuthResultCallback? onAuthResult;

  /// Whether the form is currently in a loading state
  final bool isLoading;

  /// Constructor
  const LoginForm({
    Key? key,
    this.onAuthResult,
    this.isLoading = false,
  }) : super(key: key);

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _emailError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _isLoading = widget.isLoading;
  }

  @override
  void didUpdateWidget(LoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      setState(() {
        _isLoading = widget.isLoading;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = null;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  /// Get current email for password reset
  String getEmail() {
    return _emailController.text.trim();
  }

  Future<void> handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      widget.onAuthResult
          ?.call(false, 'Please enter both email and password', false);
      return;
    }

    if (_emailError != null) {
      widget.onAuthResult
          ?.call(false, 'Please enter a valid email address', false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Success haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Initialize preferences if not already
      await UserPreferencesService.initialize();

      // Store the user's email for reference
      final email = _emailController.text.trim();
      await UserPreferencesService.saveUserEmail(email);

      // Sign in with Firebase - use the auth controller for proper state management
      await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
            email,
            _passwordController.text,
          );

      // Check if user has completed onboarding - but only if we got a valid sign in
      final hasCompletedOnboarding =
          UserPreferencesService.hasCompletedOnboarding();

      // Call the onAuthResult callback with success
      widget.onAuthResult
          ?.call(true, 'Sign in successful!', !hasCompletedOnboarding);
    } catch (e) {
      String errorMessage = 'Invalid email or password';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password';
            break;
          case 'invalid-credential':
            errorMessage = 'Invalid login credentials';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Please try again later';
            break;
          default:
            errorMessage = e.message ?? 'Authentication failed';
        }
      }

      // Provide haptic feedback for error
      HapticFeedback.vibrate();

      // Set loading state back to false
      setState(() {
        _isLoading = false;
      });

      // Call the onAuthResult callback with failure
      widget.onAuthResult?.call(false, errorMessage, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Field
        TextField(
          controller: _emailController,
          style: GoogleFonts.inter(color: AppColors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'University Email',
            labelStyle: GoogleFonts.inter(
              color: AppColors.white.withOpacity(0.7),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.white.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            errorText: _emailError,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        TextField(
          controller: _passwordController,
          style: GoogleFonts.inter(color: AppColors.white),
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.inter(
              color: AppColors.white.withOpacity(0.7),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.white.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gold,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppColors.white.withOpacity(0.7),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.white.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.black),
                    ),
                  )
                : Text(
                    'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
