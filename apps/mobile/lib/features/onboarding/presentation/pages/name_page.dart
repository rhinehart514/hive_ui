import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // Unnecessary import removed
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive_ui/core/widgets/hive_primary_button.dart'; // Placeholder
// import 'package:hive_ui/core/widgets/hive_text_field.dart'; // Placeholder
import 'package:hive_ui/theme/app_colors.dart';
// import 'package:hive_ui/theme/app_typography.dart'; // Placeholder
// import 'package:hive_ui/theme/app_layout.dart'; // Placeholder
// import 'package:hive_ui/core/constants/ui_constants.dart'; // Placeholder
// import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart'; // Placeholder
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_providers.dart';
import '../widgets/onboarding_page_scaffold.dart'; // Common scaffold - NOW EXISTS
import 'package:hive_ui/core/widgets/branded_text_field.dart';
import 'package:hive_ui/utils/feedback_util.dart';

/// A page that collects the user's first and last name.
///
/// This is the first page in the onboarding flow and validates that both
/// first and last name fields are filled out.
class NamePage extends ConsumerStatefulWidget {
  /// Creates an instance of [NamePage].
  const NamePage({super.key});

  @override
  ConsumerState<NamePage> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<NamePage> with TickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();

  // Animation controllers for error animations
  late AnimationController _firstNameShakeController;
  late AnimationController _lastNameShakeController;

  // Track if fields have been interacted with for validation
  bool _firstNameTouched = false;
  bool _lastNameTouched = false;

  @override
  void initState() {
    super.initState();
    _firstNameFocus.addListener(_onFirstNameFocusChange);
    _lastNameFocus.addListener(_onLastNameFocusChange);

    // Initialize shake animation controllers with HIVE standard durations
    _firstNameShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // HIVE standard duration
    );
    
