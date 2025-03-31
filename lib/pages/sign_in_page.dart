import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/core/navigation/transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:hive_ui/theme/app_colors.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
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

  // Enable Windows Safe Mode (bypasses direct Firebase Auth calls on Windows)
  // Change this to false if you want to disable the safe mode
  final bool _useWindowsSafeMode = true;

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
          backgroundColor: Colors.red,
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
            backgroundColor: const Color(0xFF1E1E1E),
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
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.transparent,
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
          backgroundColor: Colors.red,
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.inter(
                color: AppColors.white,
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
        if (e is FirebaseAuthException) {
          errorMessage = e.message ?? 'Authentication failed';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.inter(
                color: AppColors.white,
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
        color: AppColors.white.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.white.withOpacity(0.7)),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
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
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () {
                  // Add a subtle transition feedback
                  HapticFeedback.lightImpact();
                  context.go('/');
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
                            'Sign In',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
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
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
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
                      'Continue with Google',
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
        color: Color(0xFF1E1E1E),
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white38,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'Send Reset Link',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
