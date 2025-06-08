import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/features/auth/providers/user_preferences_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy page for the application
/// Shows the full privacy policy from the privacy_policy.md file
class NewPrivacyPolicyPage extends ConsumerStatefulWidget {
  /// Whether this is shown during onboarding (true) or from settings (false)
  final bool isOnboarding;

  /// Optional callback for when privacy policy is accepted
  final VoidCallback? onAccepted;

  /// Contact email for privacy questions
  static const String privacyContactEmail = 'privacy@thehiveuni.com';

  /// Creates a privacy policy page
  const NewPrivacyPolicyPage({
    super.key,
    this.isOnboarding = true,
    this.onAccepted,
  });

  @override
  ConsumerState<NewPrivacyPolicyPage> createState() => _NewPrivacyPolicyPageState();
}

class _NewPrivacyPolicyPageState extends ConsumerState<NewPrivacyPolicyPage> {
  bool _acceptedPrivacyPolicy = false;
  bool _isLoading = false;
  String _policyText = '';

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
    _checkExistingAcceptance();
  }

  /// Load privacy policy from assets
  Future<void> _loadPrivacyPolicy() async {
    try {
      final policyText = await rootBundle.loadString('lib/docs/privacy_policy.md');
      if (mounted) {
        setState(() {
          _policyText = policyText;
        });
      }
    } catch (e) {
      // Fallback to hardcoded summary if file can't be loaded
      if (mounted) {
        setState(() {
          _policyText = '''
# HIVE Privacy Policy

We collect and process your information to provide the HIVE platform. This includes profile data, usage information, and device details. We use this data to personalize your experience, connect you with relevant content, and ensure platform security.

Your information may be shared with other users based on your privacy settings, and with service providers who help us operate the platform. We implement appropriate security measures to protect your data.

You can control your data through account settings, privacy controls, and by managing app permissions. For more information, please contact privacy@thehiveuni.com.
''';
        });
      }
    }
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

  /// Open email client for privacy questions
  Future<void> _contactPrivacyTeam() async {
    final uri = Uri.parse('mailto:${NewPrivacyPolicyPage.privacyContactEmail}?subject=Privacy%20Policy%20Question');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
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
        Navigator.of(context).pop(true); // Return true to indicate acceptance
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

  /// Build a policy section with markdown styling
  Widget _buildMarkdownSection(String text) {
    final lines = text.split('\n');
    List<Widget> widgets = [];
    
    for (final line in lines) {
      if (line.startsWith('# ')) {
        // Main Header
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: Text(
              line.substring(2),
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // Section Header
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
            child: Text(
              line.substring(3),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        // Subsection Header
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              line.substring(4),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        // Bullet points
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('**') && line.endsWith('**')) {
        // Bold text (entire line)
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              line.substring(2, line.length - 2),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        // Empty line
        widgets.add(const SizedBox(height: 8));
      } else {
        // Regular paragraph
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              line,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBarBuilder.buildStandardAppBar(
        context,
        title: 'Privacy Policy',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Privacy content in scrollable area
          Expanded(
            child: _policyText.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildMarkdownSection(_policyText),
                  ),
          ),
          
          // Bottom acceptance section (only shown during onboarding or when needed)
          if (widget.isOnboarding || !_acceptedPrivacyPolicy)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dark2,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox for acceptance
                  CheckboxListTile(
                    title: Text(
                      'I have read and agree to the Privacy Policy',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    value: _acceptedPrivacyPolicy,
                    onChanged: (value) {
                      setState(() {
                        _acceptedPrivacyPolicy = value ?? false;
                      });
                    },
                    activeColor: AppColors.gold,
                    checkColor: AppColors.black,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  // Contact link
                  TextButton(
                    onPressed: _contactPrivacyTeam,
                    child: Text(
                      'Questions? Contact us',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 