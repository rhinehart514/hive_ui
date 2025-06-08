import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';
import 'event_card.dart';

/// Example page demonstrating the HiveEventCard in different modes
class EventCardExamplePage extends ConsumerWidget {
  const EventCardExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Event Card Examples'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Regular Event Card',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Regular Event Card
          HiveEventCard(
            event: _getSampleEvent(),
            onTap: (event) => _showSnackBar(context, 'Tapped ${event.title}'),
            onRsvp: (event) => _showSnackBar(context, 'RSVP to ${event.title}'),
            onRepost: (event, comment, type) => _showSnackBar(context, 'Reposted ${event.title}'),
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Reposted Event Card',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Reposted Event Card
          HiveEventCard(
            event: _getSampleEvent(),
            isRepost: true,
            repostedBy: _getSampleUser(),
            repostTimestamp: DateTime.now().subtract(const Duration(hours: 3)),
            onTap: (event) => _showSnackBar(context, 'Tapped ${event.title}'),
            onRsvp: (event) => _showSnackBar(context, 'RSVP to ${event.title}'),
            onRepost: (event, comment, type) => _showSnackBar(context, 'Reposted ${event.title}'),
          ),
        ],
      ),
    );
  }
  
  // Show a snackbar for demo actions
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // Create a sample event for demonstration
  Event _getSampleEvent() {
    return Event(
      id: 'sample_event_1',
      title: 'HIVE Premium Event: Building the future of campus networking',
      description: 'Join us for an exclusive event where we discuss the future of campus social networking and community building.',
      location: 'Student Union, Room 401',
      startDate: DateTime.now().add(const Duration(days: 3, hours: 5)),
      endDate: DateTime.now().add(const Duration(days: 3, hours: 8)),
      organizerEmail: 'organizer@hive.io',
      organizerName: 'HIVE Campus Team',
      category: 'Technology',
      status: 'confirmed',
      link: 'https://hive.io/events/sample-event',
      imageUrl: 'https://picsum.photos/seed/hive-event/800/600',
      tags: const ['Technology', 'Networking', 'Social'],
      source: EventSource.club,
      visibility: 'public',
      attendees: const ['user1', 'user2', 'user3', 'user4'],
    );
  }
  
  // Create a sample user for demonstration
  UserProfile _getSampleUser() {
    return UserProfile(
      id: 'user1',
      username: 'hiveuser',
      displayName: 'Alex Johnson',
      year: 'Junior',
      major: 'Computer Science',
      residence: 'North Campus',
      eventCount: 15,
      spaceCount: 3,
      friendCount: 148,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
      profileImageUrl: 'https://i.pravatar.cc/150?img=12',
      bio: 'Building the future of campus social networking',
      isVerified: true,
      interests: const ['Technology', 'Programming', 'Design'],
    );
  }
} 