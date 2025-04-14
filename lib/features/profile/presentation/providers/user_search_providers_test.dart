import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/features/profile/presentation/providers/user_search_providers.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('UserSearchProviders', () {
    test('userSearchFiltersProvider should have default empty filters', () {
      final filters = container.read(userSearchFiltersProvider);
      
      expect(filters.query, isNull);
      expect(filters.year, isNull);
      expect(filters.major, isNull);
      expect(filters.interests, isEmpty);
      expect(filters.onlyVerified, false);
      expect(filters.excludeFollowed, true);
    });

    test('updating userSearchFiltersProvider should update state', () {
      // Initial default state
      final initialFilters = container.read(userSearchFiltersProvider);
      expect(initialFilters.query, isNull);
      
      // Update filters
      container.read(userSearchFiltersProvider.notifier).state = 
          const UserSearchFilters(query: 'John');
      
      // Verify that state was updated
      final updatedFilters = container.read(userSearchFiltersProvider);
      expect(updatedFilters.query, equals('John'));
    });

    test('searchErrorProvider should be initially null', () {
      final error = container.read(searchErrorProvider);
      expect(error, isNull);
    });

    test('searchErrorProvider can be updated', () {
      // Set initial value
      container.read(searchErrorProvider.notifier).state = null;
      
      // Update error state
      const errorMessage = 'Failed to search';
      container.read(searchErrorProvider.notifier).state = errorMessage;
      
      // Verify update
      final error = container.read(searchErrorProvider);
      expect(error, equals(errorMessage));
    });
  });
} 