import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Input variants for the standardized HiveTextField
enum HiveInputVariant {
  /// Standard text input
  text,

  /// Password input with optional show/hide functionality
  password,

  /// Search input with search icon
  search,

  /// Textarea input for multi-line text
  textarea
}

/// A standardized text input component that follows HIVE's design system
class HiveTextField extends StatefulWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// The label/hint text to display
  final String hintText;

  /// Optional variant style
  final HiveInputVariant variant;

  /// Optional leading icon
  final IconData? prefixIcon;

  /// Optional trailing icon
  final IconData? suffixIcon;

  /// Optional callback when the suffix icon is pressed
  final VoidCallback? onSuffixPressed;

  /// Optional callback when the text field changes
  final ValueChanged<String>? onChanged;

  /// Whether the text field is enabled
  final bool enabled;

  /// Whether to provide haptic feedback on interaction
  final bool hapticFeedback;

  /// Optional validator function
  final String? Function(String?)? validator;

  /// Optional error text to display
  final String? errorText;

  /// Optional text input action
  final TextInputAction? textInputAction;

  /// Optional keyboard type
  final TextInputType? keyboardType;

  /// Optional maximum number of lines (for textarea)
  final int? maxLines;

  /// Optional minimum number of lines (for textarea)
  final int? minLines;

  /// Optional maximum length of input
  final int? maxLength;

  /// Optional input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Constructor
  const HiveTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.variant = HiveInputVariant.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.onChanged,
    this.enabled = true,
    this.hapticFeedback = true,
    this.validator,
    this.errorText,
    this.textInputAction,
    this.keyboardType,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<HiveTextField> createState() => _HiveTextFieldState();
}

class _HiveTextFieldState extends State<HiveTextField> {
  /// Whether the password is visible (for password variant)
  bool _obscureText = true;

  /// Focus node to track field focus
  final FocusNode _focusNode = FocusNode();

  /// Whether the field is focused
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.variant == HiveInputVariant.password;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// Handle focus change
  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });

      if (_isFocused && widget.hapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Handle suffix icon press (e.g., toggle password visibility)
  void _handleSuffixPressed() {
    if (widget.variant == HiveInputVariant.password) {
      setState(() {
        _obscureText = !_obscureText;
      });

      if (widget.hapticFeedback) {
        HapticFeedback.selectionClick();
      }
    } else if (widget.onSuffixPressed != null) {
      if (widget.hapticFeedback) {
        HapticFeedback.selectionClick();
      }
      widget.onSuffixPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine keyboardType based on variant
    final TextInputType keyboardType =
        widget.keyboardType ?? _getKeyboardType();

    // Determine obscureText based on variant and state
    final bool obscureText =
        widget.variant == HiveInputVariant.password && _obscureText;

    // Determine maxLines based on variant and provided value
    final int? maxLines = _getMaxLines();

    // Determine minLines based on variant and provided value
    final int? minLines = _getMinLines();

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      keyboardType: keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
      ),
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.inter(
          color: Colors.grey[500],
          fontSize: 16,
        ),
        errorText: widget.errorText,
        errorStyle: GoogleFonts.inter(
          color: AppColors.error,
          fontSize: 12,
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        prefixIcon: widget.prefixIcon != null ||
                widget.variant == HiveInputVariant.search
            ? Icon(
                widget.prefixIcon ?? Icons.search,
                color: _isFocused ? AppColors.gold : Colors.grey[500],
                size: 20,
              )
            : null,
        suffixIcon: _buildSuffixIcon(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                widget.errorText != null ? AppColors.error : Colors.grey[700]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                widget.errorText != null ? AppColors.error : Colors.grey[700]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.errorText != null ? AppColors.error : AppColors.gold,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// Build the suffix icon based on variant and state
  Widget? _buildSuffixIcon() {
    // For password variant, show toggle visibility icon
    if (widget.variant == HiveInputVariant.password) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _isFocused ? AppColors.gold : Colors.grey[500],
          size: 20,
        ),
        onPressed: _handleSuffixPressed,
      );
    }

    // For search variant, show clear icon if there's text
    if (widget.variant == HiveInputVariant.search &&
        widget.controller != null &&
        widget.controller!.text.isNotEmpty) {
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: Colors.grey[500],
          size: 20,
        ),
        onPressed: () {
          widget.controller?.clear();
          if (widget.onChanged != null) {
            widget.onChanged!('');
          }
          if (widget.hapticFeedback) {
            HapticFeedback.selectionClick();
          }
        },
      );
    }

    // For custom suffix icon
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: _isFocused ? AppColors.gold : Colors.grey[500],
          size: 20,
        ),
        onPressed: widget.onSuffixPressed != null ? _handleSuffixPressed : null,
      );
    }

    return null;
  }

  /// Get keyboard type based on variant
  TextInputType _getKeyboardType() {
    switch (widget.variant) {
      case HiveInputVariant.search:
        return TextInputType.text;
      case HiveInputVariant.textarea:
        return TextInputType.multiline;
      case HiveInputVariant.password:
        return TextInputType.visiblePassword;
      case HiveInputVariant.text:
        return TextInputType.text;
    }
  }

  /// Get max lines based on variant
  int? _getMaxLines() {
    if (widget.maxLines != null) {
      return widget.maxLines;
    }

    switch (widget.variant) {
      case HiveInputVariant.textarea:
        return 5;
      case HiveInputVariant.password:
        return 1;
      case HiveInputVariant.search:
      case HiveInputVariant.text:
        return 1;
    }
  }

  /// Get min lines based on variant
  int? _getMinLines() {
    if (widget.minLines != null) {
      return widget.minLines;
    }

    switch (widget.variant) {
      case HiveInputVariant.textarea:
        return 3;
      default:
        return null;
    }
  }
}
