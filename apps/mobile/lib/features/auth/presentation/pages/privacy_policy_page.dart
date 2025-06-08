import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy page for the application
/// Shown during onboarding or from settings to ensure users understand privacy practices
class PrivacyPolicyPage extends ConsumerStatefulWidget {
  /// Whether this is shown during onboarding (true) or from settings (false)
  final bool isOnboarding;

  /// Optional callback for when privacy policy is accepted
  final VoidCallback? onAccepted;

  /// External privacy policy URL
  static const String externalPrivacyPolicyUrl = 'https://hiveapp.com/privacy';

  /// Creates a privacy policy page
  const PrivacyPolicyPage({
    super.key,
    this.isOnboarding = true,
    this.onAccepted,
  });

  @override
  ConsumerState<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends ConsumerState<PrivacyPolicyPage> {
  bool _acceptedPrivacyPolicy = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAcceptance();
  }

  /// Check if the user has already accepted the privacy policy
  Future<void> _checkExistingAcceptance() async {
    final hasAcceptedPrivacy = ref.read(userPreferencesProvider).hasAcceptedPrivacyPolicy;
    
    if (hasAcceptedPrivacy && mounted) {
      setState(() {
        _acceptedPrivacyPolicy = true;
      });
    }
  }

  /// Open external privacy policy link
  Future<void> _openExternalPrivacyPolicy() async {
    final uri = Uri.parse(PrivacyPolicyPage.externalPrivacyPolicyUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle the continue button press
  Future<void> _handleContinue() async {
    if (!_acceptedPrivacyPolicy) {
      // Show error message that privacy policy must be accepted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the Privacy Policy to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save privacy policy acceptance with timestamp
      await ref.read(userPreferencesProvider.notifier).setPrivacyPolicyAccepted(DateTime.now());

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
          content: Text('Error saving privacy acceptance: $e'),
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
            // Privacy content in scrollable area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        'Privacy Policy',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Last updated date
                    Center(
                      child: Text(
                        'Last Updated: April 1, 2024',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Introduction
                    _buildPolicySection(
                      title: 'Introduction',
                      content: 'HIVE ("we", "our", or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and share your information when you use our platform.',
                    ),
                    
                    // Privacy content sections
                    _buildPolicySection(
                      title: '1. Information We Collect',
                      content: 'We collect information you provide directly (name, email, profile data), activity data (posts, messages, interactions), and technical data (device info, IP address, usage patterns).',
                    ),
                    _buildPolicySection(
                      title: '2. How We Use Your Information',
                      content: 'We use your information to provide and improve our services, personalize your experience, communicate with you, and ensure platform safety and security.',
                    ),
                    _buildPolicySection(
                      title: '3. Data Storage and Security',
                      content: 'Your information is stored on secure servers with encryption. We implement appropriate technical measures to protect your personal data against unauthorized access or disclosure.',
                    ),
                    _buildPolicySection(
                      title: '4. Information Sharing',
                      content: 'We may share your information with other users as part of the platform functionality, service providers who help us operate the platform, and when required by law or to protect rights.',
                    ),
                    _buildPolicySection(
                      title: '5. Your Privacy Rights',
                      content: 'Depending on your location, you may have rights to access, correct, or delete your personal data. You can also control privacy settings and notifications within the app.',
                    ),
                    _buildPolicySection(
                      title: '6. Cookies and Tracking',
                      content: 'We use cookies and similar technologies to enhance your experience, remember preferences, and collect usage data to improve our services.',
                    ),
                    _buildPolicySection(
                      title: '7. Third-Party Links',
                      content: 'Our platform may include links to third-party websites or services. We are not responsible for the privacy practices of these third parties.',
                    ),
                    _buildPolicySection(
                      title: '8. Changes to This Policy',
                      content: 'We may update this Privacy Policy from time to time. We will notify you of significant changes by email or through the app.',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // External privacy policy link
                    GestureDetector(
                      onTap: _openExternalPrivacyPolicy,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.dark3.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.launch,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'View complete Privacy Policy online',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact information
                    Text(
                      'Privacy-related questions should be sent to privacy@hiveapp.com',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withOpacity(0.7),
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
                        value: _acceptedPrivacyPolicy,
                        onChanged: (value) {
                          setState(() {
                            _acceptedPrivacyPolicy = value ?? false;
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
                          'I have read and agree to the Privacy Policy',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
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
                              style: AppTextStyles.labelLarge.copyWith(
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

  /// Build a section of the privacy policy with title and content
  Widget _buildPolicySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 