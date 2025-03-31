import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/core/navigation/transitions.dart';

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

  // Check if running on Windows platform
  final bool _isWindowsPlatform =
      defaultTargetPlatform == TargetPlatform.windows;

  // Enable Windows Safe Mode (bypasses direct Firebase Auth calls on Windows)
  // Change this to false if you want to disable the safe mode
  final bool _useWindowsSafeMode = true;

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
      } else if (email.toLowerCase().contains('gmail.com')) {
        // Gmail users are allowed but will be directed to public tier
        _emailError = null;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
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
      color = Colors.red;
    } else {
      if (password.length >= 8) strength += 0.2;
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

      if (strength <= 0.4) {
        text = 'Weak';
        color = Colors.red;
      } else if (strength <= 0.7) {
        text = 'Medium';
        color = Colors.orange;
      } else {
        text = 'Strong';
        color = const Color(0xFFFFD700);
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
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
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
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.orange,
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
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
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
    final isGmailUser = email.toLowerCase().contains('gmail.com');

    try {
      // Initialize preferences
      await UserPreferencesService.initialize();

      // For new accounts, ensure onboarding status is reset (set to false)
      await UserPreferencesService.resetOnboardingStatus();

      // Store the user's email to be used during onboarding
      debugPrint('Saving user email: $email');
      await UserPreferencesService.saveUserEmail(email);

      // Show appropriate message
      if (!isBuffaloEmail) {
        // Show a note that they'll only have access to public tier
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isGmailUser
                    ? 'Gmail users will only have access to public tier features'
                    : 'Non-Buffalo users will only have access to public tier features',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Success haptic feedback
      HapticFeedback.mediumImpact();

      // Create account using Firebase
      debugPrint('Creating Firebase account...');
      await ref
          .read(authControllerProvider.notifier)
          .createUserWithEmailPassword(
            email,
            password,
          );

      debugPrint('Firebase account created successfully');

      // CRITICAL: Ensure authentication state is fully propagated before continuing
      // This prevents the "No authenticated user found" error during onboarding
      final firebaseAuth = FirebaseAuth.instance;
      int retryCount = 0;

      // Verify that we have a valid Firebase user before proceeding to onboarding
      while (firebaseAuth.currentUser == null && retryCount < 5) {
        debugPrint(
            'Waiting for Firebase auth state to propagate (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (firebaseAuth.currentUser != null) {
        debugPrint(
            'Firebase user confirmed ready for onboarding: ${firebaseAuth.currentUser!.uid}');
      } else {
        debugPrint(
            'WARNING: Firebase user still null after waiting. This may cause issues in onboarding.');
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating account: ${e.toString()}',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
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

      // Wait for Firebase Auth state to propagate
      final firebaseAuth = FirebaseAuth.instance;
      int retryCount = 0;
      while (firebaseAuth.currentUser == null && retryCount < 5) {
        debugPrint(
            'Waiting for Google auth state to propagate (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(milliseconds: 300));
        retryCount++;
      }

      if (firebaseAuth.currentUser == null) {
        debugPrint(
            'Warning: Firebase user still null after Google sign-in. User may need to sign in again.');
      } else {
        debugPrint(
            'Google sign-in confirmed: ${firebaseAuth.currentUser!.uid}');

        // Store email in preferences for onboarding
        if (firebaseAuth.currentUser!.email != null) {
          await UserPreferencesService.saveUserEmail(
              firebaseAuth.currentUser!.email!);
        }
      }

      // Check if this is a new account or existing
      final user = ref.read(currentUserProvider);
      final bool isNewUser =
          user.createdAt.difference(DateTime.now()).inSeconds.abs() < 10;

      if (isNewUser) {
        // For new accounts, ensure onboarding status is reset
        await UserPreferencesService.resetOnboardingStatus();
        debugPrint('New Google account detected. Redirecting to onboarding...');
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
          // New users go to onboarding
          context.go('/onboarding');
        } else {
          // Existing users go to home
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google sign-in failed: ${e.toString()}',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
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
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1),
      ),
      errorText: errorText,
      errorStyle: GoogleFonts.inter(
        color: Colors.red,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Add a subtle transition feedback
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
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
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the HIVE community',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
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
                style: GoogleFonts.inter(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _getInputDecoration(
                    'University Email', Icons.email_outlined,
                    errorText: _emailError),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: _passwordController,
                style: GoogleFonts.inter(color: Colors.white),
                obscureText: !_isPasswordVisible,
                decoration: _getInputDecoration('Password', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
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
                        backgroundColor: Colors.grey.shade800,
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
                style: GoogleFonts.inter(color: Colors.white),
                obscureText: !_isConfirmPasswordVisible,
                decoration:
                    _getInputDecoration('Confirm Password', Icons.lock_outline)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
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
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white38,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                      color: Colors.white24,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white24,
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
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/google.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Continue with Google',
                      style: GoogleFonts.inter(
                        color: Colors.white,
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
                      child: Text(
                        'Already have an account? Sign In',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
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
