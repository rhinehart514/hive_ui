import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const black = Colors.black;
  static const white = Colors.white;
  static const gold = Color(0xFFFFD700);
  static const grey900 = Color(0xFF212121);
  static const grey600 = Color(0xFF757575);
  static const red = Colors.red;
  static const green = Colors.green;
  static const yellow = Color(0xFFFFd700);
}

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: const Color(0xFFEEBA2A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFEEBA2A),
      secondary: Color(0xFFEEBA2A),
      surface: Colors.black,
    ),
    useMaterial3: true,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}

class AppTextStyle {
  static const headlineLarge = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const bodyLarge = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
} 