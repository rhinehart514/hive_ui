import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/providers/auth_provider.dart' as core_auth;
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/features/auth/data/repositories/social_auth_helpers.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/core/error/error_logger.dart';

/// OAuth Callback Page for handling authentication callbacks from OAuth providers.
/// 
/// # Implementation Overview
/// This page handles authentication callbacks from various OAuth providers, 
/// specifically Google Workspace EDU for educational (.edu) email verification.
/// The page processes the OAuth callback data, validates credentials, and 
/// completes the authentication flow based on the provider type.
/// 
/// # Production Considerations
/// - **Security**: Implements CSRF protection using state parameter validation
/// - **EDU Email Verification**: Validates the email domain to ensure it's an educational institution
/// - **Error Handling**: Comprehensive error handling with specific error messages for different scenarios
/// - **Timeout Handling**: Automatically handles timeouts to prevent UI blocking
/// - **Analytics**: Tracks authentication events for monitoring and analytics
/// - **User Experience**: Provides clear feedback and visual indicators during authentication process
/// 
/// # Production Enhancement TODOs
/// - [ ] Move token exchange to a secure server-side function instead of client-side
/// - [ ] Implement more robust state parameter validation with timestamp expiration
/// - [ ] Enhance MX record validation for international educational institutions
/// - [ ] Add rate limiting to prevent brute force attacks
/// - [ ] Implement proper OAuth token exchange flow instead of direct Firebase credential usage
/// 
/// # Flow Diagram
/// 1. User is redirected from OAuth provider (Google EDU)
/// 2. Page extracts authorization code and state from URL
/// 3. Validates state parameter to prevent CSRF attacks
/// 4. Exchanges authorization code for credentials
/// 5. Validates the email domain for educational verification
/// 6. Creates or updates user profile based on verification
/// 7. Redirects to appropriate next screen based on onboarding status
///
/// # Testing
/// Unit and widget tests for this component focus on:
/// - Authentication callback parsing
/// - Error state handling
/// - Timeout behavior
/// - Navigation flow based on authentication result
class OAuthCallbackPage extends ConsumerStatefulWidget {
  final String provider;

