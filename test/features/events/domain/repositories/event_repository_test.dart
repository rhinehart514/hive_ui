import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/features/events/domain/entities/event.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/models/attendance_record.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Create custom type matcher functions
class _AnyBool extends Matcher {
  const _AnyBool();
  @override
  bool matches(dynamic item, Map matchState) => item is bool;
  @override
  Description describe(Description description) => description.add('any bool value');
}

class _AnyString extends Matcher {
  const _AnyString();
  @override
  bool matches(dynamic item, Map matchState) => item is String;
  @override
  Description describe(Description description) => description.add('any string value');
}

class _AnyInt extends Matcher {
  const _AnyInt();
  @override
  bool matches(dynamic item, Map matchState) => item is int;
  @override
  Description describe(Description description) => description.add('any int value');
}

// Exposing matcher functions
Matcher anyBool() => const _AnyBool();
Matcher anyString() => const _AnyString();
Matcher anyInt() => const _AnyInt();

// Manual mock implementation instead of using build_runner
class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
  });

  group('EventRepository', () {
    // Create a test event with all required parameters
    final testEvent = Event.create(
      id: 'test-event-1',
      title: 'Test Event',
      description: 'This is a test event',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
      location: 'Test Location',
      spaceId: 'test-space-1',
      createdBy: 'test-user-1',
      organizerEmail: 'test@example.com',
      organizerName: 'Test Organizer',
      category: 'Test Category',
      status: 'active',
      link: 'https://example.com/event',
      imageUrl: 'https://example.com/image.jpg',
      source: EventSource.external,
    );

    test('fetchEvents returns events with pagination', () async {
      // Arrange
      final expectedEvent = Event.create(
        id: '1',
        title: 'Test Event',
        description: 'Test Description',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(hours: 2)),
        location: 'Test Location',
        imageUrl: 'https://example.com/image.jpg',
        organizerEmail: 'test@example.com',
        organizerName: 'Test Organizer',
        category: 'Test Category',
        status: 'confirmed',
        link: 'https://example.com/event',
        source: EventSource.user,
      );
      
      final expectedResult = {
        'events': [expectedEvent],
        'hasMore': false,
        'total': 1,
      };

      // Set up the mock response without using matchers
      when(
        mockRepository.fetchEvents(
          forceRefresh: false,
          page: 1,
          pageSize: 20,
        ),
      ).thenAnswer((_) => Future.value(expectedResult));

      // Act
      final result = await mockRepository.fetchEvents(
        forceRefresh: false,
        page: 1,
        pageSize: 20,
      );

      // Assert
      expect(result, equals(expectedResult));
      verify(mockRepository.fetchEvents(
        forceRefresh: false,
        page: 1,
        pageSize: 20,
      )).called(1);
    });

    test('getEventById returns event when it exists', () async {
      // Arrange
      when(mockRepository.getEventById('test-event-1'))
          .thenAnswer((_) => Future.value(testEvent));

      // Act
      final result = await mockRepository.getEventById('test-event-1');

      // Assert
      expect(result, equals(testEvent));
      verify(mockRepository.getEventById('test-event-1')).called(1);
    });

    test('getEventById returns null when event does not exist', () async {
      // Arrange
      when(mockRepository.getEventById('non-existent-id'))
          .thenAnswer((_) => Future<Event?>.value(null));

      // Act
      final result = await mockRepository.getEventById('non-existent-id');

      // Assert
      expect(result, isNull);
      verify(mockRepository.getEventById('non-existent-id')).called(1);
    });

    test('saveRsvpStatus returns true when operation succeeds', () async {
      // Arrange
      when(
        mockRepository.saveRsvpStatus(
          '123',
          'user-456',
          true,
        ),
      ).thenAnswer((_) => Future.value(true));

      // Act
      final result = await mockRepository.saveRsvpStatus(
        '123',
        'user-456',
        true,
      );

      // Assert
      expect(result, isTrue);
      verify(mockRepository.saveRsvpStatus(
        '123',
        'user-456',
        true,
      )).called(1);
    });

    test('getTrendingEvents returns trending events', () async {
      // Arrange
      final trendingEvent = Event.create(
        id: '2',
        title: 'Trending Event',
        description: 'Trending Description',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(hours: 3)),
        location: 'Trending Location',
        imageUrl: 'https://example.com/trending.jpg',
        organizerEmail: 'trend@example.com',
        organizerName: 'Trend Organizer',
        category: 'Trending Category',
        status: 'confirmed',
        link: 'https://example.com/trending',
        source: EventSource.user,
      );
      
      final trendingEvents = [trendingEvent];

      when(
        mockRepository.getTrendingEvents(limit: 5),
      ).thenAnswer((_) => Future.value(trendingEvents));

      // Act
      final result = await mockRepository.getTrendingEvents(limit: 5);

      // Assert
      expect(result, equals(trendingEvents));
      verify(mockRepository.getTrendingEvents(limit: 5)).called(1);
    });
  });
} 