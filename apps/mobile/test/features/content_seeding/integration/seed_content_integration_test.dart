import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/data/repositories/firebase_seed_content_repository.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';
import 'package:hive_ui/features/content_seeding/presentation/widgets/seed_content_card.dart';

// Create a provider for the repository
final seedContentRepositoryProvider = Provider<FirebaseSeedContentRepository>((ref) {
  final firestore = FakeFirebaseFirestore();
  return FirebaseSeedContentRepository(firestore: firestore);
});

// Create a provider for seed content list
final seedContentListProvider = FutureProvider<List<SeedContentEntity>>((ref) async {
  final repository = ref.watch(seedContentRepositoryProvider);
  return repository.getAllSeedContent();
});

// Helper functions to create and add test content
Future<SeedContentEntity> createAndAddTestContent({
  required FirebaseSeedContentRepository repository,
  required String id,
  required String title,
  required String description,
  required SeedContentType type,
  required SeedingStatus status,
}) async {
  final now = DateTime.now();
  final content = SeedContentEntity(
    id: id,
    type: type,
    data: {
      'title': title,
      'description': description,
    },
    status: status,
    environment: SeedingEnvironment.development,
    seedForNewUsers: true,
    replaceExisting: false,
    priority: 0,
    dependencies: [],
    tags: ['test', 'integration'],
    metadata: {},
    createdAt: now,
    updatedAt: now,
  );
  
  await repository.createSeedContent(content);
  return content;
}

// Test component that displays a list of seed content cards
class SeedContentListView extends ConsumerWidget {
  final Function(SeedContentEntity)? onItemTap;
  
  const SeedContentListView({Key? key, this.onItemTap}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsyncValue = ref.watch(seedContentListProvider);
    
    return contentAsyncValue.when(
      data: (seedContents) {
        if (seedContents.isEmpty) {
          return const Center(child: Text('No seed content available'));
        }
        
        return ListView.builder(
          itemCount: seedContents.length,
          itemBuilder: (context, index) {
            final content = seedContents[index];
            return SeedContentCard(
              seedContent: content,
              onTap: () => onItemTap?.call(content),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading seed content: $error'),
      ),
    );
  }
}

void main() {
  testWidgets('Seed content integration test - repository to UI', (WidgetTester tester) async {
    // Setup a container with overrides
    final container = ProviderContainer();
    addTearDown(container.dispose);
    
    // Get the repository from the container
    final repository = container.read(seedContentRepositoryProvider);
    
    // Add test content
    await createAndAddTestContent(
      repository: repository,
      id: 'test-1',
      title: 'Event Info Seed',
      description: 'Seeds initial event data',
      type: SeedContentType.event,
      status: SeedingStatus.completed,
    );
    
    await createAndAddTestContent(
      repository: repository,
      id: 'test-2',
      title: 'User Profiles Seed',
      description: 'Seeds sample user profiles',
      type: SeedContentType.profile,
      status: SeedingStatus.pending,
    );
    
    // Track which item was tapped
    SeedContentEntity? tappedContent;
    
    // Build the widget tree using the ProviderScope with our container
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Seed Content'),
            ),
            body: SeedContentListView(
              onItemTap: (content) {
                tappedContent = content;
              },
            ),
          ),
        ),
      ),
    );
    
    // Initial frame has the loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Wait for the data to load
    await tester.pumpAndSettle();
    
    // Verify that loading indicator is gone
    expect(find.byType(CircularProgressIndicator), findsNothing);
    
    // Verify that both content items are displayed
    expect(find.text('Event Info Seed'), findsOneWidget);
    expect(find.text('User Profiles Seed'), findsOneWidget);
    
    // Verify status indicators
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    
    // Verify type indicators
    expect(find.text('EVENT'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    
    // Tap the first item
    await tester.tap(find.text('Event Info Seed'));
    await tester.pump();
    
    // Verify the correct item was tapped
    expect(tappedContent, isNotNull);
    expect(tappedContent?.id, equals('test-1'));
    expect(tappedContent?.type, equals(SeedContentType.event));
    
    // Test adding a new content item
    await createAndAddTestContent(
      repository: repository,
      id: 'test-3',
      title: 'Space Configuration Seed',
      description: 'Seeds initial space configurations',
      type: SeedContentType.space,
      status: SeedingStatus.inProgress,
    );
    
    // Rebuild to refresh the data
    await tester.pumpAndSettle();
    
    // Verify the new item appears
    expect(find.text('Space Configuration Seed'), findsOneWidget);
    expect(find.text('SPACE'), findsOneWidget);
    expect(find.text('IN_PROGRESS'), findsOneWidget);
    
    // Test updating an existing item
    await repository.updateSeedContentStatus(
      'test-2',
      SeedingStatus.failed,
      errorMessage: 'Failed to seed profiles',
    );
    
    // Rebuild to refresh the data
    await tester.pumpAndSettle();
    
    // Verify the status was updated
    expect(find.text('FAILED'), findsOneWidget);
  });
} 