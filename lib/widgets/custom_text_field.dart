import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/widgets/error_text.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final TextInputType? keyboardType;
  final double width;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final bool obscureText;
  final void Function(String)? onChanged;
  final VoidCallback? onToggleVisibility;

  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.width,
    required this.obscureText,
    this.label,
    this.keyboardType,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.validator,
    this.decoration,
    this.onChanged,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.white54,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
      ),
      filled: true,
      fillColor: const Color(0xFF111111),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF242424)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF242424)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      errorStyle: const TextStyle(height: 0),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      suffixIcon: onToggleVisibility != null ? IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.white54,
        ),
        onPressed: onToggleVisibility,
      ) : null,
    );

    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Container(
              width: width,
              height: 56,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.03),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.01),
                    blurRadius: 6,
                    spreadRadius: -1,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                autocorrect: autocorrect,
                enableSuggestions: enableSuggestions,
                inputFormatters: inputFormatters,
                obscureText: obscureText,
                onChanged: (value) {
                  state.didChange(value);
                  onChanged?.call(value);
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
                decoration: (decoration?.copyWith(
                  hintText: hintText,
                  suffixIcon: baseDecoration.suffixIcon,
                ) ?? baseDecoration),
              ),
            ),
            if (state.hasError && state.errorText != null)
              ErrorText(state.errorText!),
          ],
        );
      },
    );
  }
} 