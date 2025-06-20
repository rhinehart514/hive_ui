import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/features/events/domain/entities/event.dart';

/// Use case for getting an event by ID
class GetEventByIdUseCase {
  final EventRepository _repository;

  /// Constructor
  GetEventByIdUseCase(this._repository);

  /// Execute the use case
  Future<Event?> execute(String eventId) async {
    return _repository.getEventById(eventId);
  }
}

/// Provider for the GetEventByIdUseCase
final getEventByIdUseCaseProvider = Provider<GetEventByIdUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetEventByIdUseCase(repository);
}); 