import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import 'event_card.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';

/// A test page to demonstrate the HiveEventCard improvements with different organizer name lengths
class EventCardTestPage extends ConsumerWidget {
  const EventCardTestPage({Key? key}) : super(key: key);

  static void navigateToTestPage(BuildContext context) {
    context.go(AppRoutes.eventCardTest);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Event Card Profile Improvements'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Short Organizer Name',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          
          HiveEventCard(
            event: _createSampleEvent(
              organizerName: 'Short Name',
              description: 'This event has a very short organizer name that should fit easily.',
            ),
            onTap: (_) {},
          ),
          
          const SizedBox(height: 24),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Medium Organizer Name',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          
          HiveEventCard(
            event: _createSampleEvent(
              organizerName: 'Medium Length Organizer Name',
              description: 'This event has a medium length organizer name that should fit on a single line on most devices.',
            ),
            onTap: (_) {},
          ),
          
          const SizedBox(height: 24),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Long Organizer Name',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          
          HiveEventCard(
            event: _createSampleEvent(
              organizerName: 'Very Long Organizer Name That Should Wrap to Two Lines',
              description: 'This event has a very long organizer name that should wrap to two lines with the new layout improvements.',
            ),
            onTap: (_) {},
          ),
          
          const SizedBox(height: 24),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Long Organizer Name With Verification',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          
          HiveEventCard(
            event: _createSampleEvent(
              organizerName: 'Very Long Verified Organizer Name That Wraps With Badge',
              description: 'This event has a very long organizer name that should wrap properly with the verification badge showing.',
              source: EventSource.club,
            ),
            onTap: (_) {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.home),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.home),
      ),
    );
  }
  
  Event _createSampleEvent({
    required String organizerName,
    required String description,
    EventSource source = EventSource.user,
  }) {
    return Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Event Card Profile Test',
      description: description,
      location: 'Buffalo, NY',
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 2, hours: 3)),
      organizerName: organizerName,
      organizerEmail: 'test@example.com',
      category: 'Test',
      status: 'confirmed',
      link: 'https://example.com',
      attendees: const ['user1', 'user2', 'user3'],
      imageUrl: 'https://example.com/image.jpg',
      source: source,
    );
  }
} 