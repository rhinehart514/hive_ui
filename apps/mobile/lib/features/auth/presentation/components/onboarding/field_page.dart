import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

class FieldPage extends StatefulWidget {
  final String? selectedMajor;
  final List<String> filteredFields;
  final ValueChanged<String> onMajorSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const FieldPage({
    super.key,
    required this.selectedMajor,
    required this.filteredFields,
    required this.onMajorSelected,
    required this.progressIndicator,
    this.onContinue,
  });

  @override
  State<FieldPage> createState() => _FieldPageState();
}

class _FieldPageState extends State<FieldPage> with SingleTickerProviderStateMixin {
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
                'What\'s your major/field?',
                style: OnboardingLayout.titleStyle,
              ),
            ),
          ),
          const SizedBox(height: OnboardingLayout.spacingXS),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                'Choose your primary field of study',
                style: OnboardingLayout.subtitleStyle,
              ),
            ),
          ),
          const SizedBox(height: OnboardingLayout.spacingXL),
          Expanded(
            child: AnimatedList(
              initialItemCount: widget.filteredFields.length,
              itemBuilder: (context, index, animation) {
                final field = widget.filteredFields[index];
                final isSelected = field == widget.selectedMajor;
                
                // Create a staggered effect with increasing delays
                final staggeredAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Interval(
                    0.05 * index, // Start delay based on index
                    1.0,
                    curve: OnboardingLayout.entryCurve,
                  ),
                );
                
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(staggeredAnimation),
                  child: FadeTransition(
                    opacity: staggeredAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: OnboardingLayout.spacingSM),
                      child: _buildFieldItem(field, isSelected),
                    ),
                  ),
                );
              },
            ),
          ),
          widget.progressIndicator,
          const SizedBox(height: OnboardingLayout.spacingLG),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SizedBox(
              width: double.infinity,
              height: OnboardingLayout.buttonHeight,
              child: ElevatedButton(
                onPressed: widget.selectedMajor != null ? widget.onContinue : null,
                style: OnboardingLayout.primaryButtonStyle(isEnabled: widget.selectedMajor != null),
                child: Text(
                  'Continue',
                  style: OnboardingLayout.buttonTextStyle,
                ),
              ),
            ),
          ),
          const SizedBox(height: OnboardingLayout.spacingXL),
        ],
      ),
    );
  }
  
  Widget _buildFieldItem(String field, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onMajorSelected(field);
        },
        borderRadius: BorderRadius.circular(OnboardingLayout.itemRadius),
        splashColor: OnboardingLayout.activeIndicator.withOpacity(0.1),
        highlightColor: OnboardingLayout.activeIndicator.withOpacity(0.05),
        child: AnimatedContainer(
          duration: OnboardingLayout.standardDuration,
          curve: OnboardingLayout.standardCurve,
          padding: OnboardingLayout.itemPadding,
          decoration: isSelected 
            ? OnboardingLayout.selectedItemDecoration
            : OnboardingLayout.unselectedItemDecoration,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  field,
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