import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/core/animations/shake_animation.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';

/// A branded text field that follows the HIVE design system.
///
/// This component implements the standard text field style with consistent
/// colors, borders, and animations according to HIVE's brand aesthetic.
class BrandedTextField extends StatefulWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Label text displayed above the field
  final String label;

  /// Hint text displayed when the field is empty
  final String? hint;

  /// Whether the text field should obscure text (for passwords)
  final bool obscureText;

  /// Validator function for form validation
  final String? Function(String?)? validator;

  /// Text input type for the keyboard
  final TextInputType keyboardType;

  /// Whether the field should focus automatically
  final bool autofocus;

  /// The next action on the keyboard
  final TextInputAction textInputAction;

  /// Callback when the field is submitted
  final Function(String)? onFieldSubmitted;

  /// Maximum number of lines for the text field
  final int? maxLines;

  /// Maximum length of the text
  final int? maxLength;

  /// Whether the field is enabled
  final bool enabled;

  /// Callback when the field loses focus
  final VoidCallback? onEditingComplete;

  /// List of input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Callback when the text changes
  final Function(String)? onChanged;

  /// Whether to show the counter for character count
  final bool showCounter;

  /// Creates a [BrandedTextField] instance.
  const BrandedTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onEditingComplete,
    this.inputFormatters,
    this.onChanged,
    this.showCounter = false,
  }) : super(key: key);

  @override
  State<BrandedTextField> createState() => _BrandedTextFieldState();
}

class _BrandedTextFieldState extends State<BrandedTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;
  bool _hasError = false;
  bool _showPassword = false;

  // GlobalKey to control the ShakeAnimation
  final GlobalKey<ShakeAnimationState> _shakeKey = GlobalKey<ShakeAnimationState>();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    
    if (!_focusNode.hasFocus && widget.onEditingComplete != null) {
      widget.onEditingComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get text theme for consistent styling
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label text - Use theme style
        Text(
          widget.label,
          // Use labelLarge or similar appropriate style
          // Check AppTypography mapping if needed
          style: textTheme.labelLarge?.copyWith(
            color: _hasFocus ? AppColors.gold : textTheme.labelLarge?.color,
            // Removed hardcoded size/weight/spacing
          ),
        ),
        const SizedBox(height: 8),
        
        // Wrap the TextFormField with ShakeAnimation
        ShakeAnimation(
          key: _shakeKey, // Assign the key
          // Optional: Adjust shakeOffset if needed based on visual testing
          // shakeOffset: 15.0, 
          child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
            // Use theme style for input text
            style: textTheme.bodyLarge?.copyWith(
              color: widget.enabled 
                  ? textTheme.bodyLarge?.color 
                  : AppColors.grey600, // Keep disabled color distinct
               // Removed hardcoded size
          ),
          obscureText: widget.obscureText && !_showPassword,
          validator: (value) {
            final error = widget.validator?.call(value);
              final hadError = _hasError; // Store previous error state
            setState(() {
              _hasError = error != null;
            });
              // Trigger shake and haptic only when error first appears
              if (_hasError && !hadError) {
                _shakeKey.currentState?.shake();
                FeedbackUtil.errorHaptic();
              }
            return error;
          },
          keyboardType: widget.keyboardType,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          inputFormatters: widget.inputFormatters,
          onChanged: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            if (_hasError && widget.validator != null) {
              // Re-validate on change to clear error state when fixed
              final error = widget.validator!(value);
                // No shake/haptic needed when clearing error via typing
              setState(() {
                _hasError = error != null;
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.dark2,
            hintText: widget.hint,
              hintStyle: textTheme.bodyLarge?.copyWith( // Use theme style for hint
              color: AppColors.grey600,
                 // Removed hardcoded size
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterText: widget.showCounter ? null : '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.inputBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.inputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.gold,
                width: 2,
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
                width: 2,
              ),
            ),
              errorStyle: textTheme.bodySmall?.copyWith( // Use theme style for error
              color: AppColors.error,
                // Removed hardcoded size
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.grey600,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                    splashRadius: 20,
                  )
                : null,
            ),
          ),
        ),
      ],
    );
  }
} 