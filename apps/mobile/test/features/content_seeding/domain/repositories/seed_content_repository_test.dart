import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/data/repositories/firebase_seed_content_repository.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';

// Helper factory for creating test seed content
class TestSeedContentFactory {
  // Create a test seed content entity with default values
  static SeedContentEntity createTestSeedContent({
    String? id,
    SeedContentType? type,
    Map<String, dynamic>? data,
    SeedingStatus? status,
    SeedingEnvironment? environment,
    bool? seedForNewUsers,
    bool? replaceExisting,
    int? priority,
    List<String>? dependencies,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    final now = DateTime.now();
    
    return SeedContentEntity(
      id: id ?? 'test-seed-id',
      type: type ?? SeedContentType.post,
      data: data ?? {'title': 'Test Content', 'body': 'This is test content'},
      status: status ?? SeedingStatus.pending,
      environment: environment ?? SeedingEnvironment.development,
      seedForNewUsers: seedForNewUsers ?? true,
      replaceExisting: replaceExisting ?? false,
      priority: priority ?? 0,
      dependencies: dependencies ?? [],
      tags: tags ?? ['test', 'sample'],
      metadata: metadata ?? {},
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      errorMessage: errorMessage,
    );
  }
  
  // Create a list of test seed content
  static List<SeedContentEntity> createTestSeedContentList({int count = 3}) {
    return List.generate(count, (index) => 
      createTestSeedContent(
        id: 'test-seed-$index',
        priority: index,
      )
    );
  }
  
  // Helper method to add test seed content to fake Firestore
  static Future<void> addSeedContentToFirestore(
    FakeFirebaseFirestore firestore,
    List<SeedContentEntity> seedContents,
  ) async {
    final collection = firestore.collection('seed_content');
    
    for (final entity in seedContents) {
      final model = SeedContentModel.fromEntity(entity);
      await collection.doc(entity.id).set(model.toFirestore());
    }
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseSeedContentRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseSeedContentRepository(firestore: fakeFirestore);
  });

