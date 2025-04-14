import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A factory class that helps create standardized tiles for club spaces
/// This ensures consistent styling across the app
class ClubSpaceTileFactory {
  // Private constructor to prevent instantiation
  ClubSpaceTileFactory._();

  /// Create a standard container for any club space tile
  ///
  /// Parameters:
  /// - [height]: The tile height (can be null for flexible height)
  /// - [child]: The tile content
  /// - [onTap]: Callback for when the tile is tapped
  /// - [borderRadius]: The tile's corner radius (default: 16)
  static Widget createTile({
    double? height,
    required Widget child,
    VoidCallback? onTap,
    double borderRadius = 16,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create a standard tile header with an icon and title
  ///
  /// Parameters:
  /// - [icon]: The icon to display
  /// - [title]: The title text
  /// - [count]: Optional count to display (e.g., "3 total")
  /// - [iconColor]: Color for the icon (default: white at 70% opacity)
  /// - [titleColor]: Color for the title (default: white)
  /// - [countColor]: Color for the count (default: white at 50% opacity)
  static Widget createTileHeader({
    required IconData icon,
    required String title,
    String? count,
    Color? iconColor,
    Color? titleColor,
    Color? countColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor ?? Colors.white,
          ),
        ),
        if (count != null) ...[
          const Spacer(),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: countColor ?? Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  /// Create a standard button for tiles
  ///
  /// Parameters:
  /// - [label]: The button text
  /// - [onPressed]: Callback for when the button is pressed
  /// - [isTransparent]: Whether to use a transparent background (default: true)
  /// - [isFullWidth]: Whether the button should span the full width (default: true)
  static Widget createTileButton({
    required String label,
    required VoidCallback onPressed,
    bool isTransparent = true,
    bool isFullWidth = true,
    double height = 40,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isTransparent ? Colors.transparent : AppColors.gold,
          foregroundColor: isTransparent ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isTransparent
                ? BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  )
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Create a standard locked state message
  ///
  /// Parameters:
  /// - [message]: The message explaining why the feature is locked
  static Widget createLockedMessage(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: Colors.white30,
        ),
      ),
    );
  }

  /// Create a vertical spacer for use within tiles
  static Widget createSpacer() {
    return const Spacer();
  }

  /// Create a standard horizontal divider for use within tiles
  static Widget createDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 24,
    );
  }

  /// Create a badge for counts or status indicators
  ///
  /// Parameters:
  /// - [label]: The badge text
  /// - [color]: The badge color (default: AppColors.gold)
  static Widget createBadge(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppColors.gold).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? AppColors.gold).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.gold,
        ),
      ),
    );
  }
}
