import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_layout.dart';
import 'package:hive_ui/theme/dark_surface.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/widgets/form_fields/hive_text_form_field.dart'; // Assuming masked input is a variation

// TODO: Define state/provider for verification logic

/// Secure identity challenge screen with an "elite" feel.
class VerifyIdentityPage extends ConsumerStatefulWidget {
  const VerifyIdentityPage({super.key});

  @override
  ConsumerState<VerifyIdentityPage> createState() => _VerifyIdentityPageState();
}

class _VerifyIdentityPageState extends ConsumerState<VerifyIdentityPage> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showError = false; // To trigger red shimmer
  bool _showSuccess = false; // To trigger gold dissolve

  String? _validateInput(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Input is required';
    if (input.length < 4) return 'Enter at least 4 digits'; // Example validation
    // Add more specific validation (e.g., digits only) if needed
    return null;
  }

  Future<void> _submitVerification() async {
    setState(() {
      _showError = false;
      _showSuccess = false;
    });

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      FeedbackUtil.buttonTap();

      // --- TODO: Replace with actual verification logic --- 
      await Future.delayed(1500.ms); // Simulate network call
      final bool success = _inputController.text.trim() == "1234"; // Example success condition
      // --- End of placeholder logic ---

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() => _showSuccess = true);
        FeedbackUtil.success();
        // Navigate on success after animation
        await Future.delayed(800.ms); // Allow dissolve animation
        if (mounted) context.go('/home'); // Or next step
      } else {
        setState(() => _showError = true);
        _inputController.clear();
        FeedbackUtil.error();
        // Reset error state after animation
        await Future.delayed(600.ms);
        if (mounted) setState(() => _showError = false);
      }
    } else {
       FeedbackUtil.error();
       setState(() => _showError = true); // Show error shimmer on validation fail
       await Future.delayed(600.ms);
       if (mounted) setState(() => _showError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bool canSubmit = _inputController.text.isNotEmpty && !_isLoading;

    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBarBuilder.buildAuthAppBar(context), // Assuming standard auth back navigation
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: AppLayout.pagePadding.copyWith(bottom: AppLayout.spacingLarge * 2),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Text(
                        'Verify Access',
                        style: textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: AppLayout.spacingSmall),
                      Text(
                        'Before we open the gates, confirm you belong.',
                        style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: AppLayout.spacingXLarge * 2),
                      
                      // Input Field with shimmer effect on error
                      Form(
                        key: _formKey,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6, // Limit width
                          child: HiveTextFormField(
                            controller: _inputController,
                            labelText: 'Last 4 Digits', // Or Student ID
                            hintText: '••••',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 4,
                            obscureText: true, // Mask input
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(letterSpacing: 8), // Spaced out digits
                            validator: _validateInput,
                            errorText: 'Invalid input',
                            focusedBorderColor: AppColors.white,
                            // TODO: Add custom InputDecorator for better masking style
                          ).animate(target: _showError ? 1 : 0).shimmer(
                            color: AppColors.error.withOpacity(0.6),
                            duration: 500.ms,
                          ),
                        ),
                      ),
                      const Spacer(),
                      HivePrimaryButton(
                        text: 'Confirm Identity',
                        onPressed: canSubmit ? _submitVerification : null,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Success Animation Overlay (Gold Barrier Dissolve)
              if (_showSuccess)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container()
                      .animate()
                      .color(
                        begin: AppColors.gold.withOpacity(0.8),
                        end: Colors.transparent,
                        duration: 700.ms,
                        curve: Curves.easeOut,
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