import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart'; // Correct import for spacing and radii

class FeedItemCard extends StatelessWidget {
  const FeedItemCard({
    super.key,
    // Add required data parameters later (e.g., user, post content)
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual feed item data and structure
    return Card(
      color: AppColors.dark2, // Corrected: Use dark2 for #1E1E1E
      elevation: 0, // Minimal elevation, rely on bg contrast
      margin: const EdgeInsets.symmetric(
        vertical: AppTheme.spacing12, // Corrected: Use AppTheme constants
        horizontal: AppTheme.spacing16, // Corrected: Use AppTheme constants
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm), // Corrected: Use AppTheme radiusSm for 8px
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16), // Corrected: Use AppTheme constants
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  // Placeholder background
                  backgroundColor: AppColors.textTertiary, // Correct (uses existing constant)
                  // backgroundImage: NetworkImage(userData.avatarUrl), // Later
                ),
                const SizedBox(width: AppTheme.spacing12), // Corrected: Use AppTheme constants
                Expanded( // Wrap with Expanded
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Username Placeholder',
                        style: TextStyle(
                          color: AppColors.textPrimary, // Correct (uses existing constant)
                          fontWeight: FontWeight.w600, // Semi-bold
                          fontSize: 14, // Body size
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4), // Corrected: Use AppTheme constants
                      const Text(
                        '2 hours ago • Placeholder Context',
                        style: TextStyle(
                          color: AppColors.textSecondary, // Correct (uses existing constant)
                          fontSize: 12, // Small size
                        ),
                      ),
                    ],
                  ),
                ),
                // Optional: More actions icon (e.g., report, block)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary), // Correct (uses existing constant)
                  onPressed: () {
                    // TODO: Implement more actions
                  },
                  tooltip: 'More options',
                  padding: EdgeInsets.zero, // Ensure minimal padding
                  constraints: const BoxConstraints(), // Remove excessive constraints
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16), // Corrected: Use AppTheme constants

            // --- Body ---
            const Text(
              'This is placeholder text for the main content of the feed item. It should be replaced with actual post data. We need to adhere to line height and character limits for readability.',
              style: TextStyle(
                color: AppColors.textPrimary, // Correct (uses existing constant)
                fontSize: 14, // Body size
                height: 1.6, // Line height
              ),
            ),
            // Placeholder for Media (Image/Video)
            // AspectRatio(aspectRatio: 16/9, child: Container(color: Colors.grey)),
            const SizedBox(height: AppTheme.spacing16), // Corrected: Use AppTheme constants

            // --- Actions Footer (No Vanity Metrics) ---
            // Use Padding to ensure buttons don't touch card edges if needed
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacing8), // Add some space above buttons
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute buttons
                children: [
                  // Use Flexible or Expanded if labels might overflow
                  Flexible(child: _buildActionButton(context, Icons.chat_bubble_outline, 'Discuss')),
                  Flexible(child: _buildActionButton(context, Icons.bookmark_border, 'Save')),
                  Flexible(child: _buildActionButton(context, Icons.repeat, 'React')), // Label removed for icon-only example
                  // Flexible(child: _buildActionButton(context, Icons.ios_share, 'Share')), // Platform-specific share
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Action Button to resemble a Chip using TextButton styling
  Widget _buildActionButton(BuildContext context, IconData icon, [String? label]) {
    final textButtonStyle = Theme.of(context).textButtonTheme.style;

    return TextButton.icon(
      style: textButtonStyle?.copyWith(
        // Enforce Chip-like appearance from theme/style guide
        minimumSize: MaterialStateProperty.all(const Size(0, 36)), // 36px height, variable width
        padding: MaterialStateProperty.all(
          // Adjust padding for chip feel - less vertical, more horizontal if label exists
          EdgeInsets.symmetric(
            horizontal: label != null ? AppTheme.spacing12 : AppTheme.spacing8,
            vertical: AppTheme.spacing4,
          ),
        ),
        // Use pill shape from theme (assuming radiusFull or similar defined)
        // If TextButtonTheme doesn't define pill shape, override here
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            // Use AppTheme.radiusFull or a specific value like 24 if defined
            borderRadius: BorderRadius.circular(AppTheme.radiusFull), // Pill shape
          ),
        ),
        foregroundColor: MaterialStateProperty.all(AppColors.textSecondary),
        overlayColor: MaterialStateProperty.all(AppColors.ripple), // Use ripple color from theme
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center, // Center icon and text
      ),
      icon: Icon(icon, size: 18), // Slightly smaller icon for chips
      label: label != null
          ? Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink(), // No label text if null
      onPressed: () {
        // Add haptic feedback
        HapticFeedback.lightImpact();
        // TODO: Implement actual action logic
        print('Action button tapped: ${label ?? "Icon only"}'); // Placeholder action
      },
    );
  }
} 