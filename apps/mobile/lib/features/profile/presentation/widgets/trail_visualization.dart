import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_ui/features/profile/domain/models/trail_entry.dart';
import 'package:hive_ui/features/profile/presentation/providers/trail_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// Widget for visualizing a user's activity trail
class TrailVisualization extends ConsumerWidget {
  /// User ID to show trail for, null means current user
  final String? userId;

  /// Maximum number of entries to show
  final int maxEntries;
  
  /// Whether to show the header
  final bool showHeader;

  const TrailVisualization({
    super.key,
    this.userId,
    this.maxEntries = 50,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailAsync = userId != null
        ? ref.watch(userTrailProvider(userId!))
        : ref.watch(currentUserTrailProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) _buildHeader(context),
          const SizedBox(height: 16),
          trailAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return _buildEmptyState(context);
              }
              
              // Group entries by date
              final groupedEntries = ref.watch(groupedTrailEntriesProvider(entries));
              
              return _buildTimeline(context, groupedEntries);
            },
            loading: () => _buildLoadingState(),
            error: (error, stackTrace) => _buildErrorState(context, error, ref),
          ),
        ],
      ),
    );
  }

  /// Build the header for the trail section
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            'Your Trail',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.gold),
            onPressed: () => _showTrailInfoDialog(context),
          ),
        ],
      ),
    );
  }

  /// Show information dialog about the trail
  void _showTrailInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'About Your Trail',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your Trail shows your journey through the Hive community. It captures your participation in spaces, events, and other activities across campus.',
          style: GoogleFonts.inter(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the timeline visualization
  Widget _buildTimeline(BuildContext context, Map<String, List<TrailEntry>> groupedEntries) {
    // Sort the keys by recency (Today, Yesterday, etc.)
    final sortOrder = {
      'Today': 0,
      'Yesterday': 1,
      'This Week': 2,
      'This Month': 3,
      'Last Month': 4,
      'This Year': 5,
      'Earlier': 6,
    };
    
    final sortedKeys = groupedEntries.keys.toList()
      ..sort((a, b) => (sortOrder[a] ?? 99).compareTo(sortOrder[b] ?? 99));
    
    // Use a ListView.builder instead of Column for better performance and scrolling
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedKeys.length,
      itemBuilder: (context, keyIndex) {
        final dateKey = sortedKeys[keyIndex];
        final entriesForDate = groupedEntries[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                dateKey,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: entriesForDate.length > maxEntries ? maxEntries : entriesForDate.length,
              itemBuilder: (context, entryIndex) {
                final entry = entriesForDate[entryIndex];
                return _buildTrailEntryCard(context, entry);
              },
            ),
          ],
        );
      },
    );
  }

  /// Build a card for a single trail entry
  Widget _buildTrailEntryCard(BuildContext context, TrailEntry entry) {
    // Determine icon based on activity type
    IconData getIconForActivity(TrailActivityType type) {
      switch (type) {
        case TrailActivityType.spaceJoin:
          return HugeIcons.constellation;
        case TrailActivityType.eventAttendance:
          return HugeIcons.calendar;
        case TrailActivityType.creation:
          return Icons.create; // Using standard Icons instead of custom
        case TrailActivityType.signal:
          return Icons.arrow_circle_up; // Using standard Icons instead of custom
        case TrailActivityType.achievement:
          return Icons.emoji_events; // Using standard Icons instead of custom
      }
    }
    
    // Determine color based on activity type
    Color getColorForActivity(TrailActivityType type) {
      switch (type) {
        case TrailActivityType.spaceJoin:
          return Colors.purple;
        case TrailActivityType.eventAttendance:
          return Colors.blue;
        case TrailActivityType.creation:
          return Colors.orange;
        case TrailActivityType.signal:
          return Colors.green;
        case TrailActivityType.achievement:
          return AppColors.gold;
      }
    }
    
    final icon = entry.icon ?? getIconForActivity(entry.activityType);
    final color = getColorForActivity(entry.activityType);
    final formattedTime = DateFormat.jm().format(entry.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: GestureDetector(
        onTap: () => _showTrailEntryDetails(context, entry),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            color: AppColors.cardBackground.withOpacity(0.7),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (entry.description != null)
                      Text(
                        entry.description!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: entry.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.black12,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black12,
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show detailed view of a trail entry
  void _showTrailEntryDetails(BuildContext context, TrailEntry entry) {
    final formatter = DateFormat('MMMM d, yyyy • h:mm a');
    final formattedDate = formatter.format(entry.timestamp);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.imageUrl != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: entry.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              entry.title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (entry.description != null) ...[
              Text(
                entry.description!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              formattedDate,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the empty state when there are no entries
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Trail is Empty',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Start your journey by joining spaces, attending events, and engaging with the community.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      ),
    );
  }

  /// Build the error state
  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load trail',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Refresh the provider
                ref.refresh(userId != null
                    ? userTrailProvider(userId!)
                    : currentUserTrailProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
} 