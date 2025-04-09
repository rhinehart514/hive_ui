import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/providers/feed_provider.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/components/event_card/event_card.dart';
import 'package:hive_ui/features/spaces/data/repositories/space_repository_impl.dart';
import 'dart:ui';
import 'dart:math';
import '../styles/feed_theme.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';

// Add the spaceRepositoryProvider
final spaceRepositoryProvider = Provider<SpaceRepositoryImpl>((ref) {
  final dataSource = SpacesFirestoreDataSource();
  return SpaceRepositoryImpl(dataSource);
});

/// A beautiful event detail page with premium HIVE-branded design
class EventDetailPage extends ConsumerStatefulWidget {
  final Event event;
  final String heroTag;

  const EventDetailPage({
    Key? key,
    required this.event,
    required this.heroTag,
  }) : super(key: key);

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late bool _isRsvped;
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _blurAnimation;
  late Future<List<Event>> _relatedEventsFuture;

  @override
  void initState() {
    super.initState();
    _isRsvped =
        ref.read(profileProvider.notifier).isEventSaved(widget.event.id);

    // Set up confetti for RSVP celebrations
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Set up animation for the blur effect on scroll
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _blurAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Initialize related events future
    if (widget.event.spaceId != null) {
      _relatedEventsFuture = ref.read(spaceRepositoryProvider).getSpaceEvents(widget.event.spaceId!);
    } else {
      _relatedEventsFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar with hero image
              _buildHeroHeader(),

              // Event details
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event title and organizer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Material(
                        color: Colors.transparent,
                        child: Hero(
                          tag: 'event_detail_title_${widget.heroTag}',
                          flightShuttleBuilder:
                              (_, Animation<double> animation, __, ___, ____) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (BuildContext context, Widget? child) {
                                return Opacity(
                                  opacity: animation.value,
                                  child: Text(
                                    widget.event.title,
                                    style: FeedTheme.titleLarge.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Text(
                            widget.event.title,
                            style: FeedTheme.titleLarge.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'By ${widget.event.organizerName}',
                        style: FeedTheme.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Key details section with improved glassmorphism
                    _buildKeyDetailsSection(),

                    // Description
                    _buildSection(
                      title: 'About this event',
                      content: widget.event.description,
                    ),

                    // Location
                    if (widget.event.location.isNotEmpty)
                      _buildLocationSection(),

                    // External link if available
                    if (widget.event.link.isNotEmpty)
                      _buildLinkSection(),

                    // Add related events section before the bottom spacing
                    if (widget.event.spaceId != null) _buildRelatedEventsSection(),

                    // Space at the bottom for the action bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Confetti overlay for RSVP celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                AppColors.yellow,
                Colors.white,
                Colors.amber,
                Colors.orangeAccent,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AnimatedBuilder(
          animation: _blurAnimation,
          builder: (context, child) {
            return ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: AppBar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    iconSize: 22,
                  ),
                  actions: [
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.share,
                        size: 22,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        FeedTheme.lightHaptic();
                        // Share event
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildHeroHeader() {
    return SliverAppBar(
      expandedHeight: 240.0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'event_detail_image_${widget.heroTag}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with gradient overlay
              ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.event.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Bottom gradient for text legibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.yellow.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Date and time
              _buildKeyDetailRow(
                iconData: HugeIcons.calendar,
                title: _formatDateRange(
                    widget.event.startDate, widget.event.endDate),
                subtitle: _formatTimeRange(
                    widget.event.startDate, widget.event.endDate),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  color: Colors.white10,
                  height: 32,
                ),
              ),

              // Location preview
              _buildKeyDetailRow(
                iconData: HugeIcons.spaces,
                title: widget.event.location.isEmpty ? 'Online Event' : widget.event.location,
                subtitle: 'Tap for directions',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyDetailRow({
    required IconData iconData,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: iconData,
              size: 24,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FeedTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: FeedTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FeedTheme.titleMedium.copyWith(
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: FeedTheme.bodyMedium.copyWith(
              height: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: FeedTheme.titleMedium.copyWith(
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                FeedTheme.lightHaptic();
                // Open maps
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white10,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.spaces,
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event.location,
                      style: FeedTheme.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open in Maps',
                      style: FeedTheme.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Link',
            style: FeedTheme.titleMedium.copyWith(
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                FeedTheme.lightHaptic();
                // Open link
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.share,
                        size: 20,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Event Website',
                            style: FeedTheme.titleMedium.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.event.link,
                            style: FeedTheme.bodyMedium.copyWith(
                              color: AppColors.yellow,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: AppColors.yellow,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedEventsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other Events in this Space',
            style: FeedTheme.titleMedium.copyWith(
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Event>>(
            future: _relatedEventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading events',
                    style: FeedTheme.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final events = snapshot.data ?? [];
              // Filter out current event and past events
              final otherEvents = events
                  .where((e) => e.id != widget.event.id && e.endDate.isAfter(DateTime.now()))
                  .toList();

              if (otherEvents.isEmpty) {
                return Center(
                  child: Text(
                    'No other upcoming events',
                    style: FeedTheme.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: otherEvents.length,
                itemBuilder: (context, index) {
                  final event = otherEvents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HiveEventCard(
                      key: ValueKey('related_event_${event.id}'),
                      event: event,
                      isRepost: false,
                      followsClub: false,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      height: 80,
      color: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // RSVP button
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _toggleRsvp,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isRsvped
                            ? Colors.white.withOpacity(0.1)
                            : AppColors.yellow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isRsvped
                              ? Colors.white.withOpacity(0.2)
                              : AppColors.yellow,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isRsvped ? 'Confirmed' : 'RSVP',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Share button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      FeedTheme.lightHaptic();
                      // Show repost dialog
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.share,
                      size: 22,
                      color: Colors.white,
                    ),
                    iconSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleRsvp() async {
    FeedTheme.mediumHaptic();

    setState(() {
      _isRsvped = !_isRsvped;
    });

    if (_isRsvped) {
      _confettiController.play();
    }

    // Update RSVP in the feed provider
    ref
        .read(feedStateProvider.notifier)
        .rsvpToEvent(widget.event.id, _isRsvped);

    // Save/remove event from profile
    if (_isRsvped) {
      await ref.read(profileProvider.notifier).saveEvent(widget.event);
    } else {
      await ref.read(profileProvider.notifier).removeEvent(widget.event.id);
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final DateFormat formatter = DateFormat('EEE, MMM d');
    final String startStr = formatter.format(start);

    // Check if same day event
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startStr;
    }

    final String endStr = formatter.format(end);
    return '$startStr - $endStr';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final DateFormat timeFormatter = DateFormat('h:mm a');
    return '${timeFormatter.format(start)} - ${timeFormatter.format(end)}';
  }
}
