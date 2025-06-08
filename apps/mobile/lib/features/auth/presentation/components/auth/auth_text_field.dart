import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A styled text field component for authentication forms
class AuthTextField extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Label text for the field
  final String label;

  /// Icon to display
  final IconData icon;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// Optional suffix icon
  final Widget? suffixIcon;

  /// Error text to display
  final String? errorText;

  /// Text input type
  final TextInputType keyboardType;

  /// Focus node for the field
  final FocusNode? focusNode;

  /// Callback when text changes
  final Function(String)? onChanged;

  /// Creates an AuthTextField
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
        ),
      ),
    );
  }
}
