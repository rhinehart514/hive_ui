import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/friend.dart';
import 'package:flutter/material.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return ProfileNotifier();
});

final userEventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<Event>>>((ref) {
  return EventsNotifier();
});

final userClubsProvider = StateNotifierProvider<ClubsNotifier, AsyncValue<List<Club>>>((ref) {
  return ClubsNotifier();
});

final userFriendsProvider = StateNotifierProvider<FriendsNotifier, AsyncValue<List<Friend>>>((ref) {
  return FriendsNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      final profile = UserProfile(
        id: '1',
        username: 'johndoe',
        profileImageUrl: 'assets/images/profile.png',
        year: 'Junior',
        major: 'Computer Science',
        residence: 'Greiner Hall',
        eventCount: 12,
        clubCount: 3,
        friendCount: 128,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  EventsNotifier() : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      final events = [
        Event(
          title: 'Hackathon 2024',
          description: 'Join us for a 24-hour coding challenge!',
          location: 'Davis Hall',
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 24)),
          organizerEmail: 'acm@buffalo.edu',
          organizerName: 'ACM Club',
          category: 'Technology',
          status: 'confirmed',
          link: 'https://ubhacking.com',
        ),
        Event(
          title: 'Career Fair',
          description: 'Meet top employers and find your next opportunity!',
          location: 'Student Union',
          startTime: DateTime.now().add(const Duration(days: 14)),
          endTime: DateTime.now().add(const Duration(days: 14, hours: 6)),
          organizerEmail: 'careers@buffalo.edu',
          organizerName: 'Career Services',
          category: 'Career',
          status: 'confirmed',
          link: 'https://buffalo.edu/careers',
        ),
      ];
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ClubsNotifier extends StateNotifier<AsyncValue<List<Club>>> {
  ClubsNotifier() : super(const AsyncValue.loading()) {
    loadClubs();
  }

  Future<void> loadClubs() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      final clubs = [
        Club(
          id: '1',
          name: 'ACM Club',
          description: 'Association for Computing Machinery UB Chapter',
          category: 'Technology',
          memberCount: 150,
          status: 'active',
          icon: Icons.computer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Club(
          id: '2',
          name: 'Entrepreneurship Society',
          description: 'Building the next generation of entrepreneurs',
          category: 'Business',
          memberCount: 80,
          status: 'active',
          icon: Icons.business,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      state = AsyncValue.data(clubs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class FriendsNotifier extends StateNotifier<AsyncValue<List<Friend>>> {
  FriendsNotifier() : super(const AsyncValue.loading()) {
    loadFriends();
  }

  Future<void> loadFriends() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      final friends = [
        Friend(
          id: '1',
          name: 'Alex Johnson',
          major: 'Computer Science',
          year: 'Junior',
          imageUrl: 'assets/images/friend1.png',
          isOnline: true,
          lastActive: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        Friend(
          id: '2',
          name: 'Sarah Williams',
          major: 'Engineering',
          year: 'Senior',
          imageUrl: 'assets/images/friend2.png',
          isOnline: false,
          lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        ),
      ];
      state = AsyncValue.data(friends);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 