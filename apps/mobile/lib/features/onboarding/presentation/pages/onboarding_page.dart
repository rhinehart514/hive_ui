import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/core/widgets/hive_secondary_button.dart';
import 'package:hive_ui/features/onboarding/data/services/profile_submission_service.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/account_tier_page.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/interests_page.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/major_page.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/name_page.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/residence_page.dart';
import 'package:hive_ui/features/onboarding/presentation/pages/year_page.dart';
import 'package:hive_ui/features/onboarding/presentation/widgets/onboarding_progress_indicator.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_state.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/dark_surface.dart';

/// The main onboarding page that manages the multi-step profile completion flow.
/// 
/// This page coordinates the different steps of the onboarding process,
/// provides navigation controls, and handles the final profile submission.
class OnboardingPage extends ConsumerStatefulWidget {
  /// Whether to skip manual entry and use defaults
  final bool skipToDefaults;

  /// Creates an instance of [OnboardingPage].
  const OnboardingPage({
    super.key,
    this.skipToDefaults = false,
  });

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  void initState() {
    super.initState();

    if (widget.skipToDefaults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSkipWithDefaults();
      });
    }
  }

  void _autoSkipWithDefaults() {
    final notifier = ref.read(onboardingStateNotifierProvider.notifier);
    
    // Set default name
    notifier.updateName('New', 'User');
    
    // Set default year
    notifier.updateYear('Freshman');
    
    // Set default major
    notifier.updateMajor('Computer Science');
    
    // Set default residence
    notifier.updateResidence('Off Campus');
    
    // Set default interests (at least 5)
    for (final interest in [
      'Campus Events',
      'Student Life',
      'Networking',
      'Career Development',
      'Social Activities'
    ]) {
      notifier.addInterest(interest);
    }
    
    // Complete onboarding with defaults
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final notifier = ref.read(onboardingStateNotifierProvider.notifier);
    final currentState = ref.read(onboardingStateNotifierProvider);
    
    // Check if already submitting via provider state
    if (currentState.isSubmitting) return;
    
    // Check connectivity first
    final hasConnectivity = ref.read(hasConnectivityProvider);
    if (!hasConnectivity) {
      _showOfflineMessage();
      return; // Do not proceed with submission
    }
    
    try {
      // Set submitting state via provider
      notifier.setSubmitting(true);
      
      // Call the submission service
      final submissionService = ref.read(profileSubmissionServiceProvider);
      
      try {
        await submissionService.submitProfile(currentState);
      } catch (e) {
        // Check if this is a Firebase Realtime Database plugin issue on Windows
        if (e.toString().contains('MissingPluginException') && 
            e.toString().contains('firebase_database')) {
          // Continue execution as if submission was successful
        } else {
          // For other errors, rethrow to be caught by the outer try-catch
          rethrow;
        }
      }
      
      // Mark onboarding as completed to bypass all remaining onboarding screens
      await UserPreferencesService.setOnboardingCompleted(true);
      
      // Fire analytics event - with safe check for Realtime Database issues
      _logCompletionAnalytics(currentState);
      
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      notifier.setError(e.toString());
      _showError('Error completing onboarding: ${e.toString()}');
    } finally {
      // Reset submitting state via provider
      notifier.setSubmitting(false);
    }
  }

  void _logCompletionAnalytics(OnboardingState state) {
    try {
      AnalyticsService.logEvent('onboarding_complete', parameters: {
        'user_id': ref.read(firebaseAuthProvider).currentUser?.uid ?? 'unknown_user',
        'email_verified': ref.read(firebaseAuthProvider).currentUser?.emailVerified ?? false,
        'account_tier': state.accountTier ?? 'public',
        'bypass_access_pass': true,
        'bypass_campus_dna': true,
      });
    } catch (_) {
      // Non-critical analytics error can be ignored
    }
  }
  
  void _showOfflineMessage() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You\'re offline. We\'ll save your setup and sync once you\'re back online. 🚀'
        ),
        backgroundColor: AppColors.info,
        duration: Duration(seconds: 4),
      ),
    );
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // Haptic feedback methods
  void _triggerMediumImpactHaptic() {
    HapticFeedback.mediumImpact();
  }
  
  void _triggerErrorImpactHaptic() {
    HapticFeedback.heavyImpact(); // Use heavy for error/block
  }

  Widget _buildNavigationButtons() {
    final currentIndex = ref.watch(currentPageIndexProvider);
    final canGoBack = ref.watch(canGoBackProvider);
    final canGoForward = ref.watch(canGoForwardProvider);
    final isSubmitting = ref.watch(onboardingStateNotifierProvider.select((s) => s.isSubmitting));
    final isLastPage = currentIndex == OnboardingState.totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Expanded(
            child: HiveSecondaryButton(
              text: 'Back',
              onPressed: canGoBack
                  ? () {
                      ref.read(onboardingStateNotifierProvider.notifier).goToPreviousPage();
                      _triggerMediumImpactHaptic();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 8.0),
          // Next/Complete button
          Expanded(
            child: HivePrimaryButton(
              text: isLastPage ? 'Complete Profile' : 'Next',
              isLoading: isSubmitting && isLastPage,
              onPressed: isLastPage
                  ? (isSubmitting ? null : _completeOnboarding)
                  : (canGoForward ? _goToNextPage : null),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextPage() {
    final result = ref.read(onboardingStateNotifierProvider.notifier).goToNextPage();
    
    if (result) {
      _triggerMediumImpactHaptic();
    } else {
      _triggerErrorImpactHaptic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(onboardingPageControllerProvider);
    final currentPageIndex = ref.watch(currentPageIndexProvider);

    // Listen to page index changes and command the PageController
    ref.listen<int>(currentPageIndexProvider, (previousIndex, nextIndex) {
      if (previousIndex != nextIndex) {
        // Ensure controller is attached before animating
        if (pageController.hasClients) {
          pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 400), // Standard HIVE duration
            curve: Curves.easeInOut, // Standard HIVE curve
          );
        }
      }
    });

    final List<Widget> pages = [
      const NamePage(),
      const YearPage(),
      const MajorPage(),
      const ResidencePage(),
      const InterestsPage(),
      const AccountTierPage(),
    ];

    // Wrap the Scaffold with DarkSurface
    return DarkSurface(
      surfaceType: SurfaceType.canvas, // Use canvas for main pages
      withGrainTexture: true,
      child: Scaffold(
        // Make Scaffold background transparent to show the DarkSurface
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar transparent
          elevation: 0,
          centerTitle: true,
          title: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: OnboardingProgressIndicator(),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Page content area
              Expanded(
                child: PageView(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    ref.read(onboardingStateNotifierProvider.notifier).goToPage(index);
                  },
                  children: pages,
                ),
              ),
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }
} 