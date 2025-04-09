import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Terms Acceptance page for the application
/// Shown during onboarding to ensure users accept the terms of service
class TermsAcceptancePage extends ConsumerStatefulWidget {
  /// Whether this is shown during onboarding (true) or from settings (false)
  final bool isOnboarding;

  /// Optional callback for when terms are accepted
  final VoidCallback? onAccepted;

  /// Creates a terms acceptance page
  const TermsAcceptancePage({
    super.key,
    this.isOnboarding = true,
    this.onAccepted,
  });

  @override
  ConsumerState<TermsAcceptancePage> createState() => _TermsAcceptancePageState();
}

class _TermsAcceptancePageState extends ConsumerState<TermsAcceptancePage> {
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAcceptance();
  }

  /// Check if the user has already accepted the terms
  Future<void> _checkExistingAcceptance() async {
    final authState = ref.read(authStateProvider);
    final hasAcceptedTerms = await ref.read(userPreferencesProvider.notifier).hasAcceptedTerms();
    
    if (hasAcceptedTerms && mounted) {
      setState(() {
        _acceptedTerms = true;
      });
    }
  }

  /// Handle the continue button press
  Future<void> _handleContinue() async {
    if (!_acceptedTerms) {
      // Show error message that terms must be accepted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Terms of Service to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save terms acceptance with timestamp
      await ref.read(userPreferencesProvider.notifier).setTermsAccepted(DateTime.now());

      if (!mounted) return;
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      if (widget.isOnboarding) {
        // If in onboarding flow, navigate to next screen
        NavigationTransitions.applyNavigationFeedback(
          type: NavigationFeedbackType.pageTransition,
        );
        context.go('/onboarding');
      } else {
        // If from settings, just pop back
        Navigator.of(context).pop();
      }

      // Call the callback if provided
      widget.onAccepted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving terms acceptance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBarBuilder.buildAuthAppBar(
        context,
        destinationRoute: widget.isOnboarding ? null : '/profile', 
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Terms content in scrollable area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        'Terms of Service',
                        style: GoogleFonts.outfit(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Last updated date
                    Center(
                      child: Text(
                        'Last Updated: April 1, 2024',
                        style: GoogleFonts.inter(
                          color: AppColors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Terms content sections
                    _buildTermsSection(
                      title: '1. Acceptance of Terms',
                      content: 'By accessing or using HIVE, you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not access or use the service.',
                    ),
                    _buildTermsSection(
                      title: '2. User Accounts',
                      content: 'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You must immediately notify us of any unauthorized use of your account.',
                    ),
                    _buildTermsSection(
                      title: '3. Content Guidelines',
                      content: 'You agree not to post content that is illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable. HIVE reserves the right to remove any content that violates these guidelines.',
                    ),
                    _buildTermsSection(
                      title: '4. Privacy Policy',
                      content: 'Your use of HIVE is also governed by our Privacy Policy, which is incorporated by reference into these Terms of Service.',
                    ),
                    _buildTermsSection(
                      title: '5. Modifications to Service',
                      content: 'HIVE reserves the right to modify or discontinue the service at any time, with or without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance of the service.',
                    ),
                    _buildTermsSection(
                      title: '6. Termination',
                      content: 'HIVE may terminate your access to the service for any reason, including but not limited to a violation of these Terms. You may also terminate your account at any time.',
                    ),
                    _buildTermsSection(
                      title: '7. Limitation of Liability',
                      content: 'HIVE shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
                    ),
                    _buildTermsSection(
                      title: '8. Governing Law',
                      content: 'These Terms shall be governed by the laws of the jurisdiction in which HIVE operates, without regard to its conflict of law provisions.',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact information
                    Text(
                      'Questions about the Terms of Service should be sent to support@hiveapp.com',
                      style: GoogleFonts.inter(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Acceptance checkbox and continue button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Acceptance checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                          // Provide haptic feedback
                          HapticFeedback.selectionClick();
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return AppColors.gold;
                            }
                            return Colors.transparent;
                          },
                        ),
                        checkColor: Colors.black,
                        side: const BorderSide(
                          color: AppColors.gold,
                          width: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I have read and agree to the Terms of Service and Privacy Policy',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
                        disabledForegroundColor: Colors.black45,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a section of the terms with title and content
  Widget _buildTermsSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 