import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_page_view.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../widgets/onboarding_navigation_buttons.dart';
import '../pages/name_page.dart';
import '../pages/username_page.dart';
import '../pages/year_page.dart';
import '../pages/major_page.dart';
import '../pages/residence_page.dart';
import '../pages/interests_page.dart';
import '../pages/account_tier_page.dart';
import '../../state/onboarding_providers.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import '../../data/services/profile_submission_service.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';

/// The main screen for the profile onboarding flow.
///
/// This screen orchestrates the multi-step profile completion process using a
/// PageView with various profile information pages.
class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  /// Creates an instance of [ProfileOnboardingScreen].
  const ProfileOnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends ConsumerState<ProfileOnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _submitButtonController;

  @override
  void initState() {
    super.initState();
    _submitButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Log screen view for analytics
    AnalyticsService.logScreenView('onboarding_profile_screen');
  }
  
  @override
  void dispose() {
    _submitButtonController.dispose();
    super.dispose();
  }

  Future<void> _submitProfileData() async {
    final notifier = ref.read(onboardingStateNotifierProvider.notifier);
    final currentState = ref.read(onboardingStateNotifierProvider);

    if (currentState.isSubmitting) return;

    final hasConnectivity = ref.read(hasConnectivityProvider);
    if (!hasConnectivity) {
      // Start submit button animation (pulse) and show offline message
      _submitButtonController.repeat(reverse: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'re offline. We\'ll save your setup and sync once you\'re back online. 🚀'),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 4),
        ),
      );
      
      // Stop animation after a moment
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _submitButtonController.stop();
      });
      
      return;
    }

    notifier.setSubmitting(true);
    
    // Start loading animation
    _submitButtonController.repeat(reverse: true);
    
    try {
      final submissionService = ref.read(profileSubmissionServiceProvider);
      await submissionService.submitProfile(currentState);
      await UserPreferencesService.setOnboardingCompleted(true);
      
      final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
      AnalyticsService.logEvent('onboarding_profile_complete', parameters: {
        'user_id': userId ?? 'unknown_user',
      });
      
      if (mounted) {
        // Success feedback
        HapticFeedback.mediumImpact();
        _submitButtonController.stop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile completed successfully!', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate after a short delay
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            // Transition to the tutorial/feed screen
            context.go('/tutorial');
          }
        });
      }
    } catch (e) {
      notifier.setError(e.toString());
      if (mounted) {
        // Error feedback
        HapticFeedback.vibrate();
        _submitButtonController.stop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to save profile: ${e.toString().split(':').first}', 
                    style: const TextStyle(color: Colors.white)
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _submitProfileData,
            ),
          ),
        );
      }
    } finally {
      notifier.setSubmitting(false);
      _submitButtonController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(onboardingStateNotifierProvider.select((s) => s.isSubmitting));
    final onboardingState = ref.watch(onboardingStateNotifierProvider);
    final canGoBack = ref.watch(canGoBackProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false, // Don't use default back button
        leading: !isSubmitting && canGoBack ? GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(onboardingStateNotifierProvider.notifier).goToPreviousPage();
          },
          child: Container(
            color: Colors.transparent, // Transparent container to prevent gray box
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
            ),
          ),
        ) : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator stays at the top
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: OnboardingProgressIndicator(),
            ).animate().fadeIn(duration: 300.ms),
            
            // Main content expands to fill space
            const Expanded(
              child: OnboardingPageView(
                pages: [
                  NamePage(),
                  UsernamePage(),
                  YearPage(),
                  MajorPage(),
                  ResidencePage(),
                  InterestsPage(),
                  AccountTierPage(),
                ],
              ),
            ),
            
            // Loading indicator or navigation buttons at the bottom
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isSubmitting
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.05)
                            .animate(_submitButtonController),
                        child: const CircularProgressIndicator(color: AppColors.gold),
                      ),
                    )
                  : OnboardingNavigationButtons(
                      finalActionButtonText: 'Complete Profile',
                      onFinalActionPressed: () {
                        _submitProfileData();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 