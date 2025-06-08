import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/widgets/hive_secondary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simplified callback, parent determines onboarding status after success.
typedef SocialAuthResultCallback = void Function(bool success, String message);

/// Enum representing different social authentication providers
enum SocialAuthProvider {
  /// Google authentication
  google,
  
  /// Apple authentication
  apple,
  
  /// Facebook authentication
  facebook,
  
  /// X (Twitter) authentication
  x
}

/// A HIVE-styled button for social authentication methods.
class SocialAuthButton extends ConsumerStatefulWidget {
  /// The social provider to use
  final SocialAuthProvider provider;

  /// Callback when auth is complete
  final SocialAuthResultCallback? onAuthResult;
  
  /// The path to return to after successful authentication
  final String? returnToPath;

  /// Constructor
  const SocialAuthButton({
    super.key,
    required this.provider,
    this.onAuthResult,
    this.returnToPath,
  });

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
      case SocialAuthProvider.apple:
        return kIsWeb ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;
      case SocialAuthProvider.facebook:
      case SocialAuthProvider.x:
        return kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
    }
  }

  Future<void> _handleSignIn() async {
    if (!_isSupported) {
      widget.onAuthResult?.call(false, '${widget.provider.name} Sign-In is not supported on this platform.');
      return;
    }

    setState(() => _isLoading = true);
    FeedbackUtil.buttonTap(); // Haptic for tap

    try {
      // Store return path before initiating auth flow (especially for web)
      if (widget.returnToPath != null && widget.returnToPath!.isNotEmpty) {
        await UserPreferencesService.setSocialAuthRedirectPath(widget.returnToPath!);
      }

      // Call the appropriate repository method based on provider
      switch (widget.provider) {
        case SocialAuthProvider.google:
          await ref.read(authRepositoryProvider).signInWithGoogle();
          break;
        case SocialAuthProvider.apple:
          await ref.read(authRepositoryProvider).signInWithApple();
          break;
        case SocialAuthProvider.facebook:
        case SocialAuthProvider.x:
          // Not implemented yet
          throw UnimplementedError('${widget.provider.name} sign-in is not yet implemented');
      }

      // The repository handles profile creation/login time updates.
      // We just need to report success back to the parent.
      if (mounted) {
        widget.onAuthResult?.call(true, '${widget.provider.name} sign-in successful');
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        FeedbackUtil.error(); // Haptic feedback
        String errorMessage = _mapFirebaseAuthError(e.code);
        widget.onAuthResult?.call(false, errorMessage);
      }
    } catch (e) {
      // Handle other errors (popup closed, network, etc.)
       if (mounted) {
         FeedbackUtil.error();
         String errorMessage = 'Sign-in failed. Please try again.';
         if (e.toString().contains('popup_closed_by_user') || e.toString().contains('cancelled')) {
           errorMessage = 'Sign-in cancelled.';
         } else if (e.toString().contains('network_error')) {
            errorMessage = 'Network error. Please check connection.';
         }
          widget.onAuthResult?.call(false, errorMessage);
       }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper to map common Firebase Auth errors
  String _mapFirebaseAuthError(String code) {
     switch (code) {
       case 'account-exists-with-different-credential':
         return 'An account already exists with the same email address using a different sign-in method.';
       case 'invalid-credential':
         return 'Invalid credential provided.';
       case 'operation-not-allowed':
         return 'Sign-in method is not enabled.';
       case 'user-disabled':
         return 'This user account has been disabled.';
       case 'user-not-found': // Should not happen with social normally
         return 'User not found.';
       case 'network-request-failed':
          return 'Network error. Please check connection.';
       default:
         return 'Authentication failed. Please try again.';
     }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;

    switch (widget.provider) {
      case SocialAuthProvider.google:
        buttonText = 'Continue with Google';
        break;
      case SocialAuthProvider.apple:
        buttonText = 'Continue with Apple';
        break;
      case SocialAuthProvider.facebook:
        buttonText = 'Continue with Facebook';
        break;
      case SocialAuthProvider.x:
        buttonText = 'Continue with X';
        break;
    }

    // Use HiveSecondaryButton - assuming text only for now
    return HiveSecondaryButton(
      text: buttonText,
      onPressed: _isLoading ? null : _handleSignIn,
      isLoading: _isLoading,
      isFullWidth: true,
    );
  }

  Widget _buildIcon() {
    // Remove unused variable
    // final IconData iconData;
    
    switch (widget.provider) {
      case SocialAuthProvider.google:
        return Image.asset(
          'assets/images/google_logo.png',
          width: 24,
          height: 24,
        );
      case SocialAuthProvider.facebook:
        return Image.asset(
          'assets/images/facebook_logo.png',
          width: 24,
          height: 24,
        );
      case SocialAuthProvider.apple:
        return Image.asset(
          'assets/images/apple_logo.png',
          width: 24,
          height: 24,
          color: Colors.white,
        );
      case SocialAuthProvider.x:
        return Image.asset(
          'assets/images/twitter_logo.png',
          width: 24,
          height: 24,
        );
    }
  }
}
