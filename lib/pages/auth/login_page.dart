import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:hive_ui/core/navigation/app_bar_builder.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isResetting = false;
  String? _emailError;
  String? _resetEmailError;

  // Check if running on Windows platform
  final bool _isWindowsPlatform =
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _resetEmailController.addListener(_validateResetEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
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

  void _validateResetEmail() {
    final email = _resetEmailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _resetEmailError = null;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _resetEmailError = 'Please enter a valid email address';
      } else {
        _resetEmailError = null;
      }
    });
  }

  Future<void> _handleResetPassword() async {
    if (_resetEmailController.text.isEmpty) return;

    if (_resetEmailError != null) {
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

    setState(() {
      _isResetting = true;
    });

    try {
      // Use the auth controller to send the reset email
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(
            _resetEmailController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _isResetting = false;
        });

        // Add haptic feedback for success
        HapticFeedback.mediumImpact();

        Navigator.pop(context); // Close bottom sheet

        // Show different messages based on email type
        final email = _resetEmailController.text.trim();
        final isBuffaloEmail = email.toLowerCase().endsWith('buffalo.edu');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBuffaloEmail
                  ? 'Password reset link sent to $email'
                  : 'Password reset link sent to $email (Public tier access only)',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.bottomSheetBackground,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      if (mounted) {
        setState(() {
          _isResetting = false;
        });

        // Add haptic feedback for error
        HapticFeedback.vibrate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending reset email: ${e is FirebaseAuthException ? e.message : "Please try again"}',
              style: GoogleFonts.inter(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showResetPasswordSheet() {
    _resetEmailController.text = _emailController.text;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _AnimatedBottomSheet(
          emailController: _resetEmailController,
          isResetting: _isResetting,
          resetEmailError: _resetEmailError,
          onEmailChanged: (_) => setSheetState(() {}),
          onResetPassword: _handleResetPassword,
          getInputDecoration: _getInputDecoration,
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
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

    setState(() {
      _isLoading = true;
    });

    // Success haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Initialize preferences if not already
      await UserPreferencesService.initialize();

      // Store the user's email for reference
      final email = _emailController.text.trim();
      await UserPreferencesService.saveUserEmail(email);

      // Sign in with Firebase
      debugPrint('Signing in with Firebase...');
      await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
            email,
            _passwordController.text,
          );

      debugPrint('Firebase sign-in successful');

      // CRITICAL: Ensure authentication state is fully propagated before continuing
      final firebaseAuth = FirebaseAuth.instance;
      int retryCount = 0;

      // Verify that we have a valid Firebase user before proceeding
      while (firebaseAuth.currentUser == null && retryCount < 5) {
        debugPrint(
            'Waiting for Firebase auth state to propagate (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }

      if (firebaseAuth.currentUser != null) {
        debugPrint('Firebase user confirmed: ${firebaseAuth.currentUser!.uid}');
      } else {
        debugPrint(
            'WARNING: Firebase user still null after waiting. This may cause issues.');
      }

      // Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign in successful!',
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if user has completed onboarding
        final hasCompletedOnboarding =
            UserPreferencesService.hasCompletedOnboarding();
        debugPrint(
            'Sign-in successful, checking onboarding status: $hasCompletedOnboarding');

        // Add navigation feedback
        NavigationTransitions.applyNavigationFeedback(
          type: hasCompletedOnboarding
              ? NavigationFeedbackType.pageTransition
              : NavigationFeedbackType.modalOpen,
        );

        // Navigate to home or onboarding based on user status
        context.go(hasCompletedOnboarding ? '/home' : '/onboarding');
      }
    } catch (e) {
      debugPrint('Error in sign-in process: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Invalid email or password';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No account found with this email';
              break;
            case 'wrong-password':
              errorMessage = 'Incorrect password';
              break;
            case 'invalid-credential':
              errorMessage = 'Invalid login credentials';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later';
              break;
            default:
              errorMessage = e.message ?? 'Authentication failed';
          }
        }

        // Provide haptic feedback for error
        HapticFeedback.vibrate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.inter(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.error,
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
            'Warning: Firebase user still null after Google sign-in. Attempting recovery...');

        // Additional recovery attempt for Windows platforms
        if (defaultTargetPlatform == TargetPlatform.windows) {
          debugPrint(
              'Attempting Windows-specific recovery for Google sign-in...');
          await Future.delayed(const Duration(seconds: 1));

          // Check one more time after a longer delay
          if (firebaseAuth.currentUser != null) {
            debugPrint('Delayed recovery successful, user found after wait');
          } else {
            debugPrint('Recovery failed, user still null after extended wait');
          }
        }
      } else {
        debugPrint(
            'Google sign-in confirmed: ${firebaseAuth.currentUser!.uid}');

        // Store email in preferences for reference
        if (firebaseAuth.currentUser!.email != null) {
          await UserPreferencesService.saveUserEmail(
              firebaseAuth.currentUser!.email!);
        }
      }

      // Check if this is a new account or existing
      final user = ref.read(currentUserProvider);
      final bool isNewUser = user.createdAt.difference(DateTime.now()).inSeconds.abs() < 10;

      if (isNewUser) {
        // For new accounts, ensure onboarding status is reset
        await UserPreferencesService.resetOnboardingStatus();
        debugPrint('New Google account detected. Redirecting to onboarding...');
      } else {
        // For returning users, automatically mark onboarding as completed
        if (firebaseAuth.currentUser != null) {
          debugPrint(
              'Returning user detected, marking onboarding as completed');
          await UserPreferencesService.setOnboardingCompleted(true);
        }
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

        // For new users, check if they need onboarding
        final needsOnboarding =
            !UserPreferencesService.hasCompletedOnboarding();

        // Navigate based on user state
        context.go(needsOnboarding ? '/onboarding' : '/home');
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
        destinationRoute: '/',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Title - moved icon outside app bar
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
                      'Welcome Back',
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
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
                keyboardType: TextInputType.emailAddress,
                decoration: _getInputDecoration(
                    'University Email', Icons.email_outlined,
                    errorText: _emailError),
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
              const SizedBox(height: 8),
              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showResetPasswordSheet,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.gold,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Sign In Button
              Hero(
                tag: 'primary_auth_button',
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn,
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
                            'Sign In',
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
              // Create Account Link
              Hero(
                tag: 'auth_toggle_link',
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // Add transition feedback before navigation
                        NavigationTransitions.applyNavigationFeedback();

                        // Use push for smoother transition when navigating between auth screens
                        context.push('/create-account');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                      ),
                      child: Text(
                        'Don\'t have an account? Create one',
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

class _AnimatedBottomSheet extends StatefulWidget {
  final TextEditingController emailController;
  final bool isResetting;
  final String? resetEmailError;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onResetPassword;
  final InputDecoration Function(String, IconData, {String? errorText})
      getInputDecoration;

  const _AnimatedBottomSheet({
    required this.emailController,
    required this.isResetting,
    required this.resetEmailError,
    required this.onEmailChanged,
    required this.onResetPassword,
    required this.getInputDecoration,
  });

  @override
  State<_AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<_AnimatedBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _handleAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _descriptionAnimation;
  late Animation<double> _inputAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Staggered animations with different delays
    _handleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    ));

    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.4, curve: Curves.easeOut),
    ));

    _descriptionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
    ));

    _inputAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
    ));

    // Start the animation when the sheet appears
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle with fade animation
          FadeTransition(
            opacity: _handleAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_handleAnimation),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title with fade and slide animation
          FadeTransition(
            opacity: _titleAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_titleAnimation),
              child: Text(
                'Reset Password',
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Description with fade and slide animation
          FadeTransition(
            opacity: _descriptionAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_descriptionAnimation),
              child: Text(
                'Enter your university email address and we\'ll send you a link to reset your password.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Input field with fade and slide animation
          FadeTransition(
            opacity: _inputAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_inputAnimation),
              child: TextField(
                controller: widget.emailController,
                style: GoogleFonts.inter(color: AppColors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: widget.getInputDecoration(
                  'University Email',
                  Icons.email_outlined,
                  errorText: widget.resetEmailError,
                ),
                onChanged: widget.onEmailChanged,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Button with fade and slide animation
          FadeTransition(
            opacity: _buttonAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_buttonAnimation),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.isResetting ? null : widget.onResetPassword,
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
                  child: widget.isResetting
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
                          'Send Reset Link',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonText,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
