import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/core/theme/app_typography.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

class PasskeyManagementScreen extends ConsumerStatefulWidget {
  const PasskeyManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasskeyManagementScreen> createState() => _PasskeyManagementScreenState();
}

class _PasskeyManagementScreenState extends ConsumerState<PasskeyManagementScreen> {
  bool _isSupported = false;
  bool _isLoading = true;
  bool _hasPasskey = false;

  @override
  void initState() {
    super.initState();
    _checkPasskeySupport();
  }

  Future<void> _checkPasskeySupport() async {
    try {
      final isSupported = await ref.read(authRepositoryProvider).isPasskeySupported();
      
      // In a real implementation, we would check if the user has registered passkeys
      // This is a placeholder - in a complete implementation we would have a method
      // to check if the current user has a passkey registered
      final user = ref.read(currentUserProvider);
      final hasPasskey = user.isNotEmpty; // Placeholder logic
      
      if (mounted) {
        setState(() {
          _isSupported = isSupported;
          _isLoading = false;
          _hasPasskey = hasPasskey;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSupported = false;
          _isLoading = false;
        });
        FeedbackUtil.showToast(
          context: context, 
          message: 'Error checking passkey support: ${e.toString()}', 
          isError: true
        );
      }
    }
  }

  Future<void> _registerPasskey() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = ref.read(currentUserProvider);
      if (user.isEmpty || user.email.isEmpty) {
        if (mounted) {
          FeedbackUtil.showToast(
            context: context, 
            message: 'You must be logged in with an email account to register a passkey',
            isError: true
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      await ref.read(authRepositoryProvider).registerWithPasskey(user.email);
      HapticFeedbackManager().mediumImpact();
      
      if (mounted) {
        setState(() {
          _hasPasskey = true;
          _isLoading = false;
        });
        
        FeedbackUtil.showToast(
          context: context, 
          message: 'Passkey registered successfully',
          isError: false
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        FeedbackUtil.showToast(
          context: context, 
          message: 'Failed to register passkey: ${e.toString()}',
          isError: true
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: const HiveAppBar(
        title: 'Passkey Security',
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passkey Authentication',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Passkeys provide a more secure way to sign in without passwords. They use biometric verification like Face ID or fingerprint.',
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!_isSupported) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your device does not support passkeys yet. Passkeys require iOS 16+, Android 14+, or a modern web browser.',
                              style: AppTypography.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (_hasPasskey) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Passkey Active',
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can now sign in using your device biometrics.',
                                    style: AppTypography.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          // In a complete implementation, we would have a method to delete a passkey
                          FeedbackUtil.showToast(
                            context: context, 
                            message: 'Passkey removal not implemented in this version',
                            isError: false
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Remove Passkey'),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: _isLoading ? null : _registerPasskey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Register New Passkey'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You'll be asked to confirm with your device's security method (Face ID, fingerprint, or PIN).",
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                  const Spacer(),
                  Text(
                    'Note: Passkeys are stored securely on your device and synced through your Apple or Google account. They cannot be phished and provide stronger security than passwords.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 