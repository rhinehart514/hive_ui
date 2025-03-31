import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// A widget for displaying user's residence and interests/tags on their profile
class ProfileTagsSection extends StatelessWidget {
  /// The user's residence (e.g., "Bursley Hall")
  final String residence;

  /// List of the user's interests
  final List<String>? interests;

  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Callback when the "Add" tag button is tapped
  final VoidCallback? onAddTagTapped;

  /// Whether to use compact mode for mobile
  final bool isCompact;

  /// Whether to show the add button (false when moved to top left)
  final bool showAddButton;

  const ProfileTagsSection({
    super.key,
    required this.residence,
    this.interests,
    required this.isCurrentUser,
    this.onAddTagTapped,
    this.isCompact = false,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasInterests = interests != null && interests!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show the section title if not already showing in parent
        if (showAddButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tags',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCurrentUser)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showInterestsSearch(context),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(isCompact ? 4.0 : 8.0),
                      child: HugeIcon(
                        icon: hasInterests ? HugeIcons.tag : HugeIcons.add,
                        color: AppColors.gold,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (showAddButton) SizedBox(height: isCompact ? 8 : 12),

        // Tags
        Wrap(
          spacing: isCompact ? 6 : 8,
          runSpacing: isCompact ? 6 : 8,
          children: [
            // Show residence tag
            _buildTag(residence, Icons.home),

            // Show interest tags
            if (hasInterests)
              ...interests!
                  .take(isCompact ? 5 : interests!.length)
                  .map((interest) => GestureDetector(
                        onTap: isCurrentUser
                            ? () => _showInterestsSearch(context)
                            : null,
                        child: _buildTag(interest, Icons.star),
                      )),

            // If compact mode and we have more interests than shown, add a +X more tag
            if (isCompact && hasInterests && interests!.length > 5)
              _buildMoreTag(interests!.length - 5),

            // Show add button if no interests and user can edit (and we're supposed to show it)
            if (!hasInterests && isCurrentUser && showAddButton)
              GestureDetector(
                onTap: () => _showInterestsSearch(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 12,
                    vertical: isCompact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.gold,
                        size: isCompact ? 14 : 16,
                      ),
                      SizedBox(width: isCompact ? 2 : 4),
                      Text(
                        'Add Interests',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: isCompact ? 10 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: isCompact ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Show a "+X more" tag for compact mode when there are too many interests
  Widget _buildMoreTag(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        '+$count more',
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Shows a search dialog for interests
  void _showInterestsSearch(BuildContext context) {
    if (onAddTagTapped != null) {
      HapticFeedback.mediumImpact();
      onAddTagTapped!();
    }
  }
}
