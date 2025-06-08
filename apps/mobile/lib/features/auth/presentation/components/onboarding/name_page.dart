import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/features/auth/presentation/components/onboarding/layout_constants.dart';

/// NamePage widget for onboarding (extracted from onboarding_profile.dart)
class NamePage extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback? onContinue;
  final bool isNameValid;
  final Widget progressIndicator;
  final VoidCallback? onTextChanged;

  const NamePage({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.onContinue,
    required this.isNameValid,
    required this.progressIndicator,
    this.onTextChanged,
  });

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Add listeners to text controllers to update parent state
    widget.firstNameController.addListener(_notifyTextChanged);
    widget.lastNameController.addListener(_notifyTextChanged);
    
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
    // Remove listeners when widget is disposed
    widget.firstNameController.removeListener(_notifyTextChanged);
    widget.lastNameController.removeListener(_notifyTextChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _notifyTextChanged() {
    if (widget.onTextChanged != null) {
      widget.onTextChanged!();
    }
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
                'What\'s your name?',
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
                'Let\'s get to know you',
                style: OnboardingLayout.subtitleStyle,
              ),
            ),
          ),
          const SizedBox(height: OnboardingLayout.spacingXL),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: OnboardingLayout.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: widget.firstNameController,
                      label: 'First Name',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: OnboardingLayout.spacingMD),
                    _buildTextField(
                      controller: widget.lastNameController,
                      label: 'Last Name',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (widget.isNameValid && widget.onContinue != null) {
                          HapticFeedback.selectionClick();
                          widget.onContinue!();
                        }
                      },
                    ),
                  ],
                ),
              ),
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
                onPressed: widget.isNameValid 
                  ? () {
                      HapticFeedback.mediumImpact(); // Add haptic feedback like sign-in page
                      widget.onContinue?.call();
                    }
                  : null,
                style: OnboardingLayout.primaryButtonStyle(isEnabled: widget.isNameValid),
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
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: OnboardingLayout.inputTextStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: OnboardingLayout.inputLabelStyle,
        fillColor: OnboardingLayout.secondarySurface,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OnboardingLayout.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OnboardingLayout.inputRadius),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OnboardingLayout.inputRadius),
          borderSide: const BorderSide(color: OnboardingLayout.activeIndicator, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OnboardingLayout.spacingMD,
          vertical: OnboardingLayout.spacingMD,
        ),
      ),
      cursorColor: OnboardingLayout.activeIndicator,
      textInputAction: textInputAction,
      maxLength: 30,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      onSubmitted: onSubmitted,
    );
  }
} 