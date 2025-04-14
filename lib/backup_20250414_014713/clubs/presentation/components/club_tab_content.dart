import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Tab types for the club space
enum ClubTabType {
  about,
  events,
  members,
  gallery,
}

/// Provider for club events
final clubEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, clubId) async {
  // In a real app, this would fetch events from a service or another provider
  // For now, we'll create a dummy event for demonstration
  final now = DateTime.now();
  return [
    Event(
      id: 'demo_event_$clubId',
      title: 'Club Meeting',
      description: 'Regular club meeting for members',
      location: 'Student Union Building, Room 201',
      startDate: now.add(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 2, hours: 2)),
      organizerEmail: 'club@example.com',
      organizerName: 'Club Admin',
      category: 'Meeting',
      status: 'confirmed',
      link: '',
      tags: const ['meeting', 'club'],
      imageUrl: 'assets/images/events/club_meeting.jpg',
      source: EventSource.club,
    )
  ];
});

/// Component for the different club tab contents
class ClubTabContent extends ConsumerWidget {
  final ClubTabType tabType;
  final Club club;
  final bool isUserManager;
  final VoidCallback? onActionPressed;

  const ClubTabContent({
    super.key,
    required this.tabType,
    required this.club,
    this.isUserManager = false,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scaffold will help provide Material widgets context to child components
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildActionButton(),
      body: _buildTabContent(context, ref),
    );
  }

  Widget? _buildActionButton() {
    // Only show action button for managers and certain tabs
    if (!isUserManager || onActionPressed == null) {
      return null;
    }

    IconData icon;
    String tooltip;

    switch (tabType) {
      case ClubTabType.events:
        icon = Icons.add_circle_outline;
        tooltip = 'Create Event';
        break;
      case ClubTabType.members:
        icon = Icons.person_add_alt_1;
        tooltip = 'Manage Members';
        break;
      case ClubTabType.gallery:
        icon = Icons.add_photo_alternate_outlined;
        tooltip = 'Add Photos';
        break;
      default:
        return null;
    }

    return FloatingActionButton(
      heroTag: 'club_${club.id}_${tabType.toString()}_fab',
      onPressed: onActionPressed,
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref) {
    // Return the appropriate tab content based on tab type
    switch (tabType) {
      case ClubTabType.about:
        return _buildAboutTab(context);
      case ClubTabType.events:
        return _buildEventsTab(context, ref);
      case ClubTabType.members:
        return _buildMembersTab(context, ref);
      case ClubTabType.gallery:
        return _buildGalleryTab(context);
    }
  }

  /// Builds the About tab content
  Widget _buildAboutTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (club.mission != null && club.mission!.isNotEmpty) ...[
            _buildSectionTitle('Mission'),
            _buildSectionText(club.mission!),
            const SizedBox(height: 24),
          ],

          if (club.vision != null && club.vision!.isNotEmpty) ...[
            _buildSectionTitle('Vision'),
            _buildSectionText(club.vision!),
            const SizedBox(height: 24),
          ],

          if (club.foundedYear != null) ...[
            _buildSectionTitle('Founded'),
            _buildSectionText('${club.foundedYear}'),
            const SizedBox(height: 24),
          ],

          if (club.contactInfo.isNotEmpty) ...[
            _buildSectionTitle('Contact Information'),
            ...club.contactInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildContactItem(entry.key, entry.value),
              );
            }),
            const SizedBox(height: 16),
          ],

          if (club.location != null && club.location!.isNotEmpty) ...[
            _buildSectionTitle('Location'),
            _buildContactItem('Address', club.location!),
            const SizedBox(height: 24),
          ],

          if (club.meetingTimes.isNotEmpty) ...[
            _buildSectionTitle('Meeting Times'),
            ...club.meetingTimes.map((time) => _buildSectionText('• $time')),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 80), // Extra space for floating button
        ],
      ),
    );
  }

  /// Builds the Events tab content
  Widget _buildEventsTab(BuildContext context, WidgetRef ref) {
    final clubEvents = ref.watch(clubEventsProvider(club.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Events',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (isUserManager && onActionPressed != null)
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onActionPressed!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Events list
          Expanded(
            child: clubEvents.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Error loading events',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return _buildNoEventsMessage();
                }
                return _buildEventsList(events);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Members tab content
  Widget _buildMembersTab(BuildContext context, WidgetRef ref) {
    // TODO: Implement members provider and display
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (isUserManager && onActionPressed != null)
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onActionPressed!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Invite'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Placeholder for members list
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Member list coming soon',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This club has ${club.memberCount} members',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Gallery tab content
  Widget _buildGalleryTab(BuildContext context) {
    // TODO: Implement gallery
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photo Gallery',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (isUserManager && onActionPressed != null)
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onActionPressed!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.add_photo_alternate, size: 16),
                  label: const Text('Add'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Placeholder for gallery
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Photo gallery coming soon',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photos to showcase your club',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets for the tab contents
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          height: 1.4,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildContactItem(String type, String value) {
    IconData icon;

    switch (type.toLowerCase()) {
      case 'email':
        icon = Icons.email_outlined;
        break;
      case 'phone':
        icon = Icons.phone_outlined;
        break;
      case 'website':
        icon = Icons.language_outlined;
        break;
      case 'address':
        icon = Icons.location_on_outlined;
        break;
      default:
        icon = Icons.info_outline;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.4,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoEventsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUserManager
                ? 'Create an event to get started'
                : 'Check back later for updates',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    // Sort events by date (newest first)
    events.sort((a, b) => a.startDate.compareTo(b.startDate));

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to event details
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(
                  event.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Event date and time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(event.startDate),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Event location
                if (event.location.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.location,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
