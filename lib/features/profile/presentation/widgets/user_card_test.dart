import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/features/profile/presentation/widgets/user_card.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  // Helper to build user card widget with provider scope
  Widget buildUserCard(UserProfile user) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold,
            background: AppColors.black,
            surface: AppColors.cardBackground,
          ),
        ),
        home: Scaffold(
          body: UserCard(
            user: user,
            onTap: () {},
            onFollow: (isFollowing) {},
          ),
        ),
      ),
    );
  }

  // Mock user profile
  UserProfile createMockUser({
    required String id,
    required String displayName,
    String? profileImageUrl,
    bool isVerified = false,
    String year = 'Junior',
    String major = 'Computer Science',
    String? bio,
    List<String> interests = const [],
  }) {
    return UserProfile(
      id: id,
      username: displayName.toLowerCase().replaceAll(' ', ''),
      displayName: displayName,
      bio: bio,
      profileImageUrl: profileImageUrl,
      isVerified: isVerified,
      year: year,
      major: major,
      interests: interests,
      residence: 'Campus',
      eventCount: 5,
      spaceCount: 3,
      friendCount: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('UserCard Widget', () {
    testWidgets('renders user card with basic info', (WidgetTester tester) async {
      // Mock image network requests
      await mockNetworkImagesFor(() async {
        // Arrange
        final user = createMockUser(
          id: '1',
          displayName: 'John Doe',
          major: 'Computer Science',
          year: 'Junior',
        );

        // Act
        await tester.pumpWidget(buildUserCard(user));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Computer Science • Junior'), findsOneWidget);
      });
    });

    testWidgets('renders verification badge for verified users', (WidgetTester tester) async {
      // Mock image network requests
      await mockNetworkImagesFor(() async {
        // Arrange
        final user = createMockUser(
          id: '1',
          displayName: 'John Doe',
          isVerified: true,
        );

        // Act
        await tester.pumpWidget(buildUserCard(user));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.verified), findsOneWidget);
      });
    });

    testWidgets('renders bio when available', (WidgetTester tester) async {
      // Mock image network requests
      await mockNetworkImagesFor(() async {
        // Arrange
        final user = createMockUser(
          id: '1',
          displayName: 'John Doe',
          bio: 'Computer science student passionate about AI',
        );

        // Act
        await tester.pumpWidget(buildUserCard(user));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Computer science student passionate about AI'), findsOneWidget);
      });
    });

    testWidgets('renders interests when available', (WidgetTester tester) async {
      // Mock image network requests
      await mockNetworkImagesFor(() async {
        // Arrange
        final user = createMockUser(
          id: '1',
          displayName: 'John Doe',
          interests: ['Programming', 'AI', 'Machine Learning'],
        );

        // Act
        await tester.pumpWidget(buildUserCard(user));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Programming'), findsOneWidget);
        expect(find.text('AI'), findsOneWidget);
        expect(find.text('Machine Learning'), findsOneWidget);
      });
    });

    testWidgets('renders follow button', (WidgetTester tester) async {
      // Mock image network requests
      await mockNetworkImagesFor(() async {
        // Arrange
        final user = createMockUser(
          id: '1',
          displayName: 'John Doe',
        );

        // Act
        await tester.pumpWidget(buildUserCard(user));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });
  });
} 