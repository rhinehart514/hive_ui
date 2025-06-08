import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';

/// Event emitted when an event is set to Honey Mode
class EventHoneyModeActivatedEvent extends AppEvent {
  final String eventId;
  final String userId;
  
  const EventHoneyModeActivatedEvent({
    required this.eventId,
    required this.userId,
  });
}

/// Use case for setting an event to Honey Mode for premium visibility
class HoneyModeUseCase {
  final EventRepository _repository;
  final AppEventBus _eventBus;

  /// Constructor
  HoneyModeUseCase(
    this._repository, {
    AppEventBus? eventBus,
  }) : _eventBus = eventBus ?? AppEventBus();

  /// Execute the use case to set an event to Honey Mode
  /// 
  /// This implements the Honey Mode System described in the business logic:
  /// - Once-per-month per Space limitation
  /// - Premium visibility state with enhanced UI treatment
  /// - Top-tier feed positioning
  /// - Effects last for limited duration
  Future<bool> execute(String eventId, String userId) async {
    try {
      // First check if honey mode is available for this event's space
      final event = await _repository.getEventById(eventId);
      if (event == null || event.spaceId == null) {
        return false;
      }
      
      // Check if the space has already used its honey mode allocation
      final isAvailable = await _repository.isHoneyModeAvailable(event.spaceId!);
      if (!isAvailable) {
        return false;
      }
      
      // Set the event to honey mode
      final success = await _repository.setEventHoneyMode(eventId, userId);
      
      if (success) {
        // Emit event to notify all listeners about the change
        _eventBus.emit(EventHoneyModeActivatedEvent(
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

/// Provider for the HoneyModeUseCase
final honeyModeUseCaseProvider = Provider<HoneyModeUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return HoneyModeUseCase(repository);
}); 