import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/domain/repositories/signal_repository.dart';

/// Implementation of the Signal repository with mock data
class SignalRepositoryImpl implements SignalRepository {
  // Mock data for signal content
  final List<SignalContent> _mockSignalContent = [
    SignalContent(
      id: 'last_night_1',
      title: 'Last Night on Campus',
      description: 'Over 500 students attended the Engineering Showcase last night, with 22 projects receiving funding interest.',
      type: SignalType.lastNight,
      priority: 5,
      data: const {'eventId': 'eng_showcase_2023'},
    ),
    SignalContent(
      id: 'top_event_1',
      title: 'Top Event Today',
      description: '250+ students are headed to the Research Symposium starting at 2PM in the Main Hall.',
      type: SignalType.topEvent,
      priority: 4,
      data: const {'eventId': 'research_symposium_2023'},
    ),
    SignalContent(
      id: 'try_space_1',
      title: 'Try One Space',
      description: 'Robotics Club is gaining momentum with 38 new members this week. Check them out!',
      type: SignalType.trySpace,
      priority: 3,
      data: const {'spaceId': 'robotics_club'},
    ),
    SignalContent(
      id: 'hive_lab_1',
      title: 'Chaos Pulse',
      description: 'The HiveLab is collecting feedback on our new Signal Strip feature. Tap to share your thoughts!',
      type: SignalType.hiveLab,
      priority: 4,
      data: const {'labActionId': 'signal_strip_survey'},
    ),
    SignalContent(
      id: 'underrated_1',
      title: 'Underrated Gem',
      description: 'This small poetry reading unexpectedly attracted 85 students yesterday. Next session is Friday!',
      type: SignalType.underratedGem,
      priority: 2,
      data: const {'eventId': 'poetry_reading_series'},
    ),
    SignalContent(
      id: 'news_1',
      title: 'Campus Update',
      description: 'Library hours have been extended to 2AM on weekdays for the remainder of the semester.',
      type: SignalType.universityNews,
      priority: 3,
      data: const {'newsId': 'library_hours_extended'},
    ),
    SignalContent(
      id: 'community_1',
      title: 'Community Milestone',
      description: 'HIVE users have created 100+ student-led events this month, a new record!',
      type: SignalType.communityUpdate,
      priority: 1,
      data: const {'statType': 'student_events'},
    ),
    // Space Heat card
    SignalContent(
      id: 'space_heat_1',
      title: 'CS Club is on fire 🔥',
      description: '14 new members in the past hour. Activity is trending upward rapidly.',
      type: SignalType.spaceHeat,
      priority: 5,
      data: const {'spaceId': 'cs_club', 'memberDelta': 14, 'timePeriod': 'hour'},
    ),
    // Space Heat card 2
    SignalContent(
      id: 'space_heat_2',
      title: 'Design Union is heating up',
      description: '8 new posts in the last 3 hours with high engagement.',
      type: SignalType.spaceHeat,
      priority: 4,
      data: const {'spaceId': 'design_union', 'postDelta': 8, 'timePeriod': '3 hours'},
    ),
    // Ritual Launch card
    SignalContent(
      id: 'ritual_launch_1',
      title: 'Weekly Photo Challenge',
      description: 'Post your best campus shot. Most reactions wins a feature spot.',
      type: SignalType.ritualLaunch,
      priority: 5,
      data: const {
        'ritualId': 'photo_challenge_week_42',
        'ritualType': 'challenge',
        'expiresInHours': 48,
      },
    ),
    // Ritual Launch card 2
    SignalContent(
      id: 'ritual_launch_2',
      title: 'Campus Confession Booth',
      description: 'Share your anonymous campus confession. Most reactions get promoted.',
      type: SignalType.ritualLaunch,
      priority: 4,
      data: const {
        'ritualId': 'confession_booth_oct',
        'ritualType': 'anonymous',
        'expiresInHours': 24,
      },
    ),
    // Friend Motion card 
    SignalContent(
      id: 'friend_motion_1',
      title: 'Your Friends Are Moving',
      description: '5 people you know are headed to Jazz Club meetup tonight.',
      type: SignalType.friendMotion,
      priority: 3,
      data: const {
        'eventId': 'jazz_club_meetup',
        'friendCount': 5,
        'friendIds': ['user1', 'user2', 'user3', 'user4', 'user5'],
      },
    ),
    // Friend Motion card 2
    SignalContent(
      id: 'friend_motion_2',
      title: 'Friend Activity Spike',
      description: '3 connections just joined Blockchain Society in the last day.',
      type: SignalType.friendMotion,
      priority: 4,
      data: const {
        'spaceId': 'blockchain_society',
        'friendCount': 3,
        'friendIds': ['user7', 'user8', 'user9'],
        'timePeriod': 'day',
      },
    ),
  ];
  
  @override
  Future<List<SignalContent>> getSignalContent({
    int maxItems = 5,
    List<SignalType>? types,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Filter by types if provided
    final filteredContent = types != null
        ? _mockSignalContent.where((content) => types.contains(content.type)).toList()
        : List<SignalContent>.from(_mockSignalContent);
    
    // Filter out expired content
    final activeContent = filteredContent
        .where((content) => !content.isExpired())
        .toList();
    
    // Sort by priority (highest first)
    activeContent.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Return the requested number of items
    return activeContent.take(maxItems).toList();
  }

  @override
  Future<SignalContent?> getSignalContentById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      return _mockSignalContent.firstWhere((content) => content.id == id);
    } catch (e) {
      debugPrint('Signal content not found: $id');
      return null;
    }
  }

  @override
  Future<bool> logSignalContentView(String contentId) async {
    // In a real implementation, this would log to analytics or backend
    debugPrint('Signal content viewed: $contentId');
    return true;
  }

  @override
  Future<bool> logSignalContentTap(String contentId) async {
    // In a real implementation, this would log to analytics or backend
    debugPrint('Signal content tapped: $contentId');
    return true;
  }
} 