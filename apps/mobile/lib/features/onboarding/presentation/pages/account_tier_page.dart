import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_page_scaffold.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// A page that displays information about the user's account tier.
///
/// This is the final page in the onboarding flow and informs the user about
/// their account status based on email verification and domain type.
class AccountTierPage extends ConsumerStatefulWidget {
  /// Creates an instance of [AccountTierPage].
  const AccountTierPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountTierPage> createState() => _AccountTierPageState();
}

class _AccountTierPageState extends ConsumerState<AccountTierPage> {
  bool _isProcessing = false;
  String? _accountTier;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineAccountTier();
    });
  }
  
  Future<void> _determineAccountTier() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      debugPrint("AccountTierPage: Cannot determine tier, user is null.");
      return;
    } 

    String tier = 'public';
    final email = user.email?.toLowerCase();

    if (email != null && email.endsWith('.edu')) {
      await user.reload();
      final freshUser = ref.read(firebaseAuthProvider).currentUser; 
      if (freshUser?.emailVerified == true) {
        tier = 'verified';
      } else {
        tier = 'public';
      }
    }

    if (mounted) {
      setState(() {
        _accountTier = tier;
      });
      
      ref.read(onboardingStateNotifierProvider.notifier).setAccountTier(tier);
    }
  }
  
  Future<void> _sendVerificationEmail() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null || _isProcessing) return;

    setState(() { _isProcessing = true; });

    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent. Check your inbox.'),
            backgroundColor: AppColors.success.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, s) {
      debugPrint("Error sending verification email: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error sending verification email.'),
            backgroundColor: AppColors.error.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }
  
  Future<void> _refreshVerificationStatus() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
     if (user == null || _isProcessing) return;

    setState(() { _isProcessing = true; });

    try {
      await user.reload();
      final refreshedUser = ref.read(firebaseAuthProvider).currentUser;

      if (refreshedUser?.emailVerified == true) {
        await _determineAccountTier();
        if (mounted) {
          _triggerSuccessHaptic();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email verified successfully! Your account is upgraded.'),
              backgroundColor: AppColors.success.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Potentially auto-navigate or enable final button here if needed - REMOVED from here
           // ref.read(onboardingStateNotifierProvider.notifier).goToNextPage(); // Auto-advance if this is the last step
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email not verified yet. Check your inbox and try again.'),
              backgroundColor: AppColors.warning.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e, s) {
       debugPrint("Error refreshing verification status: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error refreshing verification status.'),
            backgroundColor: AppColors.error.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final email = user?.email ?? '';
    final isEduEmail = email.toLowerCase().endsWith('.edu');
    final isVerified = user?.emailVerified ?? false;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600);
    final subtitleStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary);
    final buttonTextStyle = textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
    
    String statusMessage;
    if (isEduEmail) {
      statusMessage = isVerified 
          ? 'Your .edu email is verified, unlocking exclusive features.'
          : 'Verify your .edu email to unlock exclusive features.';
    } else {
      statusMessage = 'Connect a .edu email in Settings later for verified access.';
    }

    return OnboardingPageScaffold(
      title: 'Account Status',
      subtitle: statusMessage, 
      body: Column(
        children: [
          _buildTierCard(
            context: context,
            title: 'Public',
            description: 'Basic features for all users',
            icon: Icons.public_rounded,
            color: AppColors.textSecondary,
            isActive: _accountTier == 'public',
            isAvailable: true,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.spacing12),
          
          _buildTierCard(
            context: context,
            title: 'Verified',
            description: 'For verified .edu accounts',
            icon: Icons.verified_user_rounded,
            color: AppColors.gold,
            isActive: _accountTier == 'verified',
            isAvailable: isEduEmail && isVerified,
            badge: isEduEmail && !isVerified ? 'Verify Email Below' : null,
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideX(begin: -0.1, end: 0),
          
          _buildTierCard(
            context: context,
            title: 'Verified+',
            description: 'For verified organization leaders',
            icon: Icons.star,
            color: AppColors.info,
            isActive: _accountTier == 'verifiedPlus',
            isAvailable: false,
            badge: 'Coming Soon',
          ),
          
          const Spacer(),
          
          if (isEduEmail && !isVerified)
            _buildVerificationSection(context, email, buttonTextStyle)
              .animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          
          if (!(isEduEmail && !isVerified)) 
             const SizedBox(height: AppTheme.spacing24 * 2),
             
          // Add emergency navigation button
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('AccountTierPage: Emergency direct navigation to home');
                  UserPreferencesService.setOnboardingCompleted(true).then((_) {
                    // Try all navigation approaches
                    try {
                      context.go(AppRoutes.home);
                    } catch (e) {
                      debugPrint('Navigation error: $e');
                      try {
                        Navigator.of(context, rootNavigator: true)
                            .pushNamedAndRemoveUntil('/home', (_) => false);
                      } catch (e2) {
                        debugPrint('Second navigation error: $e2');
                      }
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('🚨 EMERGENCY REDIRECT TO HOME'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildVerificationSection(BuildContext context, String email, TextStyle? buttonTextStyle) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.warning.withOpacity(0.7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.warning),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Verify Your .Edu Email',
                style: textTheme.titleMedium?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'A verification link was sent to $email. Check your inbox (and spam folder!) to unlock verified status.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning, 
                    side: BorderSide(color: AppColors.warning.withOpacity(0.5), width: 1.5),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                  ),
                  onPressed: _isProcessing ? null : _sendVerificationEmail,
                  child: _isProcessing && !(_accountTier == 'verified')
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning))) 
                    : Text('Resend Email', style: buttonTextStyle?.copyWith(color: AppColors.warning)),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.black,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                  ),
                  onPressed: _isProcessing ? null : _refreshVerificationStatus,
                  child: _isProcessing && (_accountTier != 'verified')
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.black)))
                    : Text('I Verified It', style: buttonTextStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTierCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool isAvailable,
    String? badge,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final cardTheme = Theme.of(context).cardTheme;

    final cardColor = isActive
        ? color.withOpacity(0.15)
        : (isAvailable ? AppColors.inputBackground : AppColors.inputBackground.withOpacity(0.5));
    final textColor = isActive
        ? color
        : (isAvailable ? AppColors.textPrimary : AppColors.textDisabled);
    final descriptionColor = isActive
        ? color.withOpacity(0.8)
        : (isAvailable ? AppColors.textSecondary : AppColors.textDisabled);
    final iconColor = isActive
        ? color
        : (isAvailable ? AppColors.textSecondary : AppColors.textDisabled);
    final borderColor = isActive ? color : Colors.transparent;

    return Opacity(
      opacity: isAvailable || isActive ? 1.0 : 0.5,
      child: Card(
        elevation: isActive ? 2 : 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardTheme.shape is RoundedRectangleBorder
              ? ((cardTheme.shape as RoundedRectangleBorder).borderRadius as BorderRadius?)
                  ?? BorderRadius.circular(AppTheme.radiusMd)
              : BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(color: descriptionColor),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8, vertical: AppTheme.spacing4),
                  decoration: BoxDecoration(
                    color: isActive ? color.withOpacity(0.2) : AppColors.dark3,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    badge,
                    style: textTheme.labelSmall?.copyWith(color: isActive ? color : AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerSuccessHaptic() {
    HapticFeedback.heavyImpact(); 
    debugPrint("HapticFeedbackManager.success() - Placeholder");
  }
} 