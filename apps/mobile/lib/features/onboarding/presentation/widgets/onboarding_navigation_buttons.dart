import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/theme/app_colors.dart';
import '../../state/onboarding_providers.dart';
import '../../state/onboarding_state.dart';

/// Navigation buttons for the onboarding flow.
///
/// This widget provides back, next, and final action buttons for the onboarding
/// flow, with appropriate validation and state management.
class OnboardingNavigationButtons extends ConsumerWidget {
  /// Text to show on the final action button on the last page.
  final String finalActionButtonText;

  /// Callback when the final action button is pressed on the last page.
  final VoidCallback onFinalActionPressed;

  /// Creates an instance of [OnboardingNavigationButtons].
  const OnboardingNavigationButtons({
    required this.finalActionButtonText,
    required this.onFinalActionPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentPageIndexProvider);
    final isLastPage = currentIndex == OnboardingState.totalPages - 1;
    final canGoNext = ref.watch(canGoForwardProvider);
    final canGoBack = ref.watch(canGoBackProvider);
    final currentPageValid = ref.watch(isCurrentPageValidProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: canGoBack
                ? _NavigationButton(
                    key: const ValueKey('back'),
                    icon: Icons.arrow_back,
                    label: 'Back',
                    color: Colors.transparent,
                    borderColor: AppColors.white.withOpacity(0.15),
                    textColor: AppColors.white,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(onboardingStateNotifierProvider.notifier).goToPreviousPage();
                    },
                  )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slide(begin: const Offset(-0.1, 0), duration: 250.ms)
                : const SizedBox(width: 100),
          ),
          
          // Next or Submit button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLastPage
                ? _NavigationButton(
                    key: const ValueKey('submit'),
                    label: finalActionButtonText,
                    color: currentPageValid ? AppColors.gold : AppColors.gold.withOpacity(0.3),
                    textColor: Colors.black,
                    iconPosition: IconPosition.trailing,
                    icon: Icons.check_circle,
                    onPressed: currentPageValid ? onFinalActionPressed : null,
                  )
                    .animate(target: currentPageValid ? 1 : 0)
                    .fadeIn(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.0, 1.0),
                      duration: 300.ms,
                    )
                : _NavigationButton(
                    key: const ValueKey('next'),
                    label: 'Next',
                    iconPosition: IconPosition.trailing,
                    icon: Icons.arrow_forward,
                    color: currentPageValid ? AppColors.white.withOpacity(0.10) : Colors.transparent,
                    borderColor: currentPageValid ? AppColors.white.withOpacity(0.25) : AppColors.white.withOpacity(0.08),
                    textColor: currentPageValid ? AppColors.white : AppColors.white.withOpacity(0.5),
                    onPressed: canGoNext
                        ? () {
                            HapticFeedback.lightImpact();
                            ref.read(onboardingStateNotifierProvider.notifier).goToNextPage();
                          }
                        : null,
                  )
                    .animate(target: currentPageValid ? 1 : 0)
                    .fadeIn(duration: 200.ms)
                    .slide(begin: const Offset(0.1, 0), duration: 250.ms),
          ),
        ],
      ),
    );
  }
}

/// Defines the position of the icon in a button.
enum IconPosition { leading, trailing }

/// A custom button for onboarding navigation.
class _NavigationButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? borderColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final IconPosition iconPosition;

  const _NavigationButton({
    required this.label,
    this.icon,
    required this.color,
    this.borderColor,
    required this.textColor,
    this.onPressed,
    this.iconPosition = IconPosition.leading,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: AppColors.gold.withOpacity(0.1),
        highlightColor: AppColors.gold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: borderColor != null 
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null && iconPosition == IconPosition.leading) ...[
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                if (icon != null && iconPosition == IconPosition.trailing) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: textColor, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(target: isDisabled ? 0 : 1)
      .scaleXY(
        begin: 0.98, 
        end: 1.0, 
        curve: Curves.easeOutQuint,
        duration: 200.ms
      );
  }
} 