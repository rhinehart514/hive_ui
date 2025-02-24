import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme.dart';

class ProfileSetupFlow extends StatefulWidget {
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialClassLevel;
  final String? initialFieldOfStudy;
  final String? initialResidence;
  final Function(String firstName, String lastName) onNameSubmitted;
  final Function(String classLevel) onClassLevelSelected;
  final Function(String fieldOfStudy) onFieldOfStudySelected;
  final Function(String residence) onResidenceSelected;

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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
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

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    
    // Request focus on first name field when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_firstNameController.text.isEmpty) {
        _firstNameFocus.requestFocus();
      } else if (_lastNameController.text.isEmpty) {
        _lastNameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep++);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getStepTitle(),
            style: AppTextStyle.headlineLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepDescription(),
            style: AppTextStyle.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildCurrentStep(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'What\'s your name?';
      case 1:
        return 'What\'s your class level?';
      case 2:
        return 'What\'s your field of study?';
      case 3:
        return 'Where do you live?';
      default:
        return '';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Please enter your first and last name';
      case 1:
        return 'Select your current academic level';
      case 2:
        return 'Select your major or field of study';
      case 3:
        return 'Select your residential area';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildOptionsStep(
          options: classLevels,
          selectedValue: widget.initialClassLevel,
          onSelected: widget.onClassLevelSelected,
        );
      case 2:
        return _buildOptionsStep(
          options: fieldsOfStudy,
          selectedValue: widget.initialFieldOfStudy,
          onSelected: widget.onFieldOfStudySelected,
        );
      case 3:
        return _buildOptionsStep(
          options: residenceOptions,
          selectedValue: widget.initialResidence,
          onSelected: widget.onResidenceSelected,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _firstNameController,
          focusNode: _firstNameFocus,
          label: 'First Name',
          onSubmitted: (_) => _lastNameFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          focusNode: _lastNameFocus,
          label: 'Last Name',
          onSubmitted: (_) {
            if (_firstNameController.text.isNotEmpty && 
                _lastNameController.text.isNotEmpty) {
              widget.onNameSubmitted(
                _firstNameController.text,
                _lastNameController.text,
              );
              _nextStep();
            }
          },
        ),
        const SizedBox(height: 24),
        _buildContinueButton(
          onPressed: () {
            if (_firstNameController.text.isNotEmpty && 
                _lastNameController.text.isNotEmpty) {
              widget.onNameSubmitted(
                _firstNameController.text,
                _lastNameController.text,
              );
              _nextStep();
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required Function(String) onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.gold.withOpacity(0.5),
          ),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }

  Widget _buildOptionsStep({
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Column(
      children: [
        ...options.map((option) => _buildOptionButton(
          label: option,
          isSelected: option == selectedValue,
          onTap: () {
            onSelected(option);
            _nextStep();
          },
        )),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.bodyMedium.copyWith(
            color: isSelected ? AppColors.gold : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton({required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
          ),
        ),
        child: Text(
          'Continue',
          style: AppTextStyle.bodyMedium.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 