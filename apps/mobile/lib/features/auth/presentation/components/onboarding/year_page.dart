import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

class YearPage extends StatefulWidget {
  final String? selectedYear;
  final List<String> years;
  final ValueChanged<String> onYearSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const YearPage({
    super.key,
    required this.selectedYear,
    required this.years,
    required this.onYearSelected,
    required this.progressIndicator,
    this.onContinue,
  });
  
  @override
  State<YearPage> createState() => _YearPageState();
}

class _YearPageState extends State<YearPage> with SingleTickerProviderStateMixin {
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
                'What year are you?',
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
                'Select your current year',
                style: OnboardingLayout.subtitleStyle,
              ),
            ),
          ),
          const SizedBox(height: OnboardingLayout.spacingXL),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: AnimatedWrap(
              items: widget.years,
              selectedItem: widget.selectedYear,
              onItemSelected: widget.onYearSelected,
            ),
          ),
          const Expanded(child: SizedBox()),
          widget.progressIndicator,
          const SizedBox(height: OnboardingLayout.spacingMD),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SizedBox(
              width: double.infinity,
              height: OnboardingLayout.buttonHeight,
              child: ElevatedButton(
                onPressed: widget.selectedYear != null ? widget.onContinue : null,
                style: OnboardingLayout.primaryButtonStyle(isEnabled: widget.selectedYear != null),
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
}

/// A wrap layout with staggered animation for its items
class AnimatedWrap extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onItemSelected;
  
  const AnimatedWrap({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OnboardingLayout.spacingSM,
      runSpacing: OnboardingLayout.spacingSM,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isSelected = item == selectedItem;
        
        // Staggered delay based on index
        final delay = Duration(milliseconds: 50 * index);
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: OnboardingLayout.standardDuration,
          curve: OnboardingLayout.entryCurve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _YearOption(
            text: item,
            isSelected: isSelected,
            onTap: () => onItemSelected(item),
          ),
        );
      }),
    );
  }
}

/// A selectable year option with consistent styling
class _YearOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _YearOption({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
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
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : OnboardingLayout.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
} 