import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';

/// Event emitted when an event is boosted
class EventBoostedEvent extends AppEvent {
  final String eventId;
  final String userId;
  
  const EventBoostedEvent({
    required this.eventId,
    required this.userId,
  });
}

/// Use case for boosting an event's visibility in feeds
class BoostEventUseCase {
  final EventRepository _repository;
  final AppEventBus _eventBus;

  /// Constructor
  BoostEventUseCase(
    this._repository, {
    AppEventBus? eventBus,
  }) : _eventBus = eventBus ?? AppEventBus();

  /// Execute the use case to boost an event
  /// 
  /// This implements the Boost System described in the business logic:
  /// - Limited to Verified+ accounts
  /// - Temporary visibility increase
  /// - Logged and auditable
  /// - Effects are time-boxed
  Future<bool> execute(String eventId, String userId) async {
    try {
      // Boost the event in the repository
      final success = await _repository.boostEvent(eventId, userId);
      
      if (success) {
        // Emit event to notify all listeners about the change
        _eventBus.emit(EventBoostedEvent(
          eventId: eventId,
          userId: userId,
        ));
      }
      
      return success;
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for the BoostEventUseCase
final boostEventUseCaseProvider = Provider<BoostEventUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return BoostEventUseCase(repository);
}); 