import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/firebase_init_tracker.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/pages/onboarding_profile.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;
  String? _emailError;
  String? _emailTierNote;
  Color _emailTierColor = AppColors.warning;

  // Check if running on Windows platform
  final bool _isWindowsPlatform =
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

        // Show helpful guidance for different email types
        if (email.toLowerCase().endsWith('buffalo.edu')) {
          _emailTierNote = 'Buffalo.edu emails get full verified access';
          _emailTierColor = AppColors.success;
        } else if (email.toLowerCase().endsWith('.edu')) {
          _emailTierNote = 'Educational emails can be verified after signup';
          _emailTierColor = AppColors.gold;
        } else if (email.toLowerCase().contains('gmail.com')) {
          _emailTierNote = 'Gmail users limited to public tier access';
          _emailTierColor = AppColors.warning;
        } else {
          _emailTierNote = 'This email will have public tier access only';
          _emailTierColor = AppColors.warning;
        }
      }
    });
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;
    String text = '';
    Color color = Colors.grey;

    if (password.isEmpty) {
      text = '';
    } else if (password.length < 8) {
      strength = 0.2;
      text = 'Too short';
      color = AppColors.error;
    } else {
      if (password.length >= 8) strength += 0.2;
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

      if (strength <= 0.4) {
        text = 'Weak';
        color = AppColors.error;
      } else if (strength <= 0.7) {
        text = 'Medium';
        color = AppColors.warning;
      } else {
        text = 'Strong';
        color = AppColors.success;
      }
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
  }

  Future<void> _handleCreateAccount() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      return;
    }

    if (_emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid email address',
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_passwordStrength < 0.6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose a stronger password',
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Passwords do not match',
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check if it's a buffalo.edu email
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isBuffaloEmail = email.toLowerCase().endsWith('buffalo.edu');
    final isEduEmail = email.toLowerCase().endsWith('.edu');
    final isGmailUser = email.toLowerCase().contains('gmail.com');

    try {
      // Initialize preferences
      await UserPreferencesService.initialize();

      // For new accounts, ensure onboarding status is reset (set to false)
      await UserPreferencesService.resetOnboardingStatus();

      // Store the user's email to be used during onboarding
      debugPrint('Saving user email: $email');
      await UserPreferencesService.saveUserEmail(email);

      // Success haptic feedback before showing any messages
      HapticFeedback.mediumImpact();

      // Create account using Firebase
      debugPrint('Creating Firebase account...');
      
      // Ensure Firebase is initialized before creating account
      try {
        // Check the tracker first
        if (!FirebaseInitTracker.isInitialized && defaultTargetPlatform != TargetPlatform.windows) {
          debugPrint('Firebase not initialized in create account page, initializing now...');
          await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
          
          if (Firebase.apps.isNotEmpty) {
            FirebaseInitTracker.isInitialized = true;
            FirebaseInitTracker.needsInitialization = false;
            debugPrint('Firebase initialized successfully from create account page');
          } else {
            throw 'Failed to initialize Firebase';
          }
        } else {
          debugPrint('Firebase already initialized: ${FirebaseInitTracker.isInitialized}');
        }
      } catch (e) {
        debugPrint('Error initializing Firebase in create account page: $e');
        throw 'Could not initialize Firebase. Please restart the app and try again.';
      }
      
      await ref
          .read(authControllerProvider.notifier)
          .createUserWithEmailPassword(
            email,
            password,
          );

      debugPrint('Firebase account created successfully');

      // Instead of polling, add a small delay to allow Riverpod state to update
      await Future.delayed(const Duration(milliseconds: 300)); 

      // Check currentUser status via the provider *if necessary* for logic like email verification
      // Reading the auth state provider once after the controller action
      final updatedAuthState = ref.read(authStateProvider);
      final currentUser = updatedAuthState.valueOrNull; // Safely get AuthUser or null

      if (currentUser != null && currentUser.isNotEmpty) { // Check if user is not empty
        debugPrint(
            'Firebase user confirmed via provider: ${currentUser.id}'); // Use id from AuthUser

        // For email verification (using the currentUser obtained via provider)
        if (isEduEmail && !isBuffaloEmail) {
          try {
            // Call the controller method to send verification
            await ref.read(authControllerProvider.notifier).sendEmailVerification();
            debugPrint('Verification email requested for ${currentUser.email}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Verification email sent to ${currentUser.email}', // Use email from AuthUser
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error sending verification email: $e');
          }
        }
      } else {
        debugPrint(
            'WARNING: Firebase user still null after waiting. This may cause issues in onboarding.');
      }

      // Show a success message to improve user experience
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created successfully! Setting up your profile...',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Brief delay to allow the success message to be seen
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint(
          'Account creation process completed. Redirecting to onboarding...');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Add transition feedback before navigating to onboarding
        NavigationTransitions.applyNavigationFeedback(
          type: NavigationFeedbackType.modalOpen,
        );

        // New users always go to onboarding
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Error in account creation process: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        bool isRecoverable = true;

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'An account already exists with this email';
              break;
            case 'weak-password':
              errorMessage = 'Password is too weak. Use at least 6 characters';
              break;
            case 'invalid-email':
              errorMessage = 'Invalid email format';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection and try again';
              break;
            default:
              errorMessage = e.message ?? 'Authentication failed';
          }
        } else if (e.toString().contains('Failed to create user profile')) {
          errorMessage = 'Account created but profile setup failed. Please try logging in.';
          isRecoverable = true;
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }

        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isRecoverable) ...[
                  const SizedBox(height: 4),
                  Text(
                    'You can try logging in with your credentials',
                    style: GoogleFonts.inter(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: isRecoverable
                ? SnackBarAction(
                    label: 'Login',
                    textColor: AppColors.white,
                    onPressed: () {
                      context.go('/login');
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Check platform support before attempting sign-in
    final bool isSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isSupported) {
      debugPrint(
          'Google Sign-In is not supported on ${defaultTargetPlatform.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In is not supported on this platform. Please use email/password sign-in instead.',
            style: GoogleFonts.inter(
              color: AppColors.white,
            ),
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: AppColors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Success haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Initialize preferences if not already
      await UserPreferencesService.initialize();

      // Sign in with Google using Firebase
      await ref.read(authControllerProvider.notifier).signInWithGoogle();

      // Add a small delay to allow Riverpod state to update
      await Future.delayed(const Duration(milliseconds: 300)); 

      // Re-read the auth state provider to get the latest user status
      final updatedAuthState = ref.read(authStateProvider);
      final currentUserFromGoogle = updatedAuthState.valueOrNull;

      if (currentUserFromGoogle == null) {
        debugPrint(
            'Warning: Firebase user still null after Google sign-in (checked via provider).');
        // Keep existing recovery logic for Windows if desired
        if (defaultTargetPlatform == TargetPlatform.windows) {
            debugPrint(
                'Attempting Windows-specific recovery for Google sign-in...');
            await Future.delayed(const Duration(seconds: 1));
            // Check one more time after a longer delay
            final finalAuthState = ref.read(authStateProvider);
            if (finalAuthState.valueOrNull != null) {
                 debugPrint('Delayed recovery successful, user found after wait');
             } else {
                 debugPrint('Recovery failed, user still null after extended wait');
             }
         }
         // Potentially throw error or show message if still null?
      } else {
        debugPrint(
            'Google sign-in confirmed via provider: ${currentUserFromGoogle.id}'); // Use id from AuthUser

        // Store email in preferences for reference
        if (currentUserFromGoogle.email != null) {
          await UserPreferencesService.saveUserEmail(
              currentUserFromGoogle.email!);
        }
      }

      // Check if this is a new account or existing
      final user = ref.read(currentUserProvider);
      
      // Simpler approach to detect new users that avoids null safety issues
      bool isNewUser = false;
      
      // Method 1: Based on creation time (if available)
      final createdAt = user.createdAt;
      if (createdAt != null) {
        final creationTimeSeconds = createdAt.difference(DateTime.now()).inSeconds.abs();
        if (creationTimeSeconds < 30) {
          isNewUser = true;
          debugPrint('New user detection - Based on creation time: true (created $creationTimeSeconds seconds ago)');
        }
      }
      
      // Method 2: Check if we have no saved user ID
      final savedUserId = UserPreferencesService.getUserIdSync();
      if (savedUserId == '') {
        // We don't have a saved user ID but we have a current user
        final currentUserId = user.id ?? '';
        if (currentUserId != '') {
          isNewUser = true;
          debugPrint('New user detection - No saved user ID: true');
        }
      }
      
      // Skip Method 3 since AuthUser doesn't have isNewUser property
      
      debugPrint('Final new user detection result: $isNewUser');

      if (isNewUser) {
        // For new accounts, ensure onboarding status is reset
        debugPrint('New account detected! Resetting onboarding status...');
        await UserPreferencesService.resetOnboardingStatus();
        
        // Save user ID to help with future new user detection
        await UserPreferencesService.saveUserId(user.id);
        
        // Verify reset was successful 
        final onboardingStatus = UserPreferencesService.hasCompletedOnboarding();
        debugPrint('Verification: Onboarding status after reset: $onboardingStatus (should be false)');
        
        // Safety check - force reset again if needed
        if (onboardingStatus == true) {
          debugPrint('WARNING: Onboarding reset failed. Trying again with force flag...');
          await UserPreferencesService.forceResetOnboardingStatus();
        }
        
        debugPrint('New Google account detected. Redirecting to onboarding...');
      } else {
        debugPrint('Existing account detected. Will go to home screen.');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Add appropriate navigation feedback based on destination
        NavigationTransitions.applyNavigationFeedback(
          type: isNewUser
              ? NavigationFeedbackType.modalOpen
              : NavigationFeedbackType.pageTransition,
        );

        // Navigate based on user state
        if (isNewUser) {
          // Add a small delay to ensure preferences are saved
          await Future.delayed(const Duration(milliseconds: 200));
          
          // New users go to onboarding - use pushReplacement for more reliable navigation
          debugPrint('Navigating to onboarding page...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingProfilePage()),
            (route) => false, // Remove all routes underneath
          );
        } else {
          // Existing users go to home
          context.go('/home');
        }
      }
    } catch (e) {
      debugPrint('Error in Google sign-in process: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Google sign-in failed';

        // Provide more specific error messages based on the error type
        if (e.toString().contains('not supported on this platform')) {
          errorMessage =
              'Google Sign-In is not supported on this platform. Please use email/password sign-in instead.';
        } else if (e.toString().contains('sign_in_canceled') ||
            e.toString().contains('sign-in was cancelled')) {
          errorMessage = 'Google Sign-In was canceled';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error during sign-in. Please check your internet connection.';
        } else if (e.toString().contains('popup_closed') ||
            e.toString().contains('popup closed')) {
          errorMessage = 'Sign-in window was closed before completion.';
        } else if (e.toString().contains('credential_already_in_use')) {
          errorMessage =
              'This Google account is already linked to another user.';
        } else if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'account-exists-with-different-credential':
              errorMessage =
                  'An account already exists with the same email but different sign-in method.';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled.';
              break;
            default:
              errorMessage = e.message ?? 'Authentication failed';
          }
        }

        // For Windows platform, provide extra context
        if (defaultTargetPlatform == TargetPlatform.windows && !kIsWeb) {
          errorMessage +=
              ' Note: Google Sign-In has limited support on Windows.';
        }

        final bool isUserCancellation = errorMessage.contains('canceled') ||
            errorMessage.contains('closed');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.inter(
                color: AppColors.white,
              ),
            ),
            backgroundColor:
                isUserCancellation ? AppColors.warning : AppColors.error,
            duration: Duration(seconds: isUserCancellation ? 2 : 4),
          ),
        );
      }
    }
  }

  InputDecoration _getInputDecoration(String label, IconData icon,
      {String? errorText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: AppColors.white.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.white.withOpacity(0.7)),
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1),
      ),
      errorText: errorText,
      errorStyle: GoogleFonts.inter(
        color: AppColors.error,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBarBuilder.buildAuthAppBar(
        context,
        onBackPressed: () {
          // Add transition feedback before navigation
          HapticFeedback.lightImpact();
          context.pop();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    Hero(
                      tag: 'auth_logo',
                      child: Image.asset(
                        'assets/images/hivelogo.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the HIVE community',
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Email Field
              TextField(
                controller: _emailController,
                style: GoogleFonts.inter(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Colors.white70),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _emailController.clear();
                              _emailTierNote = null;
                            });
                          },
                        )
                      : null,
                  labelStyle: GoogleFonts.inter(color: Colors.white70),
                  hintStyle: GoogleFonts.inter(color: Colors.white30),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  errorText: _emailError,
                  filled: true,
                  fillColor: Colors.black45,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  _validateEmail();
                },
              ),
              // Show email tier guidance if available
              if (_emailTierNote != null &&
                  _emailController.text.isNotEmpty &&
                  _emailError == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Row(
                    children: [
                      Icon(
                        _emailController.text
                                .toLowerCase()
                                .endsWith('buffalo.edu')
                            ? Icons.verified
                            : Icons.info_outline,
                        size: 16,
                        color: _emailTierColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emailTierNote!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _emailTierColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: _passwordController,
                style: GoogleFonts.inter(color: AppColors.white),
                obscureText: !_isPasswordVisible,
                decoration: _getInputDecoration('Password', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Password Strength Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _passwordStrengthColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _passwordStrengthText,
                      style: GoogleFonts.inter(
                        color: _passwordStrengthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                style: GoogleFonts.inter(color: AppColors.white),
                obscureText: !_isConfirmPasswordVisible,
                decoration:
                    _getInputDecoration('Confirm Password', Icons.lock_outline)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.white.withOpacity(0.7),
                    ),
                    onPressed: () => setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Create Account Button
              Hero(
                tag: 'primary_auth_button',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.buttonText,
                      disabledBackgroundColor:
                          AppColors.buttonPrimary.withOpacity(0.38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.buttonText),
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.buttonText,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.divider,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.divider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Google Sign In Button
              Hero(
                tag: 'google_auth_button',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : defaultTargetPlatform == TargetPlatform.windows &&
                                !kIsWeb
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Google Sign-In is not fully supported on Windows. Please use email/password instead.',
                                      style: GoogleFonts.inter(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.warning,
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: AppColors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: AppColors.white.withOpacity(0.24)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      foregroundColor: AppColors.white,
                    ),
                    icon: Image.asset(
                      'assets/images/google.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      defaultTargetPlatform == TargetPlatform.windows && !kIsWeb
                          ? 'Google Sign-In (Limited Support)'
                          : 'Continue with Google',
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign In Link
              Hero(
                tag: 'auth_toggle_link',
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // Add transition feedback before navigation
                        NavigationTransitions.applyNavigationFeedback();

                        // Use push for smoother transition between auth screens
                        context.push('/sign-in');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                      ),
                      child: Text(
                        'Already have an account? Sign In',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
