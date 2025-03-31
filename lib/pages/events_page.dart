import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event.dart';
import '../components/event_card/event_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/event_providers.dart';
import '../pages/event_details_page.dart';
import '../providers/profile_provider.dart';
import '../components/event_card/hive_event_card.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage>
    with AutomaticKeepAliveClientMixin {
  String _sortOption = 'Date'; // Default sort option
  static const List<String> _sortOptions = ['Date', 'Category', 'Location'];

  @override
  void initState() {
    super.initState();
    // Trigger events loading
    Future.microtask(() {
      ref.read(eventsProvider);
    });
  }

  // Helper to sort events based on the selected option
  List<Event> _getSortedEvents(List<Event> events) {
    switch (_sortOption) {
      case 'Category':
        return List.from(events)
          ..sort((a, b) => a.category.compareTo(b.category));
      case 'Location':
        return List.from(events)
          ..sort((a, b) => a.location.compareTo(b.location));
      case 'Date':
      default:
        // Sort by date (most imminent first, then by start time)
        final now = DateTime.now();
        return List.from(events)
          ..sort((a, b) {
            // Put events happening today at the top
            final aIsToday = a.startDate.day == now.day && a.startDate.month == now.month && a.startDate.year == now.year;
            final bIsToday = b.startDate.day == now.day && b.startDate.month == now.month && b.startDate.year == now.year;
            
            if (aIsToday && !bIsToday) return -1;
            if (!aIsToday && bIsToday) return 1;
            
            // For same-day events, sort by start time
            if (aIsToday && bIsToday) {
              return a.startDate.hour.compareTo(b.startDate.hour);
            }
            
            // For future events, compare by start date
            return a.startDate.compareTo(b.startDate);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch the events data
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: Text(
          'Events',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort events',
            onSelected: (String value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _sortOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _sortOption == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _sortOption == option ? AppColors.gold : null,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(option),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Show feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing events...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Invalidate providers to force refresh
              ref.invalidate(eventsProvider);
              ref.read(refreshEventsProvider);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Text(
                  'All Events',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Show current sort option
                Row(
                  children: [
                    Text(
                      'Sorted by: ',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _sortOption,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Event list
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildEventsList(_getSortedEvents(events));
              },
              loading: () => _buildLoadingState(),
              error: (error, stackTrace) {
                debugPrint('Error loading events: $error\n$stackTrace');
                return _buildErrorState(
                    'Failed to load events. Please try again later.');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading events...',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Events Found',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no upcoming events\nfrom the UB events feed',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(eventsProvider);
              ref.read(refreshEventsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(eventsProvider);
              ref.read(refreshEventsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildEventCard(event),
        );
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return HiveEventCard(
      event: event,
      onTap: (event) => _navigateToEventDetail(event),
      onRsvp: (event) {
        HapticFeedback.mediumImpact();
        ref.read(profileProvider.notifier).saveEvent(event);
      },
    );
  }

  void _navigateToEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          event: event,
          heroTag: 'event_${event.id}',
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
