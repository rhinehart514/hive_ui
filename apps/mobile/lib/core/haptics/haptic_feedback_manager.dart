import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Haptic feedback manager for HIVE UI 
/// Implements the Haptic Feedback Matrix defined in brand_aesthetic.md Section 7
///
/// Provides standardized haptic patterns for different interaction types
/// and enforces haptic governance rules (e.g., no double taps <300ms)
class HapticFeedbackManager {
  // Singleton instance
  static final HapticFeedbackManager _instance = HapticFeedbackManager._internal();
  factory HapticFeedbackManager() => _instance;
  HapticFeedbackManager._internal();

  // Haptic governance - prevent too frequent haptics
  DateTime? _lastHapticTime;
  static const int _minHapticIntervalMs = 300; // No haptics within 300ms
  
  // Reduced haptics setting - can be toggled by users who prefer less haptic feedback
  bool _reduceHaptics = false;
  bool get reduceHaptics => _reduceHaptics;
  set reduceHaptics(bool value) {
    _reduceHaptics = value;
  }
  
  /// Initialize the haptic manager
  Future<void> init() async {
    // Nothing to initialize yet, but could add platform checks
    // or device capability detection in the future
  }

  /// Determines if haptic feedback should be allowed based on governance rules
  bool _shouldAllowHaptic() {
    if (_reduceHaptics) return false;
    
    final now = DateTime.now();
    if (_lastHapticTime != null) {
      final timeSinceLastHaptic = now.difference(_lastHapticTime!).inMilliseconds;
      if (timeSinceLastHaptic < _minHapticIntervalMs) {
        return false;
      }
    }
    
    _lastHapticTime = now;
    return true;
  }

  /// Tap feedback - Light impact (brand_aesthetic.md Section 7.1)
  /// Used for standard button taps and selection changes
  Future<void> lightTap() async {
    if (!_shouldAllowHaptic()) return;
    debugPrint("HAPTIC: Attempting lightTap");
    await HapticFeedback.lightImpact();
  }
  
  /// Deep Hold feedback - Medium impact (brand_aesthetic.md Section 7.1)
  /// Used for long-press actions and more significant interactions
  Future<void> mediumImpact() async {
    if (!_shouldAllowHaptic()) return;
    await HapticFeedback.mediumImpact();
  }
  
  /// Success Submit feedback - Success haptic (brand_aesthetic.md Section 7.1)
  /// Used for completion of important actions
  Future<void> successFeedback() async {
    if (!_shouldAllowHaptic()) return;
    
    // No direct "success" haptic in Flutter, so we simulate it
    // with a vibration pattern that feels like a success
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
  }
  
  /// Error / Blocked feedback - Dual tap alert (brand_aesthetic.md Section 7.1)
  /// Used for error states and denied actions
  Future<void> errorFeedback() async {
    if (!_shouldAllowHaptic()) return;
    
    // Simulate error feedback with a sequence
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }
  
  /// Critical decisions (Join, Pay, Post) - Composite haptic (brand_aesthetic.md Section 7.2)
  /// impact(.medium) + notification(.success/error) chain
  Future<void> criticalActionSuccess() async {
    if (!_shouldAllowHaptic()) return;
    
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await successFeedback();
  }
  
  /// Light selection change (toggle, tab change) - selectionChanged
  /// For subtle state changes (brand_aesthetic.md Section 7.2)
  Future<void> selectionChanged() async {
    if (!_shouldAllowHaptic()) return;
    await HapticFeedback.selectionClick();
  }
  
  /// Join Space haptic - Soft click + tick (brand_aesthetic.md Section 7.3)
  /// Part of the Join Space microinteraction
  Future<void> joinSpace() async {
    if (!_shouldAllowHaptic()) return;
    
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }
  
  /// RSVP Toggle haptic - Small elastic overshoot feeling (brand_aesthetic.md Section 7.3)
  /// For the RSVP toggle microinteraction
  Future<void> rsvpToggle() async {
    if (!_shouldAllowHaptic()) return;
    
    // Simulate the feeling of toggle with "snap"
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 20));
    await HapticFeedback.selectionClick();
  }
  
  /// Event Live Now - Soft haptic loop (brand_aesthetic.md Section 7.3)
  /// For the pulsing ambient border glow
  /// 
  /// Note: This should be used sparingly and can be canceled with cancelLiveHaptic()
  Timer? _liveHapticTimer;
  
  Future<void> startLiveHaptic() async {
    if (_reduceHaptics) return;
    
    // Cancel any existing timer
    _liveHapticTimer?.cancel();
    
    // Create a repeating gentle haptic
    _liveHapticTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      HapticFeedback.lightImpact();
    });
    
    // Initial haptic
    await HapticFeedback.lightImpact();
  }
  
  void cancelLiveHaptic() {
    _liveHapticTimer?.cancel();
    _liveHapticTimer = null;
  }
  
  /// Override for system accessibility settings
  /// Call this when system settings change, or when user toggles haptic settings
  void updateFromAccessibilitySettings(BuildContext context) {
    // Could check system settings here if Flutter adds API support
    // For now, this is just a placeholder for future implementation
  }
} 