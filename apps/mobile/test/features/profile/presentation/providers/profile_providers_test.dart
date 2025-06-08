import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/models/user_profile.dart' as model;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_providers_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late MockProfileRepository mockRepository;
  late ProviderContainer container;
  
  setUp(() {
    mockRepository = MockProfileRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    
    // Add a tearDown callback to dispose the container
    addTearDown(container.dispose);
  });
  
  group('ProfileNotifier Tests', () {
    const testUserId = 'test-user-123';
    
    const testDomainProfile = domain.UserProfile(
      id: testUserId,
      displayName: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      bio: 'This is a test bio',
      photoUrl: 'https://example.com/avatar.jpg',
      interests: ['Tech', 'Music'],
      major: 'Computer Science',
      residenceType: 'Campus Housing',
    );
    
    test('initial state should be loading: false and null profile', () {
      final profileNotifier = ProfileNotifier(mockRepository);
      
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, isNull);
      expect(profileNotifier.state.error, isNull);
      expect(profileNotifier.state.hasError, isFalse);
    });
    
    test('loadProfile should update state with profile when successful', () async {
      // Arrange
      when(mockRepository.getProfile(testUserId))
          .thenAnswer((_) async => testDomainProfile);
      
      final profileNotifier = ProfileNotifier(mockRepository);
      
      // Act
      await profileNotifier.loadProfile(testUserId);
      
      // Assert
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, isNotNull);
      expect(profileNotifier.state.profile!.id, equals(testUserId));
      expect(profileNotifier.state.profile!.displayName, equals('Test User'));
      expect(profileNotifier.state.error, isNull);
      
      verify(mockRepository.getProfile(testUserId)).called(1);
    });
    
    test('loadProfile should update state with error when profile not found', () async {
      // Arrange
      when(mockRepository.getProfile(testUserId))
          .thenAnswer((_) async => null);
      
      final profileNotifier = ProfileNotifier(mockRepository);
      
      // Act
      await profileNotifier.loadProfile(testUserId);
      
      // Assert
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, isNull);
      expect(profileNotifier.state.error, equals('Profile not found'));
      expect(profileNotifier.state.hasError, isTrue);
      
      verify(mockRepository.getProfile(testUserId)).called(1);
    });
    
    test('loadProfile should update state with error when exception is thrown', () async {
      // Arrange
      when(mockRepository.getProfile(testUserId))
          .thenThrow(Exception('Network error'));
      
      final profileNotifier = ProfileNotifier(mockRepository);
      
      // Act
      await profileNotifier.loadProfile(testUserId);
      
      // Assert
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, isNull);
      expect(profileNotifier.state.error, contains('Failed to load profile'));
      expect(profileNotifier.state.hasError, isTrue);
      
      verify(mockRepository.getProfile(testUserId)).called(1);
    });
    
    test('refreshProfile should load profile if current profile is null', () async {
      // Arrange
      when(mockRepository.getProfile(any))
          .thenAnswer((_) async => testDomainProfile);
      
      final profileNotifier = ProfileNotifier(mockRepository);
      
      // Act
      await profileNotifier.refreshProfile();
      
      // Assert
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, isNotNull);
      
      verify(mockRepository.getProfile(null)).called(1);
    });
    
    test('refreshProfile should update state with refreshed profile', () async {
      // Arrange - First load a profile
      when(mockRepository.getProfile(testUserId))
          .thenAnswer((_) async => testDomainProfile);
      
      final profileNotifier = ProfileNotifier(mockRepository);
      await profileNotifier.loadProfile(testUserId);
      
      // Update the mock to return an updated profile
      const updatedDomainProfile = domain.UserProfile(
        id: testUserId,
        displayName: 'Updated User',
        username: 'testuser',
        email: 'test@example.com',
        bio: 'Updated bio',
        photoUrl: 'https://example.com/updated-avatar.jpg',
        interests: ['Tech', 'Music', 'Art'],
        major: 'Computer Science',
        residenceType: 'Updated Residence',
      );
      
      when(mockRepository.getProfile(testUserId))
          .thenAnswer((_) async => updatedDomainProfile);
      
      // Act
      await profileNotifier.refreshProfile();
      
      // Assert
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, isNotNull);
      expect(profileNotifier.state.profile!.displayName, equals('Updated User'));
      expect(profileNotifier.state.profile!.bio, equals('Updated bio'));
      
      verify(mockRepository.getProfile(testUserId)).called(2); // Once for load, once for refresh
    });
    
    test('updateProfile should update profile and state when successful', () async {
      // Arrange
      final updatedModelProfile = model.UserProfile(
        id: testUserId,
        displayName: 'Updated User',
        username: 'testuser',
        email: 'test@example.com',
        bio: 'Updated bio',
        profileImageUrl: 'https://example.com/avatar.jpg',
        interests: const ['Tech', 'Music', 'Art'],
        year: 'Junior',
        major: 'Computer Science',
        residence: 'Test Residence',
        eventCount: 0,
        spaceCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(mockRepository.updateProfile(any))
          .thenAnswer((_) async => true);
      
      final profileNotifier = ProfileNotifier(mockRepository);
      
      // Act
      final result = await profileNotifier.updateProfile(updatedModelProfile);
      
      // Assert
      expect(result, isTrue);
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.profile, equals(updatedModelProfile));
      expect(profileNotifier.state.error, isNull);
      
      verify(mockRepository.updateProfile(any)).called(1);
    });
    
    test('updateProfile should update state with error when update fails', () async {
      // Arrange
      final updatedModelProfile = model.UserProfile(
        id: testUserId,
        displayName: 'Updated User',
        username: 'testuser',
        email: 'test@example.com',
        bio: 'Updated bio',
        profileImageUrl: 'https://example.com/avatar.jpg',
        interests: const ['Tech', 'Music', 'Art'],
        year: 'Junior',
        major: 'Computer Science',
        residence: 'Test Residence',
        eventCount: 0,
        spaceCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(mockRepository.updateProfile(any))
          .thenThrow(Exception('Update failed'));
      
      final profileNotifier = ProfileNotifier(mockRepository);
      
      // Act
      final result = await profileNotifier.updateProfile(updatedModelProfile);
      
      // Assert
      expect(result, isFalse);
      expect(profileNotifier.state.isLoading, isFalse);
      expect(profileNotifier.state.error, contains('Failed to update profile'));
      expect(profileNotifier.state.hasError, isTrue);
      
      verify(mockRepository.updateProfile(any)).called(1);
    });
    
    test('profile state when method should correctly pattern match', () {
      // Arrange - create different states
      const loadingState = ProfileState(isLoading: true);
      const errorState = ProfileState(error: 'Test error');
      final dataState = ProfileState(
        profile: model.UserProfile(
          id: testUserId,
          displayName: 'Test User',
          username: 'testuser',
          email: 'test@example.com',
          bio: 'This is a test bio',
          profileImageUrl: 'https://example.com/avatar.jpg',
          interests: const ['Tech', 'Music'],
          year: 'Junior',
          major: 'Computer Science',
          residence: 'Test Residence',
          eventCount: 0,
          spaceCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Act & Assert - Test when() method
      final loadingResult = loadingState.when(
        data: (profile) => 'data',
        loading: () => 'loading',
        error: (err) => 'error: $err',
      );
      expect(loadingResult, equals('loading'));
      
      final errorResult = errorState.when(
        data: (profile) => 'data',
        loading: () => 'loading',
        error: (err) => 'error: $err',
      );
      expect(errorResult, equals('error: Test error'));
      
      final dataResult = dataState.when(
        data: (profile) => 'data: ${profile.displayName}',
        loading: () => 'loading',
        error: (err) => 'error: $err',
      );
      expect(dataResult, equals('data: Test User'));
      
      // Test whenWidget() method
      final dataWidget = dataState.whenWidget(
        data: (profile) => Text(profile.displayName),
      );
      expect(dataWidget, isA<Text>());
      
      final loadingWidget = loadingState.whenWidget(
        data: (profile) => Text(profile.displayName),
      );
      expect(loadingWidget, isA<Center>());
      expect((loadingWidget as Center).child, isA<CircularProgressIndicator>());
      
      final errorWidget = errorState.whenWidget(
        data: (profile) => Text(profile.displayName),
      );
      expect(errorWidget, isA<Center>());
      expect((errorWidget as Center).child, isA<Text>());
      expect(((errorWidget).child as Text).data, equals('Test error'));
    });
  });
  
  group('ProfileSyncNotifier Tests', () {
    test('initial state should have isSyncing false and null lastSyncTime', () {
      final syncNotifier = ProfileSyncNotifier(mockRepository);
      
      expect(syncNotifier.state.isSyncing, isFalse);
      expect(syncNotifier.state.lastSyncTime, isNull);
      expect(syncNotifier.state.error, isNull);
    });
    
    test('syncProfile should update state with lastSyncTime when successful', () async {
      // Arrange
      final syncNotifier = ProfileSyncNotifier(mockRepository);
      
      // Act
      await syncNotifier.syncProfile();
      
      // Assert
      expect(syncNotifier.state.isSyncing, isFalse);
      expect(syncNotifier.state.lastSyncTime, isNotNull);
      expect(syncNotifier.state.error, isNull);
    });
    
    test('scheduleSyncProfile should not sync if last sync was recent', () async {
      // Arrange - First sync
      final syncNotifier = ProfileSyncNotifier(mockRepository);
      await syncNotifier.syncProfile();
      
      // Capture the last sync time
      final lastSyncTime = syncNotifier.state.lastSyncTime;
      
      // Act - Try to sync again immediately
      await syncNotifier.scheduleSyncProfile();
      
      // Assert - Should still have same lastSyncTime
      expect(syncNotifier.state.lastSyncTime, equals(lastSyncTime));
    });
    
    test('scheduleSyncProfile should sync if no previous sync', () async {
      // Arrange
      final syncNotifier = ProfileSyncNotifier(mockRepository);
      
      // Act
      await syncNotifier.scheduleSyncProfile();
      
      // Assert
      expect(syncNotifier.state.lastSyncTime, isNotNull);
    });
  });
} 