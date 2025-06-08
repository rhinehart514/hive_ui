import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/data/repositories/social_auth_helpers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/core/widgets/branded_text_field.dart';

/// Utility class for validating email domains
class EmailDomainValidator {
  /// Checks if the email belongs to an educational domain (.edu)
  static bool isEduEmail(String email) {
    return SocialAuthHelpers.isEduEmail(email);
  }
  
  /// Checks if the email belongs to any approved educational institution
  static bool isApprovedEducationalDomain(String email) {
    return SocialAuthHelpers.isApprovedEducationalDomain(email);
  }
}

/// A custom form field with email domain validation for educational institutions
/// 
/// This component validates emails during input to ensure they match
/// approved educational domains.
class EmailDomainValidatorField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool showValidationStatus;
  final EdgeInsets padding;

  const EmailDomainValidatorField({
    Key? key,
    required this.controller,
    this.label = 'School Email',
    this.hint,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.showValidationStatus = true,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  ConsumerState<EmailDomainValidatorField> createState() => _EmailDomainValidatorFieldState();
}

class _EmailDomainValidatorFieldState extends ConsumerState<EmailDomainValidatorField> {
  bool _isValidDomain = false;
  bool _hasChecked = false;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateEmailDomain);
    
    // Initial validation if there's already a value
    if (widget.controller.text.isNotEmpty) {
      _validateEmailDomain();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateEmailDomain);
    _focusNode.dispose();
    super.dispose();
  }

  void _validateEmailDomain() {
    final email = widget.controller.text.trim();
    
    // Don't validate empty emails or very short inputs
    if (email.isEmpty || email.length < 5 || !email.contains('@')) {
      setState(() {
        _isValidDomain = false;
        _hasChecked = false;
        _errorMessage = null;
      });
      return;
    }
    
    // Perform actual validation
    final isValid = SocialAuthHelpers.isApprovedEducationalDomain(email);
    
    setState(() {
      _isValidDomain = isValid;
      _hasChecked = true;
      
      if (!isValid && email.contains('@')) {
        _errorMessage = 'Please use your .edu or school email';
      } else {
        _errorMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              BrandedTextField(
                controller: widget.controller,
                label: widget.label,
                hint: widget.hint ?? 'youremail@university.edu',
                autofocus: widget.autofocus,
                textInputAction: widget.textInputAction,
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: widget.onFieldSubmitted,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  
                  if (_hasChecked && !_isValidDomain) {
                    return 'Please use your .edu or school email';
                  }
                  
                  return null;
                },
                onChanged: (_) => _validateEmailDomain(),
              ),
              if (_hasChecked)
                Positioned(
                  right: 12,
                  top: 40, // Adjusted to position properly within the text field
                  child: _isValidDomain
                      ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                      : const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                ),
            ],
          ),
          if (widget.showValidationStatus && _hasChecked && _isValidDomain)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'Valid educational domain',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 