import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/space.dart';

/// A card component for recommended spaces that supports both
/// horizontal and vertical layouts based on context
class RecommendedSpaceCard extends ConsumerWidget {
  /// The space to display
  final Space space;

  /// Optional custom image URL to override space.imageUrl
  final String? imageUrl;

  /// Short pitch/intro about the space (1-2 lines)
  final String? pitch;

  /// Whether to show in horizontal layout
  final bool isHorizontal;

  /// Called when the join button is tapped
  final VoidCallback? onJoin;

  /// Called when the card is tapped
  final VoidCallback? onTap;

  /// Constructor
  const RecommendedSpaceCard({
    Key? key,
    required this.space,
    this.imageUrl,
    this.pitch,
    this.isHorizontal = true,
    this.onJoin,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        width: isHorizontal ? 280 : double.infinity,
        height: isHorizontal ? 200 : 160,
        margin: const EdgeInsets.only(right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
          ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isHorizontal ? _buildHorizontalLayout() : _buildVerticalLayout(),
      ),
    );
  }

  /// Build horizontal card layout (for feed scroll)
  Widget _buildHorizontalLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Space icon + name
          _buildHeader(),

          const SizedBox(height: 8),

          // Subheadline: short pitch/intro
          _buildSubheadline(),

          const Spacer(),

          // Stats row
          _buildStats(),

          const SizedBox(height: 16),

          // CTA button
          _buildCTA(),
        ],
      ),
    );
  }

  /// Build vertical card layout (for spaces tab)
  Widget _buildVerticalLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Space icon and stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Space icon
              _buildSpaceIcon(),

              const Spacer(),

              // Stats
              _buildStats(),
            ],
          ),

          const SizedBox(width: 16),

          // Right column: Name, pitch, and CTA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space name
                Text(
                  space.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    letterSpacing: -0.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Subheadline
                _buildSubheadline(),

                const Spacer(),

                // CTA
                _buildCTA(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the header with space icon and name
  Widget _buildHeader() {
    return Row(
      children: [
        _buildSpaceIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                space.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  letterSpacing: -0.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (space.organization != null)
                Text(
                  space.organization!.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the space icon/avatar
  Widget _buildSpaceIcon() {
    final effectiveImageUrl = imageUrl ?? space.imageUrl;

    if (effectiveImageUrl != null && effectiveImageUrl.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardBackground,
          image: DecorationImage(
            image: NetworkImage(effectiveImageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: space.primaryColor.withOpacity(0.15),
      ),
      child: Center(
        child: Icon(
          space.icon,
          color: space.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  /// Build the subheadline/pitch section
  Widget _buildSubheadline() {
    final effectivePitch = pitch ?? space.description;

    return Text(
      effectivePitch,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build the stats section
  Widget _buildStats() {
    return Row(
      children: [
        // Member count
        const Icon(
          Icons.people_outline,
          color: AppColors.textTertiary,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${space.metrics.memberCount}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Members',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
            letterSpacing: 0.2,
          ),
        ),

        const SizedBox(width: 16),

        // Events count
        if (space.metrics.weeklyEvents > 0) ...[
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${space.metrics.weeklyEvents}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Events',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  /// Build the call-to-action button
  Widget _buildCTA() {
    if (space.isJoined) {
      return const SizedBox.shrink(); // No button if already joined
    }
    
    return TextButton(
        onPressed: () {
        if (onJoin != null) {
          HapticFeedback.mediumImpact();
          onJoin!();
        }
        },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.yellow,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.yellow.withOpacity(0.15);
            }
            return null;
          },
          ),
        ),
        child: Text(
        'Join Space',
        style: GoogleFonts.inter(
          color: AppColors.yellow,
            fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
