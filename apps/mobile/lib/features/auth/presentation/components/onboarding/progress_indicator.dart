import 'package:flutter/material.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

/// A consistent progress indicator for onboarding flow following HIVE brand aesthetic
class OnboardingProgressIndicator extends StatelessWidget {
  /// Total number of steps in the onboarding flow
  final int totalSteps;
  
  /// Current active step (0-indexed)
  final int currentStep;
  
  /// Creates an OnboardingProgressIndicator
  const OnboardingProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OnboardingLayout.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          final isCurrentStep = index == currentStep;
          final isPreviousStep = index < currentStep;
          
          return AnimatedContainer(
            duration: OnboardingLayout.standardDuration,
            curve: OnboardingLayout.standardCurve,
            width: isCurrentStep ? 32 : 8,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive 
                ? (isCurrentStep 
                  ? OnboardingLayout.activeIndicator
                  : OnboardingLayout.activeIndicatorDim)
                : OnboardingLayout.inactiveElement,
              boxShadow: isCurrentStep ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ] : null,
            ),
            child: isPreviousStep ? const CompletedStepIndicator() : null,
          );
        }),
      ),
    );
  }
}

/// A subtle animation for completed steps
class CompletedStepIndicator extends StatefulWidget {
  const CompletedStepIndicator({super.key});

  @override
  State<CompletedStepIndicator> createState() => _CompletedStepIndicatorState();
}

class _CompletedStepIndicatorState extends State<CompletedStepIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: OnboardingLayout.shortDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: OnboardingLayout.standardCurve,
      ),
    );
    
    // Run once when initially shown
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.05 * _animation.value),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        );
      },
    );
  }
} 