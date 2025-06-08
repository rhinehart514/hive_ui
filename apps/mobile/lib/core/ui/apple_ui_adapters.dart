import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

/// UI adapters for Apple platforms to provide iOS/macOS styled components
/// while maintaining HIVE's dark theme aesthetic.
class AppleUIAdapters {
  /// Singleton instance
  static final AppleUIAdapters _instance = AppleUIAdapters._internal();
  
  /// Factory constructor
  factory AppleUIAdapters() => _instance;
  
  /// Private constructor
  AppleUIAdapters._internal();
  
  /// Returns true if we're on an Apple platform
  bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
  
  /// HIVE brand colors
  static const Color baseColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFEEB700);
  
  /// Returns a platform-adapted app bar
  PreferredSizeWidget getAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
  }) {
    if (isApplePlatform) {
      return CupertinoNavigationBar(
        backgroundColor: backgroundColor ?? surfaceColor.withOpacity(0.85),
        border: const Border(bottom: BorderSide(color: Colors.transparent)),
        middle: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        trailing: actions != null && actions.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              )
            : null,
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor ?? surfaceColor,
        elevation: 0,
      );
    }
  }
  
  /// Returns a platform-adapted scaffold
  Widget getScaffold({
    required BuildContext context,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Color? backgroundColor,
    bool resizeToAvoidBottomInset = true,
  }) {
    if (isApplePlatform) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? baseColor,
        navigationBar: appBar as CupertinoNavigationBar?,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        child: SafeArea(
          bottom: bottomNavigationBar == null,
          child: Column(
            children: [
              Expanded(child: body),
              if (bottomNavigationBar != null) bottomNavigationBar,
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor ?? baseColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    }
  }
  
  /// Returns a platform-adapted bottom navigation bar
  Widget getBottomNavigationBar({
    required BuildContext context,
    required List<BottomNavigationBarItem> items,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    if (isApplePlatform) {
      return CupertinoTabBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.black.withOpacity(0.95),
        activeColor: accentColor,
        inactiveColor: Colors.white.withOpacity(0.6),
        border: const Border(top: BorderSide(color: Colors.transparent)),
      );
    } else {
      return BottomNavigationBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.black,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );
    }
  }
  
  /// Returns a platform-adapted button
  Widget getButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isDestructive = false,
    IconData? icon,
  }) {
    if (isApplePlatform) {
      final Color textColor = isDestructive 
          ? CupertinoColors.destructiveRed 
          : (isPrimary ? Colors.black : Colors.white);
      
      final Color backgroundColor = isPrimary 
          ? (isDestructive ? CupertinoColors.destructiveRed : Colors.white)
          : Colors.transparent;
      
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isPrimary ? backgroundColor : null,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
            )
          : TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: isDestructive ? Colors.red : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
            );
    }
  }
  
  /// Returns a platform-adapted text field
  Widget getTextField({
    required BuildContext context,
    required String placeholder,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefix,
    Widget? suffix,
    FocusNode? focusNode,
  }) {
    if (isApplePlatform) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        prefix: prefix,
        suffix: suffix,
        focusNode: focusNode,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        style: const TextStyle(color: Colors.white),
        placeholderStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
      );
    } else {
      return TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        focusNode: focusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: surfaceColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }
  
  /// Returns a platform-adapted card
  Widget getCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    final cardWidget = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
    
    if (onTap != null) {
      if (isApplePlatform) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: cardWidget,
        );
      } else {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          child: cardWidget,
        );
      }
    } else {
      return cardWidget;
    }
  }
  
  /// Returns a platform-adapted glass card
  Widget getGlassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    final glassWidget = GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: borderRadius ?? 8,
      blur: 8,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
    
    final containerWidget = Container(
      margin: margin ?? const EdgeInsets.all(0),
      child: glassWidget,
    );
    
    if (onTap != null) {
      if (isApplePlatform) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: containerWidget,
        );
      } else {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          child: containerWidget,
        );
      }
    } else {
      return containerWidget;
    }
  }
  
  /// Returns a platform-adapted segmented control
  Widget getSegmentedControl<T extends Object>({
    required BuildContext context,
    required Map<T, Widget> children,
    required T groupValue,
    required ValueChanged<T?> onValueChanged,
  }) {
    if (isApplePlatform) {
      return CupertinoSegmentedControl<T>(
        children: children,
        groupValue: groupValue,
        onValueChanged: onValueChanged,
        unselectedColor: surfaceColor,
        selectedColor: accentColor,
        borderColor: Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.all(4),
      );
    } else {
      return SegmentedButton<T>(
        segments: children.entries.map((entry) {
          return ButtonSegment<T>(
            value: entry.key,
            label: entry.value,
          );
        }).toList(),
        selected: {groupValue},
        onSelectionChanged: (Set<T> selected) {
          if (selected.isNotEmpty) {
            onValueChanged(selected.first);
          }
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return accentColor;
            }
            return surfaceColor;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.black;
            }
            return Colors.white;
          }),
        ),
      );
    }
  }
  
  /// Returns a platform-adapted slider
  Widget getSlider({
    required BuildContext context,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
  }) {
    if (isApplePlatform) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: accentColor,
        thumbColor: Colors.white,
      );
    } else {
      return Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: accentColor,
        inactiveColor: Colors.white.withOpacity(0.3),
      );
    }
  }
  
  /// Returns a platform-adapted switch
  Widget getSwitch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    if (isApplePlatform) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: accentColor,
        trackColor: surfaceColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: accentColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
      );
    }
  }
} 