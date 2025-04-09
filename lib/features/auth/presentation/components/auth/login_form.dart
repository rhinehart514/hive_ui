import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _emailError;
  bool _obscurePassword = true;

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

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
          email,
          password,
        );
        
        // Check if user has accepted terms
        final hasAcceptedTerms = ref.read(userPreferencesProvider.notifier).hasAcceptedTerms();
        
        if (hasAcceptedTerms == false) {
          // Navigate to terms acceptance page
          if (mounted) {
            GoRouter.of(context).push('/terms?isOnboarding=false');
          }
        } else {
          // Navigate to home or dashboard
          if (mounted) {
            GoRouter.of(context).go('/home');
          }
        }
      } catch (e) {
        // Provide haptic feedback for error
        HapticFeedback.vibrate();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
          obscureText: _obscurePassword,
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
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.white.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
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
            onPressed: _isLoading ? null : _handleLogin,
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
