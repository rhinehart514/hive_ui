import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../feed/services/feed_scroll_service.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/tutorial_progress_indicator.dart';
import '../../state/tutorial_providers.dart';

/// A screen that displays the onboarding tutorial to new users.
///
/// This screen is shown after profile completion and guides users through
/// the core concepts of the app (Feed, Rituals, Events, Spaces).
class TutorialScreen extends ConsumerStatefulWidget {
  /// Creates an instance of [TutorialScreen].
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late PageController _pageController;
  final FocusNode _keyboardFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Log analytics for tutorial start
    _logAnalytics('flow_start', 'onboarding.tutorial');
    _logAnalytics('flow_step', 'tutorial.feed_intro_viewed');
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }
  
  void _provideTactileFeedback() {
    HapticFeedback.mediumImpact();
  }
  
  void _logAnalytics(String eventType, String eventName) {
    // TODO: Implement analytics logging
    debugPrint('Analytics: [$eventType: $eventName]');
  }
  
  void _goToNextPage() {
    if (_pageController.page! < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _provideTactileFeedback();
      
      // Log analytics for each step
      final nextPage = (_pageController.page!.toInt() + 1);
      switch (nextPage) {
        case 1:
          _logAnalytics('flow_step', 'tutorial.rituals_intro_viewed');
          break;
        case 2:
          _logAnalytics('flow_step', 'tutorial.events_intro_viewed');
          break;
        case 3:
          _logAnalytics('flow_step', 'tutorial.spaces_intro_viewed');
          break;
      }
    }
  }
  
  void _goToPreviousPage() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _provideTactileFeedback();
    }
  }
  
  void _finishTutorial() {
    _logAnalytics('flow_step', 'tutorial.finish_tapped');
    _logAnalytics('flow_complete', 'onboarding.tutorial');
    
    // Set scroll to ritual card flag before navigation
    ref.read(feedScrollServiceProvider).scheduleScrollToTopRitualCard();
    
    // Navigate to home screen
    context.go('/home');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Focus(
          focusNode: _keyboardFocusNode,
          autofocus: kIsWeb, // Autofocus only on web
          onKey: kIsWeb ? _handleKeyPress : null, // Enable keyboard navigation on web
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.only(
                  top: AppTheme.spacing24,
                  bottom: AppTheme.spacing16,
                ),
                child: TutorialProgressIndicator(
                  totalPages: 4,
                  pageController: _pageController,
                ),
              ),
              
              // Card content area
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    ref.read(tutorialCurrentPageProvider.notifier).state = index;
                  },
                  children: [
                    // Feed Introduction
                    TutorialCard(
                      headline: "Welcome to Your Hive Feed",
                      body: "This isn't just noise. See what matters now - live Rituals, trending events, key updates. No need to follow anyone to get started.",
                      imagePath: "assets/images/tutorial_feed.png", // Optional image
                      onNext: _goToNextPage,
                    ),
                    
                    // Rituals Introduction
                    TutorialCard(
                      headline: "Join Live Rituals",
                      body: ref.watch(hasActiveRitualProvider) 
                          ? "The Campus Madness is heating up! Join the action now right from your feed."
                          : "Rituals are timed campus moments. Participate, earn badges, and see what happens next. Your first one is waiting in the feed!",
                      imagePath: "assets/images/tutorial_rituals.png", // Optional image
                      onNext: _goToNextPage,
                    ),
                    
                    // Events Introduction
                    TutorialCard(
                      headline: "Discover Events Easily",
                      body: "Forget endless scrolling. Trending events and RSVP opportunities appear right in your feed, sometimes unlocking Rituals.",
                      imagePath: "assets/images/tutorial_events.png", // Optional image
                      onNext: _goToNextPage,
                    ),
                    
                    // Spaces Introduction (Final)
                    TutorialCard(
                      headline: "Find Your Groups in Spaces",
                      body: "Spaces are where clubs and orgs live. We've pre-loaded your campus directory. Browse anytime, join later when you're ready.",
                      imagePath: "assets/images/tutorial_spaces.png", // Optional image
                      isLastCard: true,
                      buttonLabel: "Let's Go",
                      onNext: _finishTutorial,
                    ),
                  ],
                ),
              ),
              
              // Web-only keyboard navigation hint
              if (kIsWeb) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                  child: Text(
                    'Use arrow keys to navigate',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.space) {
        final currentPage = ref.read(tutorialCurrentPageProvider);
        if (currentPage < 3) {
          _goToNextPage();
        } else {
          _finishTutorial();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goToPreviousPage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final currentPage = ref.read(tutorialCurrentPageProvider);
        if (currentPage == 3) {
          _finishTutorial();
        } else {
          _goToNextPage();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
} 