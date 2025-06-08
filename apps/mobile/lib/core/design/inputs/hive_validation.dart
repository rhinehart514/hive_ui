import 'package:flutter/material.dart';

/// HIVE Validation System - Smooth Error Handling
/// Tech, sleek validation with refined error animations
class HiveValidationField extends StatefulWidget {
  final String? label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final List<ValidationRule> validationRules;
  final bool validateOnChange;
  final TextInputType? keyboardType;
  final bool isPassword;

  const HiveValidationField({
    super.key,
    this.label,
    this.hint,
    this.onChanged,
    this.controller,
    this.validationRules = const [],
    this.validateOnChange = true,
    this.keyboardType,
    this.isPassword = false,
  });

  @override
  State<HiveValidationField> createState() => _HiveValidationFieldState();
}

class _HiveValidationFieldState extends State<HiveValidationField>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late AnimationController _errorSlideController;
  late AnimationController _pulseController;
  
  String? _errorMessage;
  bool _isValid = true;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    
    // Shake animation for errors
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Sliding error message animation
    _errorSlideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Pulsing border for errors
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    if (widget.validateOnChange) {
      _validate();
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _validate() {
    final text = _controller.text;
    String? newErrorMessage;
    
    for (final rule in widget.validationRules) {
      if (!rule.isValid(text)) {
        newErrorMessage = rule.errorMessage;
        break;
      }
    }
    
    if (newErrorMessage != _errorMessage) {
      setState(() {
        _errorMessage = newErrorMessage;
        _isValid = newErrorMessage == null;
      });
      
      if (!_isValid) {
        _triggerErrorAnimation();
      } else {
        _clearErrorAnimation();
      }
    }
  }

  void _triggerErrorAnimation() {
    // Shake animation
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
    
    // Slide in error message
    _errorSlideController.forward();
    
    // Pulsing border
    _pulseController.repeat();
  }

  void _clearErrorAnimation() {
    _errorSlideController.reverse();
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _shakeController.dispose();
    _errorSlideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: !_isValid
                ? const Color(0xFFFF3B30)
                : (_isFocused 
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFCCCCCC)),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Input field with validation animations
        AnimatedBuilder(
          animation: Listenable.merge([_shakeController, _pulseController]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeController.value * 10 * 
                  (1 - _shakeController.value) * 
                  ((_shakeController.value * 6) % 2 == 0 ? 1 : -1),
                0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0F0F0F),
                  border: Border.all(
                    color: !_isValid
                      ? Color.lerp(
                          const Color(0xFFFF3B30),
                          const Color(0xFFFF3B30).withOpacity(0.3),
                          _pulseController.value,
                        )!
                      : (_isFocused 
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.1)),
                    width: !_isValid || _isFocused ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: !_isValid
                        ? const Color(0xFFFF3B30).withOpacity(0.3)
                        : Colors.black.withOpacity(0.6),
                      blurRadius: _isFocused || !_isValid ? 12 : 4,
                      offset: Offset(0, _isFocused || !_isValid ? 2 : 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.isPassword,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    suffixIcon: !_isValid
                      ? const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF3B30),
                          size: 20,
                        )
                      : (_controller.text.isNotEmpty && _isValid
                        ? const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF8CE563),
                            size: 20,
                          )
                        : null),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Sliding error message
        AnimatedBuilder(
          animation: _errorSlideController,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: _errorSlideController.value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage ?? '',
                    style: const TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Validation rule for form fields
class ValidationRule {
  final bool Function(String) isValid;
  final String errorMessage;

  const ValidationRule({
    required this.isValid,
    required this.errorMessage,
  });

  // Common validation rules
  static ValidationRule required() {
    return ValidationRule(
      isValid: (value) => value.isNotEmpty,
      errorMessage: 'This field is required',
    );
  }

  static ValidationRule email() {
    return ValidationRule(
      isValid: (value) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return value.isEmpty || emailRegex.hasMatch(value);
      },
      errorMessage: 'Please enter a valid email address',
    );
  }

  static ValidationRule minLength(int length) {
    return ValidationRule(
      isValid: (value) => value.length >= length,
      errorMessage: 'Must be at least $length characters',
    );
  }

  static ValidationRule maxLength(int length) {
    return ValidationRule(
      isValid: (value) => value.length <= length,
      errorMessage: 'Must be no more than $length characters',
    );
  }

  static ValidationRule password() {
    return ValidationRule(
      isValid: (value) {
        if (value.isEmpty) return true;
        return value.length >= 8 && 
               RegExp(r'[A-Z]').hasMatch(value) &&
               RegExp(r'[a-z]').hasMatch(value) &&
               RegExp(r'[0-9]').hasMatch(value);
      },
      errorMessage: 'Password must contain uppercase, lowercase, and number',
    );
  }
} 