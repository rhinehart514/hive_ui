import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that displays a loading state for spaces
class SpacesLoadingState extends StatelessWidget {
  /// Constructor
  const SpacesLoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.gold,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading spaces...',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