  group('FirebaseSeedContentRepository', () {
    test('getAllSeedContent returns empty list when no content exists', () async {
      // Act
      final result = await repository.getAllSeedContent();
      
      // Assert
      expect(result, isEmpty);
    });

    test('getAllSeedContent returns content when it exists', () async {
      // Arrange
      final testData = TestSeedContentFactory.createTestSeedContentList();
      await TestSeedContentFactory.addSeedContentToFirestore(fakeFirestore, testData);
      
      // Act
      final result = await repository.getAllSeedContent();
      
      // Assert
      expect(result, hasLength(testData.length));
      expect(result.map((e) => e.id).toList(), containsAll(testData.map((e) => e.id).toList()));
    });

    test('getSeedContentById returns null when content does not exist', () async {
      // Act
      final result = await repository.getSeedContentById('non-existent-id');
      
      // Assert
      expect(result, isNull);
    });

    test('getSeedContentById returns content when it exists', () async {
      // Arrange
      final testEntity = TestSeedContentFactory.createTestSeedContent(
        id: 'test-specific-id',
        type: SeedContentType.event,
        data: {'title': 'Special Event', 'description': 'A special test event'},
      );
      await TestSeedContentFactory.addSeedContentToFirestore(fakeFirestore, [testEntity]);
      
      // Act
      final result = await repository.getSeedContentById('test-specific-id');
      
      // Assert
      expect(result, isNotNull);
      expect(result?.id, equals('test-specific-id'));
      expect(result?.type, equals(SeedContentType.event));
      expect(result?.data['title'], equals('Special Event'));
    });
    
    test('getCompletedSeedCount handles null count value from Firestore', () async {
      // This test simulates the case where the count might be null
      // Note: Using fake_cloud_firestore, we can't directly manipulate the count result
      // But we can test that the repository returns 0 instead of throwing an error
      
      // Act
      final result = await repository.getCompletedSeedCount();
      
      // Assert
      expect(result, equals(0));
    });

    test('getSeedStatusCounts handles null counts properly', () async {
      // Act
      final result = await repository.getSeedStatusCounts();
      
      // Assert
      // Verify we have an entry for each status with a count of 0
      for (final status in SeedingStatus.values) {
        expect(result[status], equals(0));
      }
    });
    
    test('getSeedContentForEnvironment properly filters content', () async {
      // Arrange
      final devContent = TestSeedContentFactory.createTestSeedContent(
        id: 'dev-content',
        environment: SeedingEnvironment.development,
      );
      final prodContent = TestSeedContentFactory.createTestSeedContent(
        id: 'prod-content',
        environment: SeedingEnvironment.production,
      );
      final allContent = TestSeedContentFactory.createTestSeedContent(
        id: 'all-content',
        environment: SeedingEnvironment.all,
      );
      
      await TestSeedContentFactory.addSeedContentToFirestore(
        fakeFirestore, 
        [devContent, prodContent, allContent]
      );
      
      // Act - get dev environment content
      final devResult = await repository.getSeedContentForEnvironment(SeedingEnvironment.development);
      
      // Assert
      expect(devResult, hasLength(2)); // Should include dev and all
      expect(devResult.map((e) => e.id).toList(), containsAll(['dev-content', 'all-content']));
      
      // Act - get prod environment content
      final prodResult = await repository.getSeedContentForEnvironment(SeedingEnvironment.production);
      
      // Assert
      expect(prodResult, hasLength(2)); // Should include prod and all
      expect(prodResult.map((e) => e.id).toList(), containsAll(['prod-content', 'all-content']));
    });
    
    test('getSeedContentForEnvironment with forNewUsersOnly filters correctly', () async {
      // Arrange
      final newUserContent = TestSeedContentFactory.createTestSeedContent(
        id: 'new-user-content',
        seedForNewUsers: true,
      );
      final existingUserContent = TestSeedContentFactory.createTestSeedContent(
        id: 'existing-user-content',
        seedForNewUsers: false,
      );
      
      await TestSeedContentFactory.addSeedContentToFirestore(
        fakeFirestore, 
        [newUserContent, existingUserContent]
      );
      
      // Act
      final result = await repository.getSeedContentForEnvironment(
        SeedingEnvironment.development,
        forNewUsersOnly: true,
      );
      
      // Assert
      expect(result, hasLength(1));
      expect(result.first.id, equals('new-user-content'));
    });
    
    test('getSeedContentByType returns content of specific type', () async {
      // Arrange
      final postContent = TestSeedContentFactory.createTestSeedContent(
        id: 'post-content',
        type: SeedContentType.post,
      );
      final eventContent = TestSeedContentFactory.createTestSeedContent(
        id: 'event-content',
        type: SeedContentType.event,
      );
      
      await TestSeedContentFactory.addSeedContentToFirestore(
        fakeFirestore, 
        [postContent, eventContent]
      );
      
      // Act
      final result = await repository.getSeedContentByType(SeedContentType.event);
      
      // Assert
      expect(result, hasLength(1));
      expect(result.first.id, equals('event-content'));
    });
    
    test('getSeedContentByTags returns content matching any tag', () async {
      // Arrange
      final content1 = TestSeedContentFactory.createTestSeedContent(
        id: 'content-1',
        tags: ['tag1', 'tag2'],
      );
      final content2 = TestSeedContentFactory.createTestSeedContent(
        id: 'content-2',
        tags: ['tag2', 'tag3'],
      );
      final content3 = TestSeedContentFactory.createTestSeedContent(
        id: 'content-3',
        tags: ['tag4'],
      );
      
      await TestSeedContentFactory.addSeedContentToFirestore(
        fakeFirestore, 
        [content1, content2, content3]
      );
      
      // Act
      final result = await repository.getSeedContentByTags(['tag1', 'tag3']);
      
      // Assert
      expect(result, hasLength(2));
      expect(result.map((e) => e.id).toList(), containsAll(['content-1', 'content-2']));
    });
    
    test('watchSeedContent stream emits updated content', () async {
      // Arrange
      final initialContent = TestSeedContentFactory.createTestSeedContent(
        id: 'stream-test',
      );
      await TestSeedContentFactory.addSeedContentToFirestore(
        fakeFirestore, 
        [initialContent]
      );
      
      // Act & Assert
      final stream = repository.watchSeedContent();
      
      // Expect the initial content
      await expectLater(
        stream.first, 
        completion(hasLength(1))
      );
      
      // Add new content
      final newContent = TestSeedContentFactory.createTestSeedContent(
        id: 'new-content',
      );
      await TestSeedContentFactory.addSeedContentToFirestore(
        fakeFirestore, 
        [newContent]
      );
      
      // Expect updated content (now 2 items)
      await expectLater(
        stream.first, 
        completion(hasLength(2))
      );
    });
  });
} 