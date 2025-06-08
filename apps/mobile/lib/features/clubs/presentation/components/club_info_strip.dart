import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Models
import 'package:hive_ui/models/club.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';
// import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/extensions/box_decoration_extensions.dart';

/// A horizontal strip that displays club quick information
/// Used right below the header in the club space
class ClubInfoStrip extends StatelessWidget {
  final Club club;
  final EdgeInsets padding;

  const ClubInfoStrip({
    Key? key,
    required this.club,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pills
          if (club.categories.isNotEmpty) _buildCategoryPills(),

          if (club.categories.isNotEmpty) const SizedBox(height: 16),

          // Location and website row
          if (club.location != null || club.website != null)
            _buildMetadataRow(),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final category in club.categories)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ).addGlassmorphism(),
              child: Text(
                category,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (club.location != null)
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      club.location!,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (club.location != null && club.website != null)
            const SizedBox(width: 16),
          if (club.website != null)
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.link,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      club.website!
                          .replaceFirst('https://', '')
                          .replaceFirst('http://', ''),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
