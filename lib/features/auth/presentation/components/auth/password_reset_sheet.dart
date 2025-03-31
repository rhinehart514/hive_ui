import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A bottom sheet for password reset functionality
class PasswordResetSheet extends ConsumerStatefulWidget {
  /// Initial email to populate the field
  final String initialEmail;

  /// Callback when reset is complete
  final Function(bool success, String message)? onComplete;

  /// Constructor
  const PasswordResetSheet({
    Key? key,
    required this.initialEmail,
    this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends ConsumerState<PasswordResetSheet> {
  late final TextEditingController _emailController;
  bool _isResetting = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _handleResetPassword() async {
    if (_emailController.text.isEmpty) return;

    if (_emailError != null) {
      widget.onComplete?.call(false, 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      // Use the auth controller to send the reset email
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(
            _emailController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _isResetting = false;
        });

        // Add haptic feedback for success
        HapticFeedback.mediumImpact();

        Navigator.pop(context); // Close bottom sheet

        // Show different messages based on email type
        final email = _emailController.text.trim();
        final isBuffaloEmail = email.toLowerCase().endsWith('buffalo.edu');

        final message = isBuffaloEmail
            ? 'Password reset link sent to $email'
            : 'Password reset link sent to $email (Public tier access only)';

        widget.onComplete?.call(true, message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });

        // Add haptic feedback for error
        HapticFeedback.vibrate();

        final errorMessage =
            'Error sending reset email: ${e.toString().contains('FirebaseAuthException') ? e.toString().split(']').last.trim() : "Please try again"}';
        widget.onComplete?.call(false, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset Password',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email to receive a password reset link',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            style: GoogleFonts.inter(color: AppColors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResetting ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResetting
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
                      'Send Reset Link',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
