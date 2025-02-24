import 'package:flutter/material.dart';
import 'package:hive_ui/components/event_card.dart';
import 'package:hive_ui/components/repost_dialog.dart';

class MainFeedPage extends StatefulWidget {
  const MainFeedPage({super.key});

  @override
  State<MainFeedPage> createState() => _MainFeedPageState();
}

class _MainFeedPageState extends State<MainFeedPage> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'Tech Talk: Future of AI',
      'description': 'Join us for an insightful discussion about the future of AI and its impact on society.',
      'clubName': 'Tech Club',
      'clubLogo': 'https://example.com/tech_club_logo.png',
      'eventImage': 'https://example.com/tech_talk_image.jpg',
      'dateTime': DateTime.now().add(const Duration(days: 2)),
      'location': 'Student Union Room 145',
      'friendsAttending': [
        'https://example.com/friend1.jpg',
        'https://example.com/friend2.jpg',
        'https://example.com/friend3.jpg',
      ],
      'isRsvped': false,
    },
    {
      'title': 'Cultural Night',
      'description': 'Experience diverse cultures through food, music, and performances.',
      'clubName': 'International Student Association',
      'clubLogo': 'https://example.com/isa_logo.png',
      'eventImage': 'https://example.com/cultural_night.jpg',
      'dateTime': DateTime.now().add(const Duration(days: 5)),
      'location': 'Campus Center Ballroom',
      'friendsAttending': [
        'https://example.com/friend4.jpg',
        'https://example.com/friend5.jpg',
      ],
      'isRsvped': false,
    },
    {
      'title': 'Hackathon 2024',
      'description': 'Join us for a 24-hour coding challenge and build something amazing!',
      'clubName': 'Computer Science Club',
      'clubLogo': 'https://example.com/cs_club_logo.png',
      'eventImage': 'https://example.com/hackathon_image.jpg',
      'dateTime': DateTime.now().add(const Duration(days: 7)),
      'location': 'Engineering Building',
      'friendsAttending': [
        'https://example.com/friend1.jpg',
        'https://example.com/friend3.jpg',
        'https://example.com/friend5.jpg',
        'https://example.com/friend6.jpg',
      ],
      'isRsvped': false,
    },
  ];

  Future<void> _refreshEvents() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implement RSS feed fetching
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRsvp(int index) {
    setState(() {
      _events[index]['isRsvped'] = !_events[index]['isRsvped'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _events[index]['isRsvped'] ? 'RSVP Confirmed!' : 'RSVP Cancelled',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFEEBA2A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRepost(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepostDialog(
        eventTitle: _events[index]['title'],
        clubName: _events[index]['clubName'],
      ),
    ).then((comment) {
      if (comment != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event reposted!'),
            backgroundColor: Color(0xFFEEBA2A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showEventDetails(int index) {
    // TODO: Implement event details view
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'HIVE',
          style: TextStyle(
            color: Color(0xFFEEBA2A),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        color: const Color(0xFFEEBA2A),
        backgroundColor: const Color(0xFF1E1E1E),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEEBA2A)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return EventCard(
                    title: event['title'],
                    description: event['description'],
                    clubName: event['clubName'],
                    clubLogo: event['clubLogo'],
                    eventImage: event['eventImage'],
                    dateTime: event['dateTime'],
                    location: event['location'],
                    friendsAttending: List<String>.from(event['friendsAttending']),
                    isRsvped: event['isRsvped'],
                    onRsvp: () => _handleRsvp(index),
                    onRepost: () => _handleRepost(index),
                    onTap: () => _showEventDetails(index),
                  );
                },
              ),
      ),
    );
  }
} 