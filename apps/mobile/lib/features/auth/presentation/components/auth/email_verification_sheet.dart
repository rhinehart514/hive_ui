import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/widgets/form_fields/hive_text_form_field.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/core/ui/glass_container.dart';

// Standard HIVE Spacing & Radius
const double _kSheetPadding = 24.0;
const double _kSpacingS = 8.0;
const double _kSpacingM = 16.0;
const double _kSpacingL = 24.0;
const double _kButtonRadius = 24.0;
const double _kFieldRadius = 12.0; // Assuming a standard field radius

/// Callback indicating completion of the email verification attempt.
typedef VerificationCompleteCallback = void Function(bool success, String message);

/// A HIVE-styled bottom sheet for email verification code input.
class EmailVerificationSheet extends ConsumerStatefulWidget {
  final String email;
  final VerificationCompleteCallback onComplete;

  const EmailVerificationSheet({
    super.key,
    required this.email,
    required this.onComplete,
  });

  @override
  ConsumerState<EmailVerificationSheet> createState() => _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends ConsumerState<EmailVerificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _codeFieldError; // For invalid code errors

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validateCodeField(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) return 'Code is required';
    if (code.length != 6 || int.tryParse(code) == null) return 'Enter a valid 6-digit code';
    // Clear backend error if user modifies field
    if (_codeFieldError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) setState(() => _codeFieldError = null);
      });
    }
    return null;
  }

  Future<void> _handleVerification() async {
    setState(() => _codeFieldError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
       FeedbackUtil.error();
       return;
    }

    setState(() => _isLoading = true);
    final code = _codeController.text.trim();

    try {
      debugPrint('Attempting to verify email with code: $code');
      // TODO: Replace with actual Firebase function call result check if available
      // Assuming verifyEmailCode throws on failure or returns bool/status
      await ref.read(authRepositoryProvider).verifyEmailCode(code);
      debugPrint('Email code accepted (assuming success based on no throw)');

      // Add success haptic feedback
      FeedbackUtil.success();

      // These can happen after reporting success
      Future.microtask(() async {
         try {
           await ref.read(authRepositoryProvider).updateEmailVerificationStatus();
           await ref.read(authRepositoryProvider).checkEmailVerified();
           await UserPreferencesService.setNeedsOnboarding(true);
           ref.read(onboardingInProgressProvider.notifier).state = true;
         } catch (e) {
            debugPrint("Error during post-verification updates: $e");
            // Log this, but don't block user flow if code itself was okay
         }
      });

      if (mounted) {
         Navigator.of(context).pop(); // Close sheet first
         widget.onComplete(true, 'Email verified successfully!');
      }

    } catch (e) {
      FeedbackUtil.error();
      debugPrint('Email verification error: $e');
      String errorMessage = 'Invalid verification code.'; // Default error
       // TODO: Map specific exceptions from verifyEmailCode if available
      // if (e is ...) { errorMessage = ...; }

      if (mounted) {
        setState(() => _codeFieldError = errorMessage);
        widget.onComplete(false, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendCode() async {
    setState(() => _isLoading = true);
    FeedbackUtil.buttonTap();

    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        FeedbackUtil.success(); // Add success haptic
        FeedbackUtil.showToast(context: context,
          message: 'Verification code sent to ${widget.email}',
          isSuccess: true);
      }
    } catch (e) {
       if (mounted) {
         FeedbackUtil.error(); // Ensure error haptic
         FeedbackUtil.showToast(context: context,
           message: 'Failed to send code. Please try again.',
           isError: true);
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return GlassContainer(
      padding: EdgeInsets.only(
        left: _kSheetPadding,
        right: _kSheetPadding,
        top: _kSpacingS, // Reduced top padding for handle
        bottom: bottomPadding + _kSheetPadding,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: _kSpacingL), // Add margin below handle
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Verify Your Email',
              style: textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _kSpacingS),

            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _kSpacingL),

            // TEST MODE NOTICE - Styled
            Container(
              padding: const EdgeInsets.symmetric(horizontal: _kSpacingM, vertical: _kSpacingS),
              decoration: BoxDecoration(
                color: AppColors.infoStatus.withOpacity(0.1),
                borderRadius: BorderRadius.circular(_kFieldRadius), // Use defined radius
                border: Border.all(color: AppColors.infoStatus.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.infoStatus, size: 18),
                  const SizedBox(width: _kSpacingS),
                  Expanded(
                    child: Text(
                      'TEST MODE: Any 6-digit code will work',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.infoStatus,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _kSpacingL),

            HiveTextFormField(
              controller: _codeController,
              labelText: 'Verification Code',
              hintText: '6-digit code',
              keyboardType: TextInputType.number,
              validator: _validateCodeField,
              errorText: _codeFieldError,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading ? null : _handleVerification(),
            ),
            const SizedBox(height: _kSpacingM),

            HivePrimaryButton(
              text: 'Verify Email',
              onPressed: _isLoading ? null : _handleVerification,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
            const SizedBox(height: _kSpacingM),

            // Resend Code Button
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _handleResendCode,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: _kSpacingM, vertical: _kSpacingS),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
                ),
                child: Text(
                  'Resend Code',
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (bottomPadding == 0) const SizedBox(height: _kSpacingM),
          ],
        ),
      ),
    );
  }
} 