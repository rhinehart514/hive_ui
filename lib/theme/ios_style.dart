import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';

/// iOS Style Design System for Hive
///
/// This file contains components and extensions to give the app an iOS-like
/// appearance while maintaining Hive's brand identity.

/// Extension methods to add iOS-style behavior to widgets
extension IOSContextExtension on BuildContext {
  /// Shows an iOS-style action sheet with options
  Future<T?> showIOSActionSheet<T>({
    required String title,
    String? message,
    required List<IOSActionSheetAction<T>> actions,
    IOSActionSheetAction<T>? cancelAction,
  }) async {
    return showModalBottomSheet<T>(
      context: this,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.modalOverlay,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.grey600.withOpacity(0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle pill
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title and message
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: AppTheme.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                ...actions.map((action) => _buildActionSheetButton(action)),

                // Cancel button
                if (cancelAction != null) ...[
                  const SizedBox(height: 8),
                  _buildActionSheetButton(cancelAction, isCancel: true),
                  const SizedBox(
                      height: 8 +
                          34), // Extra bottom padding to account for home indicator
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSheetButton<T>(IOSActionSheetAction<T> action,
      {bool isCancel = false}) {
    return Column(
      children: [
        if (!isCancel) const Divider(height: 1, color: Colors.white12),
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(this).pop(action.value);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              action.title,
              style: TextStyle(
                color: action.isDestructive
                    ? AppColors.error
                    : (isCancel ? AppColors.gold : AppColors.textPrimary),
                fontSize: 18,
                fontWeight: isCancel || action.isDefault
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Shows an iOS-style alert dialog
  Future<T?> showIOSAlert<T>({
    required String title,
    String? message,
    List<IOSAlertAction<T>> actions = const [],
  }) {
    return showDialog<T>(
      context: this,
      barrierColor: AppColors.modalOverlay,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: AppColors.grey600.withOpacity(0.9),
            title: Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            content: message != null
                ? Text(
                    message,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  )
                : null,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            buttonPadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, color: Colors.white12),
                  // Horizontal buttons if 2, vertical if more or less
                  if (actions.length == 2)
                    Row(
                      children: [
                        Expanded(
                            child: _buildAlertButton(actions[0], isLeft: true)),
                        Container(width: 1, height: 44, color: Colors.white12),
                        Expanded(child: _buildAlertButton(actions[1])),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: actions.map((action) {
                        final index = actions.indexOf(action);
                        return Column(
                          children: [
                            if (index > 0)
                              Container(height: 1, color: Colors.white12),
                            _buildAlertButton(action),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertButton<T>(IOSAlertAction<T> action, {bool isLeft = false}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(this).pop(action.value);
      },
      child: Container(
        height: 44,
        alignment: Alignment.center,
        child: Text(
          action.title,
          style: TextStyle(
            color: action.isDestructive
                ? AppColors.error
                : (action.isCancel ? AppColors.gold : AppColors.textPrimary),
            fontSize: 17,
            fontWeight: action.isDefault || action.isCancel
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// iOS-style action sheet action model
class IOSActionSheetAction<T> {
  final String title;
  final T? value;
  final bool isDestructive;
  final bool isDefault;

  IOSActionSheetAction({
    required this.title,
    this.value,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

/// iOS-style alert dialog action model
class IOSAlertAction<T> {
  final String title;
  final T? value;
  final bool isDestructive;
  final bool isDefault;
  final bool isCancel;

  IOSAlertAction({
    required this.title,
    this.value,
    this.isDestructive = false,
    this.isDefault = false,
    this.isCancel = false,
  });
}

/// iOS-style button
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isPrimary;
  final bool isSmall;
  final IconData? icon;

  const IOSButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
    this.isSmall = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDestructive
        ? AppColors.error
        : isPrimary
            ? AppColors.black
            : AppColors.gold;

    final Color backgroundColor = isPrimary
        ? isDestructive
            ? AppColors.error
            : AppColors.gold
        : Colors.transparent;

    return GestureDetector(
      onTap: onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: AnimatedOpacity(
        opacity: onPressed != null ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: isSmall
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: isPrimary
                ? null
                : Border.all(
                    color:
                        isDestructive ? AppColors.error : AppColors.cardBorder,
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: textColor,
                  size: isSmall ? 16 : 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: isSmall ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style segmented control
class IOSSegmentedControl<T> extends StatelessWidget {
  final List<IOSSegmentOption<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;

  const IOSSegmentedControl({
    Key? key,
    required this.segments,
    required this.selectedValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: segments.map((segment) {
          final isSelected = segment.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onValueChanged(segment.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    segment.label,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.gold : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// iOS segmented control option
class IOSSegmentOption<T> {
  final String label;
  final T value;

  IOSSegmentOption({
    required this.label,
    required this.value,
  });
}

/// iOS-style switch
class IOSSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const IOSSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value
              ? (activeColor ?? AppColors.gold)
              : Colors.grey.withOpacity(0.4),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style card
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool isTranslucent;
  final VoidCallback? onTap;

  const IOSCard({
    Key? key,
    required this.child,
    this.padding,
    this.isTranslucent = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardWidget = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: isTranslucent
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppColors.cardBorder.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: child,
              ),
            )
          : Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: AppColors.cardBorder,
                  width: 0.5,
                ),
              ),
              child: child,
            ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// iOS-style list item
class IOSListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isDestructive;

  const IOSListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      leadingIcon!,
                      size: 16,
                      color: isDestructive ? AppColors.error : AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? AppColors.error
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onTap != null) ...[
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: Colors.white10),
          ),
      ],
    );
  }
}

/// iOS-style search bar
class IOSSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String placeholder;
  final FocusNode? focusNode;

  const IOSSearchBar({
    Key? key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.placeholder = 'Search',
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.inputBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textSecondary,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        controller.clear();
                        if (onClear != null) onClear!();
                        if (onChanged != null) onChanged!('');
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.clear,
                          size: 12,
                          color: AppColors.black,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom scroll physics to mimic iOS behavior
class IOSScrollPhysics extends BouncingScrollPhysics {
  const IOSScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  IOSScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return IOSScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) =>
      0.8; // Increased friction to reduce shakiness

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.8, // Increased mass for stability
        stiffness: 120.0, // Increased stiffness for less bouncy behavior
        damping: 2.0, // Increased damping to reduce oscillation
      );
}

/// Custom scroll physics with no bounce effect
class NonBouncingScrollPhysics extends ClampingScrollPhysics {
  const NonBouncingScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  NonBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NonBouncingScrollPhysics(parent: buildParent(ancestor));
  }
}
