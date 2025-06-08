import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/theme/app_colors.dart';
import '../../state/onboarding_providers.dart';
import '../../state/onboarding_state.dart';

/// A progress indicator for the onboarding flow.
///
/// This widget displays the current step progress as a horizontal indicator
/// with the current step highlighted.
class OnboardingProgressIndicator extends ConsumerWidget {
  const OnboardingProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentPageIndexProvider);
    final completionPercentage = ref.watch(completionPercentageProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text progress indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Step ${currentIndex + 1}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ).animate(target: currentIndex.toDouble()).fadeIn(duration: 300.ms),
              Text(
                ' of ${OnboardingState.totalPages}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Visual progress bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 650),
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glow under progress
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                widthFactor: completionPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Main progress bar
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                widthFactor: completionPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, Color(0xFFFFE34D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Step indicators
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SizedBox(
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                OnboardingState.totalPages,
                (index) => _buildStepIndicator(index, currentIndex),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int index, int currentIndex) {
    final bool isCurrent = index == currentIndex;
    final bool isCompleted = index < currentIndex;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isCurrent ? 12 : 8,
      height: isCurrent ? 12 : 8,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.gold
            : isCompleted
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    ).animate(target: isCurrent ? 1.0 : 0.0)
      .scale(
        begin: const Offset(0.8, 0.8), 
        end: const Offset(1.0, 1.0),
        duration: 250.ms, 
        curve: Curves.easeOutExpo
      )
      .shimmer(duration: isCurrent ? 1800.ms : 0.ms, delay: 300.ms);
  }
} 