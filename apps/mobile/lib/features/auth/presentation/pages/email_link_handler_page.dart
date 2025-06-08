import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/analytics_service.dart';

/// Page that handles incoming email magic links
/// 
/// This page is displayed when a user clicks on a magic link in their email
/// It processes the link and signs in the user if valid
class EmailLinkHandlerPage extends ConsumerStatefulWidget {
  /// URI from the deep link that opened the app
  final Uri? uri;
  
  const EmailLinkHandlerPage({
    Key? key,
    this.uri,
  }) : super(key: key);

  @override
  ConsumerState<EmailLinkHandlerPage> createState() => _EmailLinkHandlerPageState();
}

class _EmailLinkHandlerPageState extends ConsumerState<EmailLinkHandlerPage> {
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _processEmailLink();
  }
  
  Future<void> _processEmailLink() async {
    try {
      if (widget.uri == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid sign-in link. Please try signing in again.';
        });
        return;
      }
      
      final link = widget.uri.toString();
      final authRepository = ref.read(authRepositoryProvider);
      
      // Verify this is a valid email sign-in link
      final isValid = await authRepository.isSignInWithEmailLink(link);
      
      if (!isValid) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid sign-in link. Please try signing in again.';
        });
        AnalyticsService.logEvent('email_link_invalid', parameters: {
          'link': link.substring(0, 20), // Only log the start of the link for privacy
        });
        return;
      }
      
      // Get the email from local storage
      final email = UserPreferencesService.getEmailForSignIn();
      
      if (email.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not find email information. Please try signing in again.';
        });
        AnalyticsService.logEvent('email_link_missing_email', parameters: {
          'link': link.substring(0, 20),
        });
        return;
      }
      
      // Attempt sign-in with the link
      final user = await authRepository.signInWithEmailLink(email, link);
      
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication failed. Please try signing in again.';
        });
        AnalyticsService.logEvent('email_link_auth_failed', parameters: {
          'email': email,
          'link': link.substring(0, 20),
        });
        return;
      }
      
      // Check if user needs onboarding
      final needsOnboarding = !UserPreferencesService.hasCompletedOnboarding();
      
      AnalyticsService.logEvent('email_link_auth_success', parameters: {
        'needs_onboarding': needsOnboarding.toString(),
        'user_id': user.uid,
      });
      
      if (mounted) {
        FeedbackUtil.success();
        
        // Navigate to the appropriate screen
        context.go(needsOnboarding ? '/onboarding/access-pass' : '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
        AnalyticsService.logEvent('email_link_error', parameters: {
          'error': e.toString(),
        });
        FeedbackUtil.error();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Verifying your sign-in link...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (_errorMessage != null)
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        FeedbackUtil.buttonTap();
                        context.go('/sign-in');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Return to Sign In'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 