import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/data/mappers/event_mapper.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/models/event.dart';

/// Provider that fetches events for a specific space
class SpaceEventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final SpacesRepository _repository;
  
  SpaceEventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Initial state is loading
  }
  
  /// Fetch events for the given space ID
  Future<void> fetchEvents(String spaceId, {int limit = 10}) async {
    // Set to loading state
    state = const AsyncValue.loading();
    
    try {
      // Fetch domain events from the repository
      final domainEvents = await _repository.getSpaceEvents(spaceId, limit: limit);
      
      // Map domain events to model events
      final modelEvents = domainEvents.map(EventMapper.toModel).toList();
      
      // Set state to data
      state = AsyncValue.data(modelEvents);
    } catch (e, stackTrace) {
      debugPrint('Error fetching space events: $e');
      // Set state to error
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for space events
final spaceEventsProvider = StateNotifierProvider.family<SpaceEventsNotifier, AsyncValue<List<Event>>, String>(
  (ref, spaceId) {
    final repository = ref.watch(spacesRepositoryProvider);
    final notifier = SpaceEventsNotifier(repository);
    // Fetch events immediately
    notifier.fetchEvents(spaceId);
    return notifier;
  },
); 