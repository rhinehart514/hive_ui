import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/data/mappers/event_mapper.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/models/event.dart';

/// Provider that fetches events as UI model objects for a specific space
final spaceEventsModelProvider = FutureProvider.family<List<Event>, String>((ref, spaceId) async {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  
  // Fetch domain events from the repository
  final domainEvents = await spacesRepository.getSpaceEvents(spaceId);
  
  // Map domain events to model events for the UI
  return domainEvents.map(EventMapper.toModel).toList();
}); 