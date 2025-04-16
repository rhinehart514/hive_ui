import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

class ResidencePage extends StatefulWidget {
  final String? selectedResidence;
  final List<String> residenceOptions;
  final ValueChanged<String> onResidenceSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const ResidencePage({
    super.key,
    required this.selectedResidence,
    required this.residenceOptions,
    required this.onResidenceSelected,
    required this.progressIndicator,
    this.onContinue,
  });

  @override
  State<ResidencePage> createState() => _ResidencePageState();
}

class _ResidencePageState extends State<ResidencePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: OnboardingLayout.standardDuration,
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: OnboardingLayout.entryCurve,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: OnboardingLayout.entryCurve,
      ),
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OnboardingLayout.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                'Where do you live?',
                style: OnboardingLayout.titleStyle,
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXS),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                'Select your campus housing or residence',
                style: OnboardingLayout.subtitleStyle,
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXL),
          Expanded(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.residenceOptions.length,
                itemBuilder: (context, index) {
                  final residence = widget.residenceOptions[index];
                  final isSelected = residence == widget.selectedResidence;
                  
                  // Add staggered animation effect
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: OnboardingLayout.standardDuration,
                    curve: Interval(
                      0.05 * index,
                      1.0,
                      curve: OnboardingLayout.entryCurve,
                    ),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: OnboardingLayout.spacingSM),
                      child: _buildResidenceItem(residence, isSelected),
                    ),
                  );
                },
              ),
            ),
          ),
          widget.progressIndicator,
          SizedBox(height: OnboardingLayout.spacingMD),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SizedBox(
              width: double.infinity,
              height: OnboardingLayout.buttonHeight,
              child: ElevatedButton(
                onPressed: widget.selectedResidence != null ? widget.onContinue : null,
                style: OnboardingLayout.primaryButtonStyle(isEnabled: widget.selectedResidence != null),
                child: Text(
                  'Continue',
                  style: OnboardingLayout.buttonTextStyle,
                ),
              ),
            ),
          ),
          SizedBox(height: OnboardingLayout.spacingXL),
        ],
      ),
    );
  }
  
  Widget _buildResidenceItem(String residence, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onResidenceSelected(residence);
        },
        borderRadius: BorderRadius.circular(OnboardingLayout.itemRadius),
        splashColor: OnboardingLayout.activeIndicator.withOpacity(0.1),
        highlightColor: OnboardingLayout.activeIndicator.withOpacity(0.05),
        child: Container(
          padding: OnboardingLayout.itemPadding,
          decoration: isSelected 
            ? OnboardingLayout.selectedItemDecoration
            : OnboardingLayout.unselectedItemDecoration,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  residence,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.black : OnboardingLayout.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isSelected)
                AnimatedOpacity(
                  duration: OnboardingLayout.shortDuration,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 