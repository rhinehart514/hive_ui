import 'package:flutter/material.dart';

/// Central definition of all animation values for HIVE app
/// Ensures consistency across all UI interactions
class AnimationConstants {
  // Standard durations
  static const Duration veryShort = Duration(milliseconds: 150); // Button presses, micro-interactions
  static const Duration short = Duration(milliseconds: 200);     // Icon state changes
  static const Duration medium = Duration(milliseconds: 300);    // Card expansions, RSVP feedback
  static const Duration long = Duration(milliseconds: 350);      // Modal/sheet openings
  static const Duration veryLong = Duration(milliseconds: 450);  // Complex emphasis animations

  // Curve definitions
  static const Curve standardCurve = Curves.easeOutCubic;        // Default for most animations
  static const Curve entryCurve = Curves.easeOutQuint;           // Modal/dialog entries
  static const Curve exitCurve = Curves.easeInQuad;              // Modal/dialog exits  
  static const Curve emphasizedCurve = Curves.elasticOut;        // Special emphasis (subtle bounce)
  static const Curve tabSwitchCurve = Curves.easeInOut;          // Tab transitions

  // Scale factors
  static const double buttonPressScale = 0.98;                   // Subtle button press feedback
  static const double emphasizedScale = 1.05;                    // Attention-grabbing elements
  static const double dialogEntryScale = 1.02;                   // Slight scale for dialog entries

  // Offset distances (for slide animations)
  static const double smallOffset = 10.0;                        // Small UI element moves
  static const double mediumOffset = 30.0;                       // Content shifts
  static const double largeOffset = 100.0;                       // Major screen transitions

  // Stagger timing
  static const Duration staggerDelay = Duration(milliseconds: 50); // Delay between staggered items
} 