import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';
import '../../state/onboarding_providers.dart';

/// A custom PageView widget for the onboarding flow.
///
/// This widget handles horizontal swiping between pages with animations and
/// prevents swiping to the next page if the current page data is invalid.
class OnboardingPageView extends ConsumerStatefulWidget {
  /// The list of pages to display in the PageView.
  final List<Widget> pages;
  
  /// An optional external page controller
  final PageController? externalController;

  /// Creates an instance of [OnboardingPageView].
  const OnboardingPageView({
    Key? key,
    required this.pages,
    this.externalController,
  }) : super(key: key);
  
  @override
  ConsumerState<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends ConsumerState<OnboardingPageView> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _pageTransitionController;
  int _previousPage = 0;
  
  /// Get the page controller for external access 
  PageController get pageController => _pageController;

  @override
  void initState() {
    super.initState();
    // Use external controller if provided, otherwise create a new one
    final initialIndex = ref.read(currentPageIndexProvider);
    _previousPage = initialIndex;
    _pageController = widget.externalController ?? PageController(initialPage: initialIndex);
    
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    
    debugPrint('OnboardingPageView: Initialized with PageController starting at page $initialIndex');
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    // Only dispose if we created the controller
    if (widget.externalController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for page changes from the state notifier and animate the page view
    ref.listen(currentPageIndexProvider, (previous, next) {
      debugPrint('OnboardingPageView Listener: Detected page index change from $previous to $next');
      
      // Ensure the controller is attached and the indices are different
      if (previous != next && _pageController.hasClients) {
        final currentPageOnController = _pageController.page?.round();
        debugPrint('OnboardingPageView Listener: Controller client attached. Current controller page: $currentPageOnController, Target page: $next');
        
        // Capture direction for transition effect
        _previousPage = previous ?? 0;
        
        // Play transition animation
        _pageTransitionController.forward(from: 0.0);
        
        // Animate only if the controller isn't already on or animating to the target page
        if (currentPageOnController != next) { 
          debugPrint('OnboardingPageView Listener: Requesting animation to page $next');
          
          // Provide haptic feedback based on direction (lighter for back, stronger for forward)
          if (next > (previous ?? 0)) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.lightImpact();
          }
          
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        } else {
           debugPrint('OnboardingPageView Listener: Controller already at target page $next. No animation needed.');
        }
      } else {
        debugPrint('OnboardingPageView Listener: Conditions not met for animation (previous=$previous, next=$next, hasClients=${_pageController.hasClients})');
        // Try to force the controller to the correct page anyway if it has clients
        if (_pageController.hasClients && _pageController.page?.round() != next) { 
          debugPrint('OnboardingPageView Listener: Forcing page jump to $next');
          _pageController.jumpToPage(next); 
        }
      }
    });

    final currentIndex = ref.watch(currentPageIndexProvider);
    final isCurrentPageValid = ref.watch(isCurrentPageValidProvider);
    
    final isMovingForward = currentIndex > _previousPage;
    
    // Log the state during build
    debugPrint('OnboardingPageView Build: Building with currentIndex=$currentIndex, isCurrentPageValid=$isCurrentPageValid');

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _pageTransitionController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Subtle background shimmer effect
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _pageTransitionController.value * 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              Colors.amber.withOpacity(0.02),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Main page view
                  PageView(
                    controller: _pageController,
                    // Disable swiping entirely to control navigation flow
                    physics: const NeverScrollableScrollPhysics(), 
                    onPageChanged: (index) {
                      // Log details when page changes via controller
                      final previousIndex = ref.read(currentPageIndexProvider); 
                      final isCurrentPageValid = ref.read(isCurrentPageValidProvider);
                      debugPrint('OnboardingPageView onPageChanged: Page changed via controller to $index (State was $previousIndex, valid=$isCurrentPageValid)');
                      
                      // This logic primarily handles state updates *from* controller changes
                      if (index != previousIndex) {
                        // If moving forward, ensure the current page is valid
                        if (index > previousIndex && !isCurrentPageValid) {
                          debugPrint('OnboardingPageView onPageChanged: Forward navigation blocked due to invalid page data. Animating back to $previousIndex');
                          
                          // Animate back to the previous page with haptic feedback
                          HapticFeedback.mediumImpact();
                          _pageController.animateToPage(
                            previousIndex,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        } else {
                          debugPrint('OnboardingPageView onPageChanged: Valid navigation detected - Updating state notifier to page $index.');
                          // Update the state through the notifier
                          ref.read(onboardingStateNotifierProvider.notifier).goToPage(index);
                        }
                      } else {
                        debugPrint('OnboardingPageView onPageChanged: Index unchanged ($index), no action needed.');
                      }
                    },
                    children: widget.pages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final page = entry.value;
                      
                      // Apply entrance and exit animations to pages
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: index == currentIndex ? 1.0 : 0.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          transform: Matrix4.translationValues(
                            index == currentIndex 
                                ? 0.0 
                                : (index < currentIndex ? -30.0 : 30.0),
                            0.0,
                            0.0,
                          ),
                          child: page,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ).animate()
         .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
         .moveY(begin: 10, end: 0, duration: 500.ms, curve: Curves.easeOutQuint),
      ],
    );
  }
} 