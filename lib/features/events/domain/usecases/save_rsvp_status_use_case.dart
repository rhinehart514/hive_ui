import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';

/// Use case for saving RSVP status for an event
class SaveRsvpStatusUseCase {
  final EventRepository _repository;

  /// Constructor
  SaveRsvpStatusUseCase(this._repository);

  /// Execute the use case to save RSVP status
  Future<bool> execute(String eventId, String userId, bool isAttending) async {
    return _repository.saveRsvpStatus(eventId, userId, isAttending);
  }
}

/// Provider for the SaveRsvpStatusUseCase
final saveRsvpStatusUseCaseProvider = Provider<SaveRsvpStatusUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return SaveRsvpStatusUseCase(repository);
}); 