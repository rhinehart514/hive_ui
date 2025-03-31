import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/profile/name_setup_step.dart';
import 'package:hive_ui/widgets/profile/selection_setup_step.dart';

/// A multi-step profile setup flow widget
class ProfileSetupFlow extends StatefulWidget {
  /// Initial first name value
  final String? initialFirstName;

  /// Initial last name value
  final String? initialLastName;

  /// Initial class level selection
  final String? initialClassLevel;

  /// Initial field of study selection
  final String? initialFieldOfStudy;

  /// Initial residence selection
  final String? initialResidence;

  /// Callback when name is submitted
  final Function(String firstName, String lastName) onNameSubmitted;

  /// Callback when class level is selected
  final Function(String classLevel) onClassLevelSelected;

  /// Callback when field of study is selected
  final Function(String fieldOfStudy) onFieldOfStudySelected;

  /// Callback when residence is selected
  final Function(String residence) onResidenceSelected;

  /// Constructor
  const ProfileSetupFlow({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialClassLevel,
    this.initialFieldOfStudy,
    this.initialResidence,
    required this.onNameSubmitted,
    required this.onClassLevelSelected,
    required this.onFieldOfStudySelected,
    required this.onResidenceSelected,
  });

  @override
  State<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  int _currentStep = 0;

  // Predefined options
  final List<String> classLevels = [
    'Freshman',
    'Sophomore',
    'Junior',
    'Senior',
    'Masters',
    'PhD',
    'Non-Degree',
  ];

  final List<String> fieldsOfStudy = [
    'Computer Science',
    'Engineering',
    'Business',
    'Arts',
    'Sciences',
    'Medicine',
    'Law',
    'Other',
  ];

  final List<String> residenceOptions = [
    'On Campus - Greiner',
    'On Campus - Ellicott',
    'On Campus - Governors',
    'On Campus - South Lake',
    'Off Campus - University Heights',
    'Off Campus - Amherst',
    'Off Campus - Other',
  ];

  void _goToNextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _handleNameSubmitted(String firstName, String lastName) {
    widget.onNameSubmitted(firstName, lastName);
    _goToNextStep();
  }

  void _handleClassLevelSelected(String classLevel) {
    widget.onClassLevelSelected(classLevel);
    _goToNextStep();
  }

  void _handleFieldOfStudySelected(String fieldOfStudy) {
    widget.onFieldOfStudySelected(fieldOfStudy);
    _goToNextStep();
  }

  void _handleResidenceSelected(String residence) {
    widget.onResidenceSelected(residence);
    // No next step needed, this is the last one
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4, // 4 steps total
              backgroundColor: Colors.white.withOpacity(0.1),
              color: AppColors.gold,
              minHeight: 4,
            ),
            const SizedBox(height: 32),

            // Show appropriate step content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return NameSetupStep(
          key: const ValueKey('name-step'),
          initialFirstName: widget.initialFirstName,
          initialLastName: widget.initialLastName,
          onNameSubmitted: _handleNameSubmitted,
        );
      case 1:
        return SelectionSetupStep(
          key: const ValueKey('class-level-step'),
          title: 'What year are you?',
          description: 'Select your current academic level',
          options: classLevels,
          initialSelection: widget.initialClassLevel,
          onSelectionSubmitted: _handleClassLevelSelected,
        );
      case 2:
        return SelectionSetupStep(
          key: const ValueKey('field-of-study-step'),
          title: 'What do you study?',
          description: 'Select your field of study',
          options: fieldsOfStudy,
          initialSelection: widget.initialFieldOfStudy,
          onSelectionSubmitted: _handleFieldOfStudySelected,
        );
      case 3:
        return SelectionSetupStep(
          key: const ValueKey('residence-step'),
          title: 'Where do you live?',
          description: 'Select your current residence',
          options: residenceOptions,
          initialSelection: widget.initialResidence,
          onSelectionSubmitted: _handleResidenceSelected,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
