import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/features/friends/presentation/providers/suggested_friends_provider.dart' as friends_providers;

/// Provider for getting suggested friends specifically for the feed
final feedSuggestedFriendsProvider = FutureProvider.autoDispose<List<SuggestedFriend>>((ref) async {
  try {
    // Get all suggested friends
    final allSuggestions = await ref.watch(friends_providers.suggestedFriendsProvider.future);
    
    // If there are no suggestions, return mock data
    if (allSuggestions.isEmpty) {
      return _getMockSuggestions();
    }
    
    // Limit to 5 suggestions
    final maxSuggestions = min(5, allSuggestions.length);
    
    // Get a random subset of suggestions
    final random = Random();
    final List<SuggestedFriend> feedSuggestions = [];
    
    // Create a copy of the list to prevent modifying the original
    final availableSuggestions = List<SuggestedFriend>.from(allSuggestions);
    
    // Select random suggestions
    for (int i = 0; i < maxSuggestions; i++) {
      if (availableSuggestions.isEmpty) break;
      final randomIndex = random.nextInt(availableSuggestions.length);
      feedSuggestions.add(availableSuggestions[randomIndex]);
      availableSuggestions.removeAt(randomIndex);
    }
    
    return feedSuggestions;
  } catch (e) {
    // If any error occurs, return mock data
    if (kDebugMode) {
      debugPrint('Error fetching suggested friends: $e');
    }
    return _getMockSuggestions();
  }
});

/// Create detailed mock suggestions for testing purposes
List<SuggestedFriend> _getMockSuggestions() {
  // Profile images from diverse sources
  final profileImages = [
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80',
  ];
  
  // Use Firebase Authentication UID format for mock user IDs
  // These IDs match the format expected by ProfilePage
  final mockUserIds = [
    'mz9JUBBh8TQB5TSqGYUukL1PVmr1',
    'CrwYdwfLPuVUkgUHoXlIBPXx7Os1',
    '5LKGjm9Zt0WgfFIZMlpRzSWO2362',
    'bTp0tBLTnXcHJYSXCYiYHQqMAyH3',
    'l7oRGYSH5mTtpCzwqkB0RQrpLwl1',
  ];
  
  // Sample detailed majors for academic matching
  final majors = ['Computer Science', 'Psychology', 'Business Administration', 'Mechanical Engineering', 'Graphic Design'];
  
  // Sample years for better context
  final years = ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate'];
  
  // Sample detailed residences for location matching
  final residences = ['North Campus Housing', 'South Quad', 'Downtown Apartments', 'College Town Suites', 'East Village Dorms'];
  
  // Sample interests for interest matching
  final interests = [
    ['Hackathons', 'Programming', 'Machine Learning', 'Game Development'],
    ['Music Production', 'Classical Piano', 'Concert Photography', 'Vinyl Collection'],
    ['Film Studies', 'Screenwriting', 'Photography', 'Visual Arts'],
    ['Basketball', 'Tennis', 'Hiking', 'Rock Climbing'],
    ['Book Club', 'Poetry Writing', 'Literary Criticism', 'Creative Writing']
  ];
  
  // Create mock friends with richer data
  return [
    SuggestedFriend(
      id: mockUserIds[0],
      name: 'Alex Rivera',
      profileImage: profileImages[0],
      status: '${majors[0]} • ${years[2]}',
      matchCriteria: MatchCriteria.major,
      matchValue: majors[0],
      isRequestSent: false,
    ),
    SuggestedFriend(
      id: mockUserIds[1],
      name: 'Jordan Chen',
      profileImage: profileImages[1],
      status: '${majors[1]} • ${years[1]}',
      matchCriteria: MatchCriteria.interest,
      matchValue: interests[1][0],
      isRequestSent: false,
    ),
    SuggestedFriend(
      id: mockUserIds[2],
      name: 'Taylor Kim',
      profileImage: profileImages[2],
      status: '${majors[2]} • ${years[3]}',
      matchCriteria: MatchCriteria.residence,
      matchValue: residences[0],
      isRequestSent: false,
    ),
    SuggestedFriend(
      id: mockUserIds[3],
      name: 'Morgan Singh',
      profileImage: profileImages[3],
      status: '${majors[3]} • ${years[0]}',
      matchCriteria: MatchCriteria.interest,
      matchValue: interests[3][2],
      isRequestSent: false,
    ),
    SuggestedFriend(
      id: mockUserIds[4],
      name: 'Casey Patel',
      profileImage: profileImages[4],
      status: '${majors[4]} • ${years[4]}', 
      matchCriteria: MatchCriteria.residence,
      matchValue: residences[2],
      isRequestSent: false,
    ),
  ];
}

/// Provider for getting a single suggested friend for the feed
final feedSingleSuggestedFriendProvider = FutureProvider.autoDispose<SuggestedFriend?>((ref) async {
  final suggestions = await ref.watch(feedSuggestedFriendsProvider.future);
  
  if (suggestions.isEmpty) {
    return null;
  }
  
  // Always return the first mock user for consistency in the feed display
  return suggestions.first;
}); 