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
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:hive_ui/core/navigation/app_bar_builder.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/core/widgets/branded_text_field.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/theme/dark_surface.dart';

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
  final bool _isPasswordVisible = false;
  final bool _isConfirmPasswordVisible = false;
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;
  String? _emailError;
  String? _emailTierNote;
  Color _emailTierColor = AppColors.warning;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _emailController.addListener(_validateEmail);
    
    // Debug output to help diagnose issues
    debugPrint('CreateAccountPage initialized');
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
        if (email.toLowerCase().endsWith('.edu')) {
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
    debugPrint('Create account button pressed');
    
    // Add haptic feedback when button is pressed (per HIVE UX standards)
    FeedbackUtil.buttonTap();
    
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      FeedbackUtil.error(); // Add error haptic feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all fields',
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

    if (_emailError != null) {
      FeedbackUtil.error(); // Add error haptic feedback
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
      FeedbackUtil.error(); // Add error haptic feedback
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
      FeedbackUtil.error(); // Add error haptic feedback
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

    // Get credentials from form
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Initialize preferences
      await UserPreferencesService.initialize();

      // For new accounts, ensure onboarding status is reset (set to false)
      await UserPreferencesService.resetOnboardingStatus();

      // Store the user's email to be used during onboarding
      debugPrint('Saving user email: $email');
      await UserPreferencesService.saveUserEmail(email);

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
      
      debugPrint('Creating Firebase account...');
      await ref
          .read(authControllerProvider.notifier)
          .createUserWithEmailPassword(
            email,
            password,
          );

      debugPrint('Firebase account created successfully');

      // Instead of polling, add a small delay to allow Riverpod state to update
      await Future.delayed(const Duration(milliseconds: 300)); 

      // Check currentUser status via the provider
      final updatedAuthState = ref.read(authStateProvider);
      final currentUser = updatedAuthState.valueOrNull;

      if (currentUser != null && currentUser.isNotEmpty) {
        debugPrint('Firebase user confirmed via provider: ${currentUser.id}');
        // Success haptic feedback
        FeedbackUtil.success();
        
        // Navigate to onboarding or send email verification
        if (mounted) {
          debugPrint('Navigation triggered to onboarding');
          FeedbackUtil.navigate();
          context.go(AppRoutes.onboarding);
        }
      } else {
        debugPrint('User not available after account creation');
        throw 'Account created but user data unavailable';
      }
    } catch (e) {
      debugPrint('Error during account creation: $e');
      
      // Error haptic feedback
      FeedbackUtil.error();
      
      if (mounted) {
        String errorMessage = 'Failed to create account';
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'Email is already in use';
              break;
            case 'weak-password':
              errorMessage = 'Password is too weak';
              break;
            case 'invalid-email':
              errorMessage = 'Invalid email format';
              break;
            default:
              errorMessage = e.message ?? errorMessage;
          }
        } else if (e is String) {
          errorMessage = e;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
    // Fixed linter warnings by using const when possible
    const spacing = 20.0;
    const outerPadding = 24.0;
    const cardBorderRadius = 16.0;
    const titleSize = 28.0;
    const subtitleSize = 16.0;
    const double buttonHeight = 56.0;
    
    return DarkSurface(
      surfaceType: SurfaceType.canvas,
      withGrainTexture: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBarBuilder.buildAuthAppBar(context),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(outerPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: spacing / 2),
                  const Text(
                    'Join HIVE and connect with your campus community',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: subtitleSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: spacing * 1.5),
                  // Email input field
                  DarkSurface(
                    surfaceType: SurfaceType.glass,
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                    padding: const EdgeInsets.all(spacing),
                    child: Column(
                      children: [
                        BrandedTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (_) => _emailError,
                        ),
                        if (_emailTierNote != null && _emailError == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: _emailTierColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _emailTierNote!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _emailTierColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: spacing),
                        // Password field
                        BrandedTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create a strong password',
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.next,
                        ),
                        // Password strength indicator
                        if (_passwordStrengthText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: _passwordStrength,
                                    backgroundColor: Colors.grey.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _passwordStrengthText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _passwordStrengthColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: spacing),
                        // Confirm password field
                        BrandedTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          obscureText: !_isConfirmPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleCreateAccount(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: spacing * 1.5),
                  // Create account button with better UX for press detection
                  GestureDetector(
                    onTapDown: (_) {
                      // Improves responsiveness - adds immediate feedback
                      debugPrint('Button tap down detected');
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: HivePrimaryButton(
                        text: 'Create Account',
                        onPressed: _isLoading ? null : _handleCreateAccount,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing),
                  // Sign in link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        FeedbackUtil.selection();
                        debugPrint('Sign in button pressed');
                        context.go(AppRoutes.signIn);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 