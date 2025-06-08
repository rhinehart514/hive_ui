import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/content_seeding/data/models/seed_content_model.dart';
import 'package:hive_ui/features/content_seeding/domain/entities/seed_content_entity.dart';
import 'package:hive_ui/features/content_seeding/presentation/widgets/seed_content_card.dart';

// Helper to create test seed content
SeedContentEntity createTestSeedContent({
  String? id,
  SeedContentType? type,
  SeedingStatus? status,
  String? title,
  String? description,
}) {
  final now = DateTime.now();
  final data = <String, dynamic>{
    'title': title ?? 'Test Content',
    'description': description ?? 'This is test content',
  };
  
  return SeedContentEntity(
    id: id ?? 'test-seed-id',
    type: type ?? SeedContentType.post,
    data: data,
    status: status ?? SeedingStatus.pending,
    environment: SeedingEnvironment.development,
    seedForNewUsers: true,
    replaceExisting: false,
    priority: 0,
    dependencies: [],
    tags: ['test', 'sample'],
    metadata: {},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('SeedContentCard displays content information correctly', (WidgetTester tester) async {
    // Create test content
    final testContent = createTestSeedContent(
      title: 'Sample Post',
      description: 'This is a sample post for testing',
      type: SeedContentType.post,
      status: SeedingStatus.pending,
    );
    
    bool onTapCalled = false;
    
    // Build our widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeedContentCard(
              seedContent: testContent,
              onTap: () {
                onTapCalled = true;
              },
            ),
          ),
        ),
      ),
    );

    // Verify content title is displayed
    expect(find.text('Sample Post'), findsOneWidget);
    
    // Verify content description is displayed
    expect(find.text('This is a sample post for testing'), findsOneWidget);
    
    // Verify type is displayed
    expect(find.text('POST'), findsOneWidget);
    
    // Verify status is displayed
    expect(find.text('PENDING'), findsOneWidget);
    
    // Tap on the card
    await tester.tap(find.byType(SeedContentCard));
    await tester.pump();
    
    // Verify onTap was called
    expect(onTapCalled, isTrue);
  });

  testWidgets('SeedContentCard displays status with appropriate style', (WidgetTester tester) async {
    // Create test content with different statuses
    final pendingContent = createTestSeedContent(
      title: 'Pending Content',
      status: SeedingStatus.pending,
    );
    
    final completedContent = createTestSeedContent(
      title: 'Completed Content',
      status: SeedingStatus.completed,
    );
    
    final failedContent = createTestSeedContent(
      title: 'Failed Content',
      status: SeedingStatus.failed,
    );
    
    // Test pending content
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeedContentCard(
              seedContent: pendingContent,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    
    // Verify pending status is displayed with expected style
    expect(find.text('PENDING'), findsOneWidget);
    
    // Find the status indicator widget
    final pendingStatusFinder = find.byWidgetPredicate(
      (widget) => widget is Container && 
                 (widget.decoration as BoxDecoration?)?.color != null &&
                 (widget.decoration as BoxDecoration).color == const Color(0xFFE6E6E6)
    );
    
    expect(pendingStatusFinder, findsOneWidget);
    
    // Test completed content
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeedContentCard(
              seedContent: completedContent,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    
    // Verify completed status is displayed with expected style
    expect(find.text('COMPLETED'), findsOneWidget);
    
    // Find the status indicator widget
    final completedStatusFinder = find.byWidgetPredicate(
      (widget) => widget is Container && 
                 (widget.decoration as BoxDecoration?)?.color != null &&
                 (widget.decoration as BoxDecoration).color == const Color(0xFF4CAF50)
    );
    
    expect(completedStatusFinder, findsOneWidget);
    
    // Test failed content
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeedContentCard(
              seedContent: failedContent,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    
    // Verify failed status is displayed with expected style
    expect(find.text('FAILED'), findsOneWidget);
    
    // Find the status indicator widget
    final failedStatusFinder = find.byWidgetPredicate(
      (widget) => widget is Container && 
                 (widget.decoration as BoxDecoration?)?.color != null &&
                 (widget.decoration as BoxDecoration).color == const Color(0xFFF44336)
    );
    
    expect(failedStatusFinder, findsOneWidget);
  });

  testWidgets('SeedContentCard handles null values gracefully', (WidgetTester tester) async {
    // Create test content with minimal data
    final now = DateTime.now();
    final minimalContent = SeedContentEntity(
      id: 'minimal-content',
      type: SeedContentType.post,
      data: {}, // Empty data map - should handle missing title/description
      status: SeedingStatus.pending,
      environment: SeedingEnvironment.development,
      seedForNewUsers: true,
      replaceExisting: false,
      priority: 0,
      dependencies: [],
      tags: [],
      metadata: {},
      createdAt: now,
      updatedAt: now,
    );
    
    // Build our widget
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SeedContentCard(
              seedContent: minimalContent,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Verify it doesn't crash and displays fallback or empty values
    expect(find.text('Untitled'), findsOneWidget); // Fallback title
    expect(find.text('No description'), findsOneWidget); // Fallback description
  });
} 