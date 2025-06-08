import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuthException
import 'package:hive_ui/features/auth/providers/auth_providers.dart'; // To read repo provider
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/form_fields/hive_text_form_field.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/ui/glass_container.dart'; // For styling

// Standard HIVE Spacing & Radius
const double _kSheetPadding = 24.0;
const double _kSpacingS = 8.0;
const double _kSpacingM = 16.0;
const double _kSpacingL = 24.0;

/// Callback indicating completion of the password reset attempt.
/// Parent should use FeedbackUtil.showToast based on success/message.
typedef PasswordResetCallback = void Function(bool success, String message);

/// A HIVE-styled bottom sheet for password reset functionality.
class PasswordResetSheet extends ConsumerStatefulWidget {
  final String initialEmail;
  final PasswordResetCallback? onComplete;

  const PasswordResetSheet({
    super.key,
    required this.initialEmail,
    this.onComplete,
  });

  @override
  ConsumerState<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends ConsumerState<PasswordResetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false; // Use local loading state for the button
  String? _emailFieldError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _handleResetPassword() async {
    setState(() => _emailFieldError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      FeedbackUtil.error(); // Haptic for validation fail
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      // Call repository directly
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);

      if (mounted) {
        FeedbackUtil.success(); // Add success haptic feedback
        Navigator.pop(context); // Close sheet on success
        final message = 'Password reset link sent to $email';
        widget.onComplete?.call(true, message); // Inform parent
        // Parent (LoginPage) will show the FeedbackUtil.showToast
      }
    } on FirebaseAuthException catch (e) {
       if (mounted) {
         FeedbackUtil.error(); // Haptic on error
         String errorMessage = 'Failed to send reset link.';
         if (e.code == 'user-not-found' || e.code == 'invalid-email') {
           setState(() => _emailFieldError = 'No account found with this email.');
           errorMessage = 'No account found with this email.';
         } else {
            errorMessage = e.message ?? errorMessage;
         }
          widget.onComplete?.call(false, errorMessage);
       }
    } catch (e) {
      if (mounted) {
        FeedbackUtil.error();
        widget.onComplete?.call(false, 'An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // Add padding for keyboard overlap
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Use GlassContainer for HIVE styling
    return GlassContainer(
       // Apply padding within the glass container
      padding: EdgeInsets.only(
        left: _kSheetPadding,
        right: _kSheetPadding,
        top: _kSheetPadding,
        bottom: bottomPadding + _kSheetPadding, // Adjust for keyboard
      ),
      // Remove external decoration, handled by GlassContainer
      // borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fit content
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset Password',
              style: textTheme.headlineSmall?.copyWith( // Use theme style
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: _kSpacingS),
            Text(
              'Enter your email to receive a password reset link.',
              style: textTheme.bodyMedium?.copyWith( // Use theme style
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: _kSpacingL),

            HiveTextFormField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Your registered email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmailField,
              errorText: _emailFieldError,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading ? null : _handleResetPassword(),
            ),
            const SizedBox(height: _kSpacingL),

            HivePrimaryButton(
              text: 'Send Reset Link',
              onPressed: _isLoading ? null : _handleResetPassword,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
            // Add some extra space at the bottom if keyboard is not visible
            if (bottomPadding == 0) const SizedBox(height: _kSpacingM),
          ],
        ),
      ),
    );
  }
}
