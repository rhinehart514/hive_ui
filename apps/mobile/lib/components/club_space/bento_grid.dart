import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/theme/app_icons.dart';

/// Base class for Bento grid items
abstract class BentoItem extends ConsumerWidget {
  final double height;
  final int span;
  final bool isAnimated;
  final VoidCallback? onTap;

  const BentoItem({
    super.key,
    this.height = 180,
    this.span = 1,
    this.isAnimated = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget content = Material(
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                HapticFeedback.mediumImpact();
                onTap!();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: buildContent(context, ref),
          ),
        ),
      ),
    ).addGlassmorphism(
      blur: GlassmorphismGuide.kCardBlur,
      opacity: 0.05,
    );

    if (!isAnimated) return content;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: content,
    );
  }

  Widget buildContent(BuildContext context, WidgetRef ref);
}

/// Events tool showing upcoming events
class EventsTool extends BentoItem {
  final List<dynamic> events;

  const EventsTool({
    super.key,
    required this.events,
    super.height = 180,
    super.span = 2,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Events',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.white.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Events preview
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'No upcoming events',
                      style: GoogleFonts.outfit(
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        width: 200,
                        margin: EdgeInsets.only(
                          right: index < events.length - 1 ? 12 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Event image
                              Image.network(
                                event.imageUrl,
                                fit: BoxFit.cover,
                              ),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                              // Event info
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event.date,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pinned post tool for club leaders
class PinnedPostTool extends BentoItem {
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime date;

  const PinnedPostTool({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.date,
    super.height = 120,
    super.span = 2,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pin icon
          Row(
            children: [
              const Icon(
                Icons.push_pin,
                size: 16,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                'Pinned Post',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title and preview
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meet the executives tool
class ExecutivesTool extends BentoItem {
  final List<dynamic> executives;

  const ExecutivesTool({
    super.key,
    required this.executives,
    super.height = 200,
    super.span = 2,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meet the Team',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Executives grid
          Expanded(
            child: executives.isEmpty
                ? Center(
                    child: Text(
                      'No executives listed',
                      style: GoogleFonts.outfit(
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: executives.length,
                    itemBuilder: (context, index) {
                      final executive = executives[index];
                      return Column(
                        children: [
                          // Profile image
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold,
                                width: 1,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(executive.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Name
                          Text(
                            executive.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.white,
                            ),
                          ),
                          // Role
                          Text(
                            executive.role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: AppColors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Live chat messaging tool
class MessagingTool extends BentoItem {
  final bool isUnlocked;
  final int messageCount;
  final int memberCount;

  const MessagingTool({
    super.key,
    required this.isUnlocked,
    this.messageCount = 0,
    this.memberCount = 0,
    super.height = 120,
    super.span = 1,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and status
              Row(
                children: [
                  Icon(
                    isUnlocked ? AppIcons.message : Icons.lock_outline,
                    color: isUnlocked
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUnlocked ? 'Club Chat' : 'Chat Locked',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isUnlocked) ...[
                Text(
                  '$messageCount messages',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  '$memberCount members active',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.gold,
                  ),
                ),
              ] else
                Text(
                  'Unlock at 10 followers',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
        if (!isUnlocked)
          Positioned(
            right: 12,
            bottom: 12,
            child: Icon(
              Icons.lock_outline,
              color: AppColors.white.withOpacity(0.2),
              size: 32,
            ),
          ),
      ],
    );
  }
}

/// Grid layout for Bento items
class BentoGrid extends StatelessWidget {
  final List<BentoItem> items;
  final double spacing;
  final EdgeInsets padding;

  const BentoGrid({
    super.key,
    required this.items,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimationLimiter(
        child: Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = (width - spacing) / 2;

              List<Widget> rows = [];
              List<Widget> currentRow = [];
              int currentSpan = 0;

              for (int i = 0; i < items.length; i++) {
                final item = items[i];

                // Calculate item width based on span
                final itemWidget = SizedBox(
                  width: item.span == 2 ? width : itemWidth,
                  child: AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: item,
                      ),
                    ),
                  ),
                );

                // Add to current row if it fits
                if (currentSpan + item.span <= 2) {
                  currentRow.add(itemWidget);
                  currentSpan += item.span;
                } else {
                  // Start new row
                  rows.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: currentRow,
                    ),
                  );
                  rows.add(SizedBox(height: spacing));
                  currentRow = [itemWidget];
                  currentSpan = item.span;
                }
              }

              // Add remaining items
              if (currentRow.isNotEmpty) {
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: currentRow,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows,
              );
            },
          ),
        ),
      ),
    );
  }
}
