import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuthException
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/form_fields/hive_text_form_field.dart'; // Use standard form field
import 'package:hive_ui/utils/feedback_util.dart';

// Standard HIVE Spacing & Radius - Should match parent page
const double _kSpacingM = 16.0;

/// Callback for authentication results.
/// The parent page should check onboarding status upon success.
typedef AuthResultCallback = void Function(
    bool success, String message);

/// A form component for handling email/password login, adhering to HIVE standards.
class LoginForm extends ConsumerStatefulWidget {
  /// Callback triggered after auth attempt (success or failure).
  final AuthResultCallback onAuthResult;

  /// Whether the parent page indicates a loading state (disables interactions).
  final bool isLoading;

  const LoginForm({
    super.key, // Use super.key
    required this.onAuthResult,
    required this.isLoading,
  });

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailFieldError; // For specific email errors like "not found"
  String? _passwordFieldError; // For "wrong password"

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Exposes the email for password reset functionality in the parent.
  String getEmail() {
    return _emailController.text.trim();
  }

  /// Validates the form and triggers the sign-in process.
  /// Returns true if validation passes and submission starts, false otherwise.
  bool validateAndSubmit() {
    // Clear previous field-specific errors on new submission attempt
    setState(() {
      _emailFieldError = null;
      _passwordFieldError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      // Validation passed, start the sign-in process
      _signIn();
      return true;
    } else {
      // Validation failed
      FeedbackUtil.error(); // Haptic for validation failure
      return false;
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Call controller method (returns void, handles state internally)
      await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
            email,
            password,
          );

      // If no exception, assume success for now. Parent checks onboarding.
      widget.onAuthResult(true, 'Login successful!');

    } on FirebaseAuthException catch (e) {
       FeedbackUtil.error(); // Haptic on any auth error
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        if (mounted) setState(() => _emailFieldError = 'Invalid email or user not found.');
        widget.onAuthResult(false, 'Login failed.'); // Inform parent
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') { // invalid-credential used in newer SDKs
        if (mounted) setState(() => _passwordFieldError = 'Incorrect password.');
        widget.onAuthResult(false, 'Login failed.'); // Inform parent
      } else {
        // Handle other specific Firebase errors or use a generic message
        final message = e.message ?? 'An unknown authentication error occurred.';
        if (mounted) widget.onAuthResult(false, message);
      }
    } catch (e) {
      // Handle non-Firebase exceptions
      FeedbackUtil.error();
      if (mounted) widget.onAuthResult(false, 'An unexpected error occurred. Please try again.');
    }
    // isLoading state is managed by the parent page
  }

  String? _validateEmailField(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) return 'Please enter a valid email';
    // Clear backend error if user modifies field
    if (_emailFieldError != null) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) setState(() => _emailFieldError = null);
       });
    }
    return null;
  }

   String? _validatePasswordField(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    // Basic length check, specific "wrong password" comes from backend
     if (password.length < 8) return 'Password too short'; // Match registration validation
     // Clear backend error if user modifies field
     if (_passwordFieldError != null) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted) setState(() => _passwordFieldError = null);
       });
     }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Use Form widget
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field using HiveTextFormField
          HiveTextFormField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmailField,
            errorText: _emailFieldError, // Display specific email error
            textInputAction: TextInputAction.next,
            // focusedBorderColor is now handled by the widget default (white)
            // enabled: !widget.isLoading, // Removed enabled property
          ),
          const SizedBox(height: _kSpacingM),

          // Password Field using HiveTextFormField
          HiveTextFormField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            obscureText: _obscurePassword,
            validator: _validatePasswordField,
            errorText: _passwordFieldError, // Display specific password error
            textInputAction: TextInputAction.done,
            // focusedBorderColor is now handled by the widget default (white)
            // enabled: !widget.isLoading, // Removed enabled property
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary, // Use secondary text color instead of gold
              ),
              onPressed: widget.isLoading ? null : () {
                FeedbackUtil.selection();
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            onFieldSubmitted: (_) {
              if (!widget.isLoading) validateAndSubmit();
            },
          ),
          // Button is now handled by the parent (LoginPage)
        ],
      ),
    );
  }
}
