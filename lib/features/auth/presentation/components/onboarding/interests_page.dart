import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

class InterestsPage extends StatelessWidget {
  final List<String> selectedInterests;
  final List<String> interestOptions;
  final ValueChanged<String> onInterestToggled;
  final Widget progressIndicator;
  final VoidCallback? onContinue;
  final int minInterests;
  final int maxInterests;

  const InterestsPage({
    Key? key,
    required this.selectedInterests,
    required this.interestOptions,
    required this.onInterestToggled,
    required this.progressIndicator,
    this.onContinue,
    this.minInterests = 3,
    this.maxInterests = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompleted = selectedInterests.length >= minInterests;
    final canAddMore = selectedInterests.length < maxInterests;
    
    return Padding(
      padding: OnboardingLayout.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you interested in?',
            style: OnboardingLayout.titleStyle,
          ),
          SizedBox(height: OnboardingLayout.spacingXS),
          Text(
            'Select at least $minInterests interests (max $maxInterests)',
            style: OnboardingLayout.subtitleStyle,
          ),
          SizedBox(height: OnboardingLayout.spacingXL),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interestOptions.map((interest) {
                  final isSelected = selectedInterests.contains(interest);
                  final canSelect = canAddMore || isSelected;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSelect ? () => onInterestToggled(interest) : null,
                      borderRadius: BorderRadius.circular(OnboardingLayout.itemRadius),
                      splashColor: OnboardingLayout.activeIndicator.withOpacity(0.1),
                      highlightColor: OnboardingLayout.activeIndicator.withOpacity(0.05),
                      child: Container(
                        padding: OnboardingLayout.itemPadding,
                        decoration: isSelected
                          ? OnboardingLayout.selectedItemDecoration
                          : canAddMore 
                              ? OnboardingLayout.unselectedItemDecoration
                              : BoxDecoration(
                                  color: OnboardingLayout.deepLayer,
                                  borderRadius: BorderRadius.circular(OnboardingLayout.itemRadius),
                                  border: Border.all(
                                    color: OnboardingLayout.textTertiary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                        child: Text(
                          interest,
                          style: GoogleFonts.inter(
                            color: isSelected 
                              ? Colors.black 
                              : canAddMore 
                                ? OnboardingLayout.textPrimary
                                : OnboardingLayout.textDisabled,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: OnboardingLayout.spacingMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Selected ${selectedInterests.length}/$maxInterests',
                  style: GoogleFonts.inter(
                    color: OnboardingLayout.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          progressIndicator,
          SizedBox(height: OnboardingLayout.spacingMD),
          SizedBox(
            width: double.infinity,
            height: OnboardingLayout.buttonHeight,
            child: ElevatedButton(
              onPressed: isCompleted ? onContinue : null,
              style: OnboardingLayout.primaryButtonStyle(isEnabled: isCompleted),
              child: Text(
                'Continue',
                style: OnboardingLayout.buttonTextStyle,
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXL),
        ],
      ),
    );
  }
} 