  const OAuthCallbackPage({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  bool _isProcessing = true;
  String? _errorMessage;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupTimeout();
    _processOAuthCallback();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _setupTimeout() {
    // Set a reasonable timeout (15 seconds) for the OAuth process
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Authentication timed out. Please try again.';
        });
        AnalyticsService.logEvent('oauth_timeout', parameters: {
          'provider': widget.provider,
        });
      }
    });
  }

  Future<void> _processOAuthCallback() async {
    try {
      // Extract necessary data from URL (code, state, etc.)
      final state = GoRouterState.of(context);
      final queryParams = state.uri.queryParameters;
      final code = queryParams['code'];
      final stateParam = queryParams['state'];
      final error = queryParams['error'];
      
      // Handle OAuth error parameter if present
      if (error != null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Authentication failed: $error';
        });
        
        AnalyticsService.logEvent('oauth_callback_error', parameters: {
          'provider': widget.provider,
          'error': error,
        });
        return;
      }
      
      if (code == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Authentication failed: Missing authorization code';
        });
        
        AnalyticsService.logEvent('oauth_callback_missing_code', parameters: {
          'provider': widget.provider,
        });
        return;
      }

      // Process the OAuth callback based on provider
      if (widget.provider == 'google-edu') {
        await _processGoogleEduCallback(code, stateParam);
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Unsupported OAuth provider: ${widget.provider}';
        });
        
        AnalyticsService.logEvent('oauth_unsupported_provider', parameters: {
          'provider': widget.provider,
        });
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'OAuth callback processing error',
        error: e,
        stackTrace: stackTrace,
        context: {'provider': widget.provider},
      );
      
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
      
      AnalyticsService.logEvent('oauth_callback_exception', parameters: {
        'provider': widget.provider,
        'error': e.toString(),
      });
    }
  }

  Future<void> _processGoogleEduCallback(String code, String? stateParam) async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final firestore = FirebaseFirestore.instance;
      
      debugPrint('Processing Google EDU OAuth callback with code');
      
      // In a production environment, we would exchange the auth code for tokens server-side
      // This is a simplified client-side implementation
      
      // First, validate the state parameter to prevent CSRF attacks
      if (stateParam == null || !SocialAuthHelpers.verifyOAuthState(stateParam)) {
        throw Exception('Invalid OAuth state parameter');
      }
      
      // Exchange the authorization code for Firebase credentials
      // NOTE: In a production environment, this should be done server-side with proper OAuth flow
      // For demo purposes, we're using the code directly (not recommended for production)
      final credential = GoogleAuthProvider.credential(
        idToken: code, // In real implementation, exchange code for tokens first
        accessToken: null,
      );
      
      // Sign in with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Authentication request timed out');
      });
      
      final user = userCredential.user;
      
      if (user != null) {
        // Extract and validate the educational email
        final userData = SocialAuthHelpers.extractUserDataForEduVerification(user);
        final isEduEmail = userData['isEduEmail'] as bool;
        
        // Only proceed if this is an educational email
        if (!isEduEmail) {
          // Sign out if not an educational email
          await FirebaseAuth.instance.signOut();
          throw 'Please use your .edu school email for verification.';
        }
        
        // Attempt to validate the educational domain through additional checks
        try {
          final isValidDomain = await SocialAuthHelpers.validateEmailMXRecord(user.email ?? '');
          if (!isValidDomain) {
            debugPrint('Warning: MX record validation failed for ${user.email}');
            // Log this event but don't block sign-in if the basic .edu check passed
            AnalyticsService.logEvent('edu_domain_mx_validation_failed', parameters: {
              'email_domain': userData['domain'],
            });
          }
        } catch (e) {
          // Log the error but continue with the authentication process
          debugPrint('MX record validation error: $e');
        }
        
        // Update the user's profile with educational verification
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // This is a new user, create profile
          try {
            await SocialAuthHelpers.mergeSocialProfileData(
              user: user,
              socialData: userData,
              firestore: firestore,
              createUserProfile: (user) async {
                final userDocRef = firestore.collection('users').doc(user.uid);
                await userDocRef.set({
                  'id': user.uid,
                  'email': user.email,
                  'displayName': user.displayName ?? 'New User',
                  'profileImageUrl': user.photoURL,
                  'isEmailVerified': true,
                  'accountTier': AccountTier.verified.name,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'providers': ['google-edu'],
                  'eduVerified': true,
                  'eduDomain': userData['domain'],
                }, SetOptions(merge: true));
              },
              saveUserProfileLocally: (user) async {
                // Cache user profile locally
                final profile = UserProfile(
                  id: user.uid,
                  username: user.displayName ?? 'User ${user.uid.substring(0, 4)}',
                  displayName: user.displayName ?? 'New User',
                  email: user.email,
                  profileImageUrl: user.photoURL,
                  bio: '',
                  year: 'Freshman',
                  major: 'Undecided',
                  residence: 'Off Campus',
                  eventCount: 0,
                  spaceCount: 0,
                  friendCount: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  accountTier: AccountTier.verified,
                  interests: const [],
                );
                
                await UserPreferencesService.storeProfile(profile);
              },
            );
          } catch (e, stackTrace) {
            ErrorLogger.logError(
              'Error creating profile during Google EDU sign-in',
              error: e,
              stackTrace: stackTrace,
              context: {'userId': user.uid},
            );
            // Continue with authentication even if profile creation had issues
            // The user can update their profile later
          }
        } else {
          // Existing user, update verification status
          try {
            await firestore.collection('users').doc(user.uid).update({
              'isEmailVerified': true,
              'accountTier': AccountTier.verified.name,
              'updatedAt': FieldValue.serverTimestamp(),
              'eduVerified': true,
              'eduDomain': userData['domain'],
              'lastSignInAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Error updating user verification status: $e');
            // Non-blocking error, continue with sign-in
          }
        }
        
        // Log analytics event
        AnalyticsService.logEvent('oauth_callback_processed', parameters: {
          'provider': 'google-edu',
          'success': 'true',
          'isEduEmail': isEduEmail.toString(),
          'isNewUser': (userCredential.additionalUserInfo?.isNewUser ?? false).toString(),
          'domain': userData['domain'] ?? 'unknown',
        });
      
        if (mounted) {
          // Cancel the timeout timer
          _timeoutTimer?.cancel();
          
          FeedbackUtil.success();
          
          // Check if user needs onboarding
          final currentUser = ref.read(core_auth.currentUserProvider);
          final needsOnboarding = !UserPreferencesService.hasCompletedOnboarding();
          
          // Navigate to the appropriate page
          context.go(needsOnboarding ? '/onboarding/access-pass' : '/home');
        }
      } else {
        throw Exception('Failed to authenticate with Google EDU');
      }
    } catch (e, stackTrace) {
      if (e is FirebaseAuthException) {
        // Handle specific Firebase Auth errors
        String errorMessage = 'Authentication failed';
        
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = 'An account already exists with a different sign-in method. Please use that method instead.';
            break;
          case 'invalid-credential':
            errorMessage = 'The authentication credential is malformed or has expired.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Google EDU sign-in is not enabled for this application.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          case 'user-not-found':
          case 'wrong-password':
            errorMessage = 'Invalid user credentials.';
            break;
          default:
            errorMessage = 'Authentication error: ${e.message}';
        }
        
        ErrorLogger.logError(
          'Firebase Auth error during Google EDU sign-in',
          error: e,
          stackTrace: stackTrace,
          context: {'errorCode': e.code},
        );
        
        setState(() {
          _isProcessing = false;
          _errorMessage = errorMessage;
        });
      } else if (e is TimeoutException) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Authentication timed out. Please try again.';
        });
      } else {
        ErrorLogger.logError(
          'Unexpected error during Google EDU sign-in',
          error: e,
          stackTrace: stackTrace,
        );
        
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Google EDU authentication failed: ${e.toString()}';
        });
      }
      
      // Sign out the user if authentication failed
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        debugPrint('Error signing out after failed authentication: $signOutError');
      }
      
      // Log analytics event for failure
      AnalyticsService.logEvent('oauth_callback_processed', parameters: {
        'provider': 'google-edu',
        'success': 'false',
        'error': e.toString(),
      });
      
      if (mounted) {
        FeedbackUtil.error();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing your ${widget.provider.replaceAll('-', ' ')} sign-in...',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _errorMessage != null ? Icons.error_outline : Icons.check_circle_outline,
                    size: 64,
                    color: _errorMessage != null ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage ?? 'Authentication successful!',
                      style: TextStyle(
                        color: _errorMessage != null ? AppColors.error : Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
      ),
    );
  }
} 