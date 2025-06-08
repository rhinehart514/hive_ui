import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_ui/features/profile/data/repositories/user_search_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';

// Manual mock class instead of generated
class MockUserSearchRepository extends Mock implements UserSearchRepository {
  @override
  Future<Either<AppFailure, List<UserProfile>>> searchUsers(UserSearchFilters filters) async {
    return super.noSuchMethod(
      Invocation.method(#searchUsers, [filters]),
      returnValue: Future.value(const Right<AppFailure, List<UserProfile>>([])),
    );
  }
}

// Custom AppFailure implementation for testing
class TestFailure extends AppFailure {
  TestFailure({required String userMessage, required String technicalMessage})
      : super(
          code: 'test_error',
          userMessage: userMessage,
          technicalMessage: technicalMessage,
        );
}

void main() {
  group('UserSearchRepository - Mocked', () {
    test('should return failure when repository error occurs', () async {
      // Arrange - setup a mocked repository for this test
      final mockRepository = MockUserSearchRepository();
      const testFilters = UserSearchFilters();
      
      when(mockRepository.searchUsers(testFilters)).thenAnswer(
        (_) async => Left<AppFailure, List<UserProfile>>(
          TestFailure(
            userMessage: 'Failed to search users', 
            technicalMessage: 'Repository error'
          )
        )
      );
      
      // Act
      final result = await mockRepository.searchUsers(testFilters);
      
      // Assert
      expect(result.isLeft(), true);
    });
  });
  
  group('UserSearchRepository - Real', () {
    late UserSearchRepositoryImpl repository;
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = UserSearchRepositoryImpl(firestore: firestore);
      
      // Setup test data
      _setupTestUsers(firestore);
    });
    
    test('should search users with empty filter', () async {
      // Arrange
      const filters = UserSearchFilters();
      
      // Act
      final result = await repository.searchUsers(filters);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (users) => expect(users.length, 4),
      );
    });

    test('should search users with name query', () async {
      // Arrange
      const filters = UserSearchFilters(query: 'John');
      
      // Act
      final result = await repository.searchUsers(filters);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (users) {
          expect(users.length, 1);
          expect(users.first.displayName, contains('John'));
        },
      );
    });

    test('should filter users by year', () async {
      // Arrange
      const filters = UserSearchFilters(year: 'Senior');
      
      // Act
      final result = await repository.searchUsers(filters);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (users) {
          expect(users.every((user) => user.year == 'Senior'), true);
        },
      );
    });

    test('should filter users by major', () async {
      // Arrange
      const filters = UserSearchFilters(major: 'Psychology');
      
      // Act
      final result = await repository.searchUsers(filters);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (users) {
          expect(users.every((user) => user.major == 'Psychology'), true);
        },
      );
    });

    test('should filter verified users only', () async {
      // Arrange
      const filters = UserSearchFilters(onlyVerified: true);
      
      // Act
      final result = await repository.searchUsers(filters);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (users) {
          expect(users.every((user) => user.isVerified), true);
        },
      );
    });

    test('should filter by activity level', () async {
      // Arrange
      const filters = UserSearchFilters(minActivityLevel: 80);
      
      // Act
      final result = await repository.searchUsers(filters);
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success, got failure'),
        (users) {
          expect(users.every((user) => user.activityLevel >= 80), true);
        },
      );
    });
  });
}

// Helper to setup test user data
void _setupTestUsers(FakeFirebaseFirestore firestore) {
  final now = DateTime.now();
  final usersCollection = firestore.collection('users');
  
  usersCollection.add({
    'id': '1',
    'username': 'johndoe',
    'displayName': 'John Doe',
    'bio': 'Computer Science student',
    'major': 'Computer Science',
    'year': 'Junior',
    'activityLevel': 85,
    'isVerified': true,
    'createdAt': now,
    'updatedAt': now,
    'interests': ['Programming', 'AI'],
  });
  
  usersCollection.add({
    'id': '2',
    'username': 'janesmith',
    'displayName': 'Jane Smith',
    'bio': 'Psychology major',
    'major': 'Psychology',
    'year': 'Senior',
    'activityLevel': 92,
    'isVerified': false,
    'createdAt': now,
    'updatedAt': now,
    'interests': ['Research', 'Mental Health'],
  });
  
  usersCollection.add({
    'id': '3',
    'username': 'michaelbrown',
    'displayName': 'Michael Brown',
    'bio': 'Engineering student',
    'major': 'Engineering',
    'year': 'Sophomore',
    'activityLevel': 65,
    'isVerified': true,
    'createdAt': now,
    'updatedAt': now,
    'interests': ['Robotics', 'Circuits'],
  });
  
  usersCollection.add({
    'id': '4',
    'username': 'sarahjones',
    'displayName': 'Sarah Jones',
    'bio': 'Business major',
    'major': 'Business',
    'year': 'Senior',
    'activityLevel': 78,
    'isVerified': true,
    'createdAt': now,
    'updatedAt': now,
    'interests': ['Marketing', 'Finance'],
  });
} 