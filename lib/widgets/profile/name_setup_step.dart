import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/components/buttons.dart';

/// Name setup step for profile creation
class NameSetupStep extends StatefulWidget {
  /// Initial first name value
  final String? initialFirstName;

  /// Initial last name value
  final String? initialLastName;

  /// Callback when name is submitted
  final Function(String firstName, String lastName) onNameSubmitted;

  /// Constructor
  const NameSetupStep({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    required this.onNameSubmitted,
  });

  @override
  State<NameSetupStep> createState() => _NameSetupStepState();
}

class _NameSetupStepState extends State<NameSetupStep> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();

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

  bool get _isNameValid =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty;

  void _submitName() {
    if (_isNameValid) {
      HapticFeedback.mediumImpact();
      widget.onNameSubmitted(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your name?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'This will be displayed on your profile',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _firstNameController,
          focusNode: _firstNameFocus,
          hintText: 'First Name',
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _lastNameFocus.requestFocus(),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _lastNameController,
          focusNode: _lastNameFocus,
          hintText: 'Last Name',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitName(),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        HiveButton(
          text: 'Continue',
          variant: HiveButtonVariant.primary,
          size: HiveButtonSize.large,
          fullWidth: true,
          onPressed: _isNameValid ? _submitName : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextInputAction textInputAction,
    required Function(String) onSubmitted,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      cursorColor: AppColors.gold,
    );
  }
}
