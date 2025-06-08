import 'package:hive_ui/models/event.dart';

/// Helper functions to create test objects for Event model
class TestEventFactory {
  /// Create a test event with minimal required fields
  /// 
  /// This simplifies test creation by providing sensible defaults for all required fields
  static Event createTestEvent({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? spaceId,
    String? createdBy,
    String? organizerEmail,
    String? organizerName,
    String? category,
    String? status,
    String? link,
    String? imageUrl,
    EventSource? source,
  }) {
    final now = DateTime.now();
    
    return Event(
      id: id ?? 'test-event-id',
      title: title ?? 'Test Event',
      description: description ?? 'This is a test event',
      startDate: startDate ?? now.add(const Duration(days: 1)),
      endDate: endDate ?? now.add(const Duration(days: 1, hours: 2)),
      location: location ?? 'Test Location',
      spaceId: spaceId ?? 'test-space-id',
      createdBy: createdBy ?? 'test-user-id',
      organizerEmail: organizerEmail ?? 'test@example.com',
      organizerName: organizerName ?? 'Test Organizer',
      category: category ?? 'Test Category',
      status: status ?? 'active',
      link: link ?? 'https://example.com/event',
      imageUrl: imageUrl ?? 'https://example.com/image.jpg',
      source: source ?? EventSource.external,
    );
  }
  
  /// Create a list of test events
  static List<Event> createTestEventList({int count = 3}) {
    return List.generate(count, (index) => 
      createTestEvent(
        id: 'test-event-$index',
        title: 'Test Event $index',
      )
    );
  }
  
  /// Create a mock event repository response for pagination
  static Map<String, dynamic> createEventPaginationResponse({
    List<Event>? events,
    bool hasMore = false,
    int? total,
  }) {
    final eventList = events ?? createTestEventList();
    
    return {
      'events': eventList,
      'hasMore': hasMore,
      'total': total ?? eventList.length,
    };
  }
} 