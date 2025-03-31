import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/components/recommended_space_card.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A demo component to showcase the RecommendedSpaceCard in both layouts
class RecommendedSpaceCardDemo extends ConsumerWidget {
  const RecommendedSpaceCardDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Recommended Spaces'),
        backgroundColor: AppColors.cardBackground,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading for horizontal layout
              Text(
                'Horizontal Layout (Feed)',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Horizontal scroll of cards
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _getSampleSpaces().map((space) {
                    return RecommendedSpaceCard(
                      space: space.space,
                      pitch: space.displayPitch,
                      isHorizontal: true,
                      onJoin: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Joined ${space.space.name}!'),
                            backgroundColor: AppColors.cardBackground,
                          ),
                        );
                      },
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tapped ${space.space.name}'),
                            backgroundColor: AppColors.cardBackground,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Heading for vertical layout
              Text(
                'Vertical Layout (Spaces Tab)',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Vertical list of cards
              ...(_getSampleSpaces().map((space) {
                return RecommendedSpaceCard(
                  space: space.space,
                  pitch: space.displayPitch,
                  isHorizontal: false,
                  onJoin: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joined ${space.space.name}!'),
                        backgroundColor: AppColors.cardBackground,
                      ),
                    );
                  },
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped ${space.space.name}'),
                        backgroundColor: AppColors.cardBackground,
                      ),
                    );
                  },
                );
              }).toList()),
            ],
          ),
        ),
      ),
    );
  }

  /// Generate sample spaces for demo purposes
  List<RecommendedSpace> _getSampleSpaces() {
    return [
      RecommendedSpace(
        space: Space(
          id: '1',
          name: 'Photography Club',
          description:
              'Share your passion for photography with like-minded students',
          icon: Icons.camera_alt,
          imageUrl: 'https://source.unsplash.com/random/400x400/?photography',
          metrics: SpaceMetrics(
            spaceId: '1',
            memberCount: 128,
            activeMembers: 45,
            weeklyEvents: 2,
            monthlyEngagements: 320,
            lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
            hasNewContent: true,
            isTrending: true,
            activeMembers24h: const ['user1', 'user2', 'user3'],
            activityScores: const {'posts': 120, 'comments': 245},
            category: SpaceCategory.active,
            size: SpaceSize.medium,
            engagementScore: 0.8,
            connectedFriends: const ['friend1', 'friend2'],
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          spaceType: SpaceType.studentOrg,
        ),
        customPitch: 'Weekly photo walks, workshops, and competitions',
        recommendationReason: '2 of your friends are active members',
      ),
      RecommendedSpace(
        space: Space(
          id: '2',
          name: 'Coding Club',
          description: 'Learn programming and build projects together',
          icon: Icons.code,
          imageUrl: 'https://source.unsplash.com/random/400x400/?coding',
          metrics: SpaceMetrics(
            spaceId: '2',
            memberCount: 95,
            activeMembers: 32,
            weeklyEvents: 1,
            monthlyEngagements: 210,
            lastActivity: DateTime.now().subtract(const Duration(hours: 6)),
            hasNewContent: false,
            isTrending: false,
            activeMembers24h: const ['user4', 'user5'],
            activityScores: const {'posts': 75, 'comments': 180},
            category: SpaceCategory.expanding,
            size: SpaceSize.small,
            engagementScore: 0.6,
            connectedFriends: const [],
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          spaceType: SpaceType.studentOrg,
        ),
        customPitch: 'Upcoming hackathon and weekly coding challenges',
        recommendationReason: 'Based on your interest in technology',
      ),
      RecommendedSpace(
        space: Space(
          id: '3',
          name: 'Basketball Team',
          description:
              'Join our intramural basketball team for games and practices',
          icon: Icons.sports_basketball,
          imageUrl: 'https://source.unsplash.com/random/400x400/?basketball',
          metrics: SpaceMetrics(
            spaceId: '3',
            memberCount: 22,
            activeMembers: 18,
            weeklyEvents: 3,
            monthlyEngagements: 156,
            lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
            hasNewContent: true,
            isTrending: true,
            activeMembers24h: const ['user7', 'user8', 'user9'],
            activityScores: const {'posts': 48, 'comments': 134},
            category: SpaceCategory.active,
            size: SpaceSize.medium,
            engagementScore: 0.9,
            connectedFriends: const ['friend3'],
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
          spaceType: SpaceType.studentOrg,
        ),
        customPitch: 'Practice on Tuesdays and games on Fridays',
        recommendationReason: 'Rapidly growing community on campus',
      ),
      RecommendedSpace(
        space: Space(
          id: '4',
          name: 'Debate Society',
          description:
              'Strengthen your public speaking and critical thinking skills',
          icon: Icons.record_voice_over,
          imageUrl: 'https://source.unsplash.com/random/400x400/?debate',
          metrics: SpaceMetrics(
            spaceId: '4',
            memberCount: 42,
            activeMembers: 28,
            weeklyEvents: 1,
            monthlyEngagements: 185,
            lastActivity: DateTime.now().subtract(const Duration(hours: 8)),
            hasNewContent: false,
            isTrending: false,
            activeMembers24h: const ['user10', 'user11'],
            activityScores: const {'posts': 65, 'comments': 120},
            category: SpaceCategory.expanding,
            size: SpaceSize.small,
            engagementScore: 0.7,
            connectedFriends: const [],
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 150)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          spaceType: SpaceType.studentOrg,
        ),
        customPitch: 'Upcoming tournament with 5 other universities',
        recommendationReason: 'Based on your classes in political science',
      ),
    ];
  }
}
