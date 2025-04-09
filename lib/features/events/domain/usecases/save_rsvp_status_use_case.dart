import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';

/// Use case for saving RSVP status for an event
class SaveRsvpStatusUseCase {
  final EventRepository _repository;
  final AppEventBus _eventBus;

  /// Constructor
  SaveRsvpStatusUseCase(
    this._repository, {
    AppEventBus? eventBus,
  }) : _eventBus = eventBus ?? AppEventBus();

  /// Execute the use case to save RSVP status
  Future<bool> execute(String eventId, String userId, bool isAttending) async {
    try {
      // Save to backend
      final success = await _repository.saveRsvpStatus(eventId, userId, isAttending);
      
      if (success) {
        // Emit event to notify all listeners about the change
        _eventBus.emit(RsvpStatusChangedEvent(
          eventId: eventId,
          userId: userId,
          isAttending: isAttending,
        ));
      }
      
      return success;
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for the SaveRsvpStatusUseCase
final saveRsvpStatusUseCaseProvider = Provider<SaveRsvpStatusUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return SaveRsvpStatusUseCase(repository);
}); 