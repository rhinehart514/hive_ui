import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final String clubName;
  final String clubLogo;
  final String eventImage;
  final DateTime dateTime;
  final String location;
  final List<String> friendsAttending;
  final bool isRsvped;
  final VoidCallback onRsvp;
  final VoidCallback onRepost;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.clubName,
    required this.clubLogo,
    required this.eventImage,
    required this.dateTime,
    required this.location,
    required this.friendsAttending,
    required this.isRsvped,
    required this.onRsvp,
    required this.onRepost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onRsvp(),
              backgroundColor: isRsvped ? Colors.grey : const Color(0xFFEEBA2A),
              foregroundColor: Colors.black,
              icon: Icons.event_available,
              label: isRsvped ? 'Cancel RSVP' : 'RSVP',
            ),
            SlidableAction(
              onPressed: (_) => onRepost(),
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              icon: Icons.share,
              label: 'Repost',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club Header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(clubLogo),
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        clubName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Event Image
                if (eventImage.isNotEmpty)
                  Image.network(
                    eventImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                // Event Details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFEEBA2A),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(dateTime),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFEEBA2A),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (friendsAttending.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              height: 32,
                              child: Stack(
                                children: [
                                  for (var i = 0; i < friendsAttending.length; i++)
                                    Positioned(
                                      left: i * 20.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF1E1E1E),
                                            width: 2,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            friendsAttending[i],
                                          ),
                                          radius: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${friendsAttending.length} friends attending',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 