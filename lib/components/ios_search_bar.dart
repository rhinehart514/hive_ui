import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';

// Define the searchBarBackground color directly
const Color searchBarBackground = Color(0xFF222222);

/// A search bar styled to look like native iOS search bars
class IOSSearchBar extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;

  /// The hint text to display
  final String hintText;

  /// The callback when the text changes
  final ValueChanged<String>? onChanged;

  /// The callback when the search is submitted
  final ValueChanged<String>? onSubmitted;

  /// The callback when the clear button is tapped
  final VoidCallback? onClear;

  /// The focus node for the text field
  final FocusNode? focusNode;

  /// Creates a new iOS-style search bar
  const IOSSearchBar({
    Key? key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: searchBarBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTheme.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        placeholder: hintText,
        placeholderStyle: AppTheme.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Icon(
            CupertinoIcons.search,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        suffix: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  if (onChanged != null) {
                    onChanged!('');
                  }
                  if (onClear != null) {
                    onClear!();
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
