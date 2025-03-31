import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Callback for authentication results
typedef SocialAuthResultCallback = void Function(
    bool success, String message, bool needsOnboarding);

/// Enum representing different social authentication providers
enum SocialAuthProvider {
  /// Google authentication
  google,

  /// Future providers can be added here
}

/// A button for social authentication methods
class SocialAuthButton extends ConsumerStatefulWidget {
  /// The social provider to use
  final SocialAuthProvider provider;

  /// Callback when auth is complete
  final SocialAuthResultCallback? onAuthResult;

  /// Constructor
  const SocialAuthButton({
    Key? key,
    required this.provider,
    this.onAuthResult,
  }) : super(key: key);

  @override
  ConsumerState<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends ConsumerState<SocialAuthButton> {
  bool _isLoading = false;

  // Check if the platform is supported for this provider
  bool get _isSupported {
    switch (widget.provider) {
      case SocialAuthProvider.google:
        return kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_isSupported) {
      widget.onAuthResult?.call(
          false,
          'Google Sign-In is not supported on this platform. Please use email/password sign-in instead.',
          false);
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

      // Check for new user by examining creation vs last sign in time
      final firebaseAuth = FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;

      bool isNewUser = false;
      if (currentUser != null) {
        final metadata = currentUser.metadata;
        // If creation time and last sign-in time are close, this is likely a new user
        isNewUser = metadata.creationTime != null &&
            metadata.lastSignInTime != null &&
            metadata.creationTime!
                    .difference(metadata.lastSignInTime!)
                    .inSeconds
                    .abs() <
                10;

        // Store email in preferences for reference
        if (currentUser.email != null) {
          await UserPreferencesService.saveUserEmail(currentUser.email!);
        }
      }

      if (isNewUser) {
        // For new accounts, ensure onboarding status is reset
        await UserPreferencesService.resetOnboardingStatus();
      } else if (currentUser != null) {
        // For returning users, automatically mark onboarding as completed if not set
        if (!UserPreferencesService.hasCompletedOnboarding()) {
          await UserPreferencesService.setOnboardingCompleted(true);
        }
      }

      // Call the callback with success
      if (mounted) {
        widget.onAuthResult?.call(true, 'Google sign-in successful',
            isNewUser || !UserPreferencesService.hasCompletedOnboarding());
      }
    } catch (e) {
      // Handle errors
      String errorMessage = 'Google sign-in failed';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? 'Authentication failed';
      } else if (e.toString().contains('popup_closed')) {
        errorMessage = 'Sign-in was cancelled';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection';
      }

      // Provide haptic feedback for error
      HapticFeedback.vibrate();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Call the callback with failure
        widget.onAuthResult?.call(false, errorMessage, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Properties depend on the provider type
    String buttonText;
    IconData icon;
    Color buttonColor;
    Color textColor;
    VoidCallback? onPressed;

    switch (widget.provider) {
      case SocialAuthProvider.google:
        buttonText = defaultTargetPlatform == TargetPlatform.windows && !kIsWeb
            ? 'Google Sign-In (Limited Support)'
            : 'Continue with Google';
        icon = Icons.g_mobiledata_rounded;
        buttonColor = AppColors.black;
        textColor = AppColors.white;
        onPressed = _isLoading ? null : _handleGoogleSignIn;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: buttonColor,
        ),
        icon: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              )
            : Icon(
                icon,
                color: AppColors.gold,
                size: 24,
              ),
        label: Text(
          buttonText,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
