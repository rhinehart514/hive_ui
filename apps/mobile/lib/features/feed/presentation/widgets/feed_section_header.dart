import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

/// A standard section header used across the feed for various content sections
class FeedSectionHeader extends StatelessWidget {
  /// The title text to display
  final String title;
  
  /// Optional icon to display before the title
  final IconData? icon;
  
  /// Optional onTap callback for the entire header
  final VoidCallback? onTap;
  
  /// Whether to show a "See All" button
  final bool showSeeAll;
  
  /// Optional callback for when "See All" is tapped
  final VoidCallback? onSeeAllTap;

  /// Constructor
  const FeedSectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.onTap,
    this.showSeeAll = false,
    this.onSeeAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title with optional icon
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          
          // Optional "See All" button
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 