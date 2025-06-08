import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Validation states for the text field
enum ValidationState {
  none, // Default state
  valid, // Success state (e.g., green glow)
  invalid // Error state (e.g., red glow)
}

/// A text form field styled according to HIVE design guidelines,
/// now with real-time validation glow effects.
class HiveTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final String? errorText;
  final Color focusedBorderColor;
  final ValidationState validationState; // Added validation state
  final Duration animationDuration; // Added animation duration
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;

  const HiveTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.errorText,
    this.focusedBorderColor = AppColors.white, // Default to white
    this.validationState = ValidationState.none, // Default validation state
    this.animationDuration = const Duration(milliseconds: 200),
    this.inputFormatters,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final Color hintColor = (Colors.grey[600] ?? Colors.grey).withOpacity(0.7);
    final Color textColor = style?.color ?? AppColors.white;
    final Color enabledBorderColor = (Colors.grey[600] ?? Colors.grey).withOpacity(0.3);
    const Color errorBorderColor = AppColors.error;
    const Color successBorderColor = AppColors.success;
    const Color fillColor = Color(0xFF1E1E1E);

    // Determine border color based on validation state
    Color currentBorderColor;
    double currentBorderWidth = 1.0;
    Color? currentGlowColor;

    switch (validationState) {
      case ValidationState.valid:
        currentBorderColor = successBorderColor;
        currentGlowColor = successBorderColor.withOpacity(0.5);
        currentBorderWidth = 1.5;
        break;
      case ValidationState.invalid:
        currentBorderColor = errorBorderColor;
        currentGlowColor = errorBorderColor.withOpacity(0.5);
        currentBorderWidth = 1.5;
        break;
      case ValidationState.none:
      default:
        currentBorderColor = enabledBorderColor;
        // Glow color determined by focus below
        break;
    }

    return Focus(
      child: Builder(builder: (context) {
        final bool hasFocus = Focus.of(context).hasFocus;
        // Apply focused border color if focused and not in a validation state
        final Color displayBorderColor = hasFocus && validationState == ValidationState.none
            ? focusedBorderColor
            : currentBorderColor;
        final double displayBorderWidth = hasFocus || validationState != ValidationState.none
            ? 1.5
            : 1.0;
        final Color? displayGlowColor = hasFocus && validationState == ValidationState.none
            ? focusedBorderColor.withOpacity(0.3) // Subtle glow on focus
            : currentGlowColor;

        return AnimatedContainer(
          duration: animationDuration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: displayGlowColor != null ? [
              BoxShadow(
                color: displayGlowColor,
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ] : [],
          ),
          child: TextFormField(
            controller: controller,
            style: style ?? TextStyle(color: textColor),
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            textAlign: textAlign,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              labelStyle: TextStyle(color: hintColor),
              hintStyle: TextStyle(color: hintColor.withOpacity(0.7)),
              errorText: validationState == ValidationState.invalid ? errorText : null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              counterText: "",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: enabledBorderColor, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: errorBorderColor, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: errorBorderColor, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: displayBorderColor, width: displayBorderWidth),
              ),
              filled: true,
              fillColor: fillColor,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        );
      }),
    );
  }
} 