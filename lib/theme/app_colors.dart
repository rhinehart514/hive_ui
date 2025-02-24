import 'package:flutter/material.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gold = Color(0xFFFFD700);
  static const Color grey600 = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF111111);
  
  // Text colors
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xB3FFFFFF); // white70
  static const Color textTertiary = Color(0x8AFFFFFF); // white54
  static const Color textDisabled = Color(0x61FFFFFF); // white38
  
  // Input colors
  static const Color inputBackground = grey600;
  static const Color inputBorder = Color(0x3DFFFFFF); // white24
  static const Color inputFocused = gold;
  
  // Button colors
  static const Color buttonPrimary = white;
  static const Color buttonSecondary = gold;
  static const Color buttonText = black;
  static const Color buttonDisabled = Color(0x61FFFFFF); // white38
  
  // Card colors
  static const Color cardBackground = grey600;
  static const Color cardBorder = Color(0x1FFFFFFF); // white12
  static const Color cardHover = Color(0xFF242424);
  
  // Divider and separator colors
  static const Color divider = Color(0x3DFFFFFF); // white24
  static const Color separator = Color(0x1FFFFFFF); // white12
  
  // Overlay colors
  static const Color modalOverlay = Color(0x80000000); // black50
  static const Color bottomSheetBackground = grey600;
  
  // Status colors
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color info = Color(0xFF2196F3); // blue
  
  // Interaction colors
  static const Color ripple = Color(0x1FFFFFFF); // white12
  static const Color shimmerBase = grey600;
  static const Color shimmerHighlight = Color(0xFF242424);
} 