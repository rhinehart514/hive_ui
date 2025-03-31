import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget for displaying user interests as tags in the profile
class ProfileInterestTag extends StatelessWidget {
  /// The interest text to display
  final String interest;

  /// Whether the tag is selected
  final bool isSelected;

  /// Callback when the tag is tapped
  final VoidCallback? onTap;

  const ProfileInterestTag({
    super.key,
    required this.interest,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.grey[800]!.withOpacity(0.4)
              : Colors.grey[800]!.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.grey.withOpacity(0.6)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          interest,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