    _lastNameShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // HIVE standard duration
    );

    // Populate fields with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(onboardingStateNotifierProvider);
      
      if (state.firstName != null && state.firstName!.isNotEmpty) {
        _firstNameController.text = state.firstName!;
        _firstNameTouched = true;
      }

      if (state.lastName != null && state.lastName!.isNotEmpty) {
        _lastNameController.text = state.lastName!;
        _lastNameTouched = true;
      }

      // Initial state update and validation check
      _updateStateAndValidate();
    });
  }

  @override
  void dispose() {
    _firstNameFocus.removeListener(_onFirstNameFocusChange);
    _lastNameFocus.removeListener(_onLastNameFocusChange);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _firstNameShakeController.dispose();
    _lastNameShakeController.dispose();
    super.dispose();
  }

  void _onFirstNameFocusChange() {
    if (!_firstNameFocus.hasFocus) {
      setState(() {
        _firstNameTouched = true;
      });
      _updateStateAndValidate(triggerShake: true);
    }
  }

  void _onLastNameFocusChange() {
    if (!_lastNameFocus.hasFocus) {
      setState(() {
        _lastNameTouched = true;
      });
      _updateStateAndValidate(triggerShake: true);
    }
  }

  // Haptic feedback methods using FeedbackUtil
  void _triggerErrorHaptic() {
    FeedbackUtil.error();
  }

  void _triggerSelectionHaptic() {
    FeedbackUtil.selection();
  }

  // Validation methods
  String? _validateFirstName({bool triggerShake = false}) {
    if (!_firstNameTouched) return null;
    
    final value = _firstNameController.text.trim();
    if (value.isEmpty) {
      if (triggerShake) {
        _firstNameShakeController.forward(from: 0.0);
        _triggerErrorHaptic();
      }
      return 'First name is required';
    }
    return null;
  }

  String? _validateLastName({bool triggerShake = false}) {
    if (!_lastNameTouched) return null;
    
    final value = _lastNameController.text.trim();
    if (value.isEmpty) {
      if (triggerShake) {
        _lastNameShakeController.forward(from: 0.0);
        _triggerErrorHaptic();
      }
      return 'Last name is required';
    }
    return null;
  }

  void _updateStateAndValidate({bool triggerShake = false}) {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    // Update state if changed
    final currentState = ref.read(onboardingStateNotifierProvider);
    if (currentState.firstName != firstName || currentState.lastName != lastName) {
      ref.read(onboardingStateNotifierProvider.notifier).updateName(firstName, lastName);
    }

    // Re-validate after state update
    setState(() {
       _validateFirstName(triggerShake: triggerShake && _firstNameTouched);
       _validateLastName(triggerShake: triggerShake && _lastNameTouched);
    });
  }

  void _handleFirstNameSubmitted(String value) {
    setState(() { _firstNameTouched = true; });
    _updateStateAndValidate(triggerShake: true);
    
    // Move focus only if valid
    if (_validateFirstName() == null) {
      _triggerSelectionHaptic();
      FocusScope.of(context).requestFocus(_lastNameFocus);
    }
  }

  void _handleLastNameSubmitted(String value) {
    setState(() { _lastNameTouched = true; });
    _updateStateAndValidate(triggerShake: true);

    // Attempt to navigate if the current page is now valid
    final state = ref.read(onboardingStateNotifierProvider);
    if (state.isCurrentPageValid()) {
      _triggerSelectionHaptic();
      ref.read(onboardingStateNotifierProvider.notifier).goToNextPage();
    } else {
      // Validate any invalid fields with shake animation
      setState(() {
        _validateFirstName(triggerShake: true);
        _validateLastName(triggerShake: true);
      });
    }
  }

  Widget _buildUsernamePreview() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isEmpty && lastName.isEmpty) return const SizedBox.shrink();
    
    final previewText = '$firstName$lastName'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    if (previewText.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.dark2,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.grey700, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 16.0,
              color: AppColors.gold,
            ),
            const SizedBox(width: 8.0),
            Text(
              '@$previewText',
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.textDarkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: 1).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Get current validation errors
    final firstNameError = _validateFirstName();
    final lastNameError = _validateLastName();
    
    // Build input fields with shake animation 
    Widget buildNameFields() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Name Field with shake animation
          AnimatedBuilder(
            animation: _firstNameShakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  sin(_firstNameShakeController.value * 3 * pi) * 10,
                  0,
                ),
                child: child,
              );
            },
            child: BrandedTextField(
              controller: _firstNameController,
              label: 'First Name',
              hint: 'Enter your first name',
              textInputAction: TextInputAction.next,
              validator: (_) => firstNameError,
              onChanged: (_) => _updateStateAndValidate(),
              onFieldSubmitted: _handleFirstNameSubmitted,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Last Name Field with shake animation
          AnimatedBuilder(
            animation: _lastNameShakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  sin(_lastNameShakeController.value * 3 * pi) * 10,
                  0,
                ),
                child: child,
              );
            },
            child: BrandedTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hint: 'Enter your last name',
              textInputAction: TextInputAction.done,
              validator: (_) => lastNameError,
              onChanged: (_) => _updateStateAndValidate(),
              onFieldSubmitted: _handleLastNameSubmitted,
            ),
          ),
          
          // Username preview that appears when both fields have data
          Center(child: _buildUsernamePreview()),
        ],
      );
    }

    // Use the shared OnboardingPageScaffold
    return OnboardingPageScaffold(
      title: 'What\'s your name?',
      subtitle: 'Let\'s start with the basics. Your name will help others recognize you.',
      body: buildNameFields(),
    );
  }
}

// Removed the old OnboardingStyles references, assume HiveTextField, HivePrimaryButton,
// AppTypography, AppLayout, UIConstants, HapticFeedbackManager, OnboardingPageScaffold provide the styling and behavior.
// Also removed the local 'Continue' button as it's handled globally in OnboardingPage.
// Removed explicit entrance animations, assuming OnboardingPageView handles transitions. 