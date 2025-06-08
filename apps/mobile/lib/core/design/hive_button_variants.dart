import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HIVE Button Variants - Essential production-ready button types
/// Extracted from comprehensive testing suite - validated and optimized
class HiveButtonVariants {
  
  // === SECONDARY BUTTONS ===
  
  /// Glass surface secondary button - for secondary actions
  static Widget buildGlassSecondary({
    required String text,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () {
            HapticFeedback.lightImpact();
            onPressed();
          } : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Outlined secondary button - for clear hierarchy
  static Widget buildOutlinedSecondary({
    required String text,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enabled ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () {
            HapticFeedback.lightImpact();
            onPressed();
          } : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: enabled ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === TEXT BUTTONS ===
  
  /// Text button with gold underline growth on hover
  static Widget buildTextButton({
    required String text,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () {
          HapticFeedback.lightImpact();
          onPressed();
        } : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            text,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: enabled ? TextDecoration.underline : null,
              decorationColor: const Color(0xFFFFD700).withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  // === ICON BUTTONS ===
  
  /// Standard icon button with 44x44pt touch target
  static Widget buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
    double size = 44.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          onTap: enabled ? () {
            HapticFeedback.lightImpact();
            onPressed();
          } : null,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  // === LOADING STATES ===
  
  /// Primary button with loading spinner
  static Widget buildLoadingButton({
    required String text,
    bool isLoading = false,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ),
      ),
    );
  }
} 