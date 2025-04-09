import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/domain/providers/recurring_event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/recurring_event_repository.dart';
import 'package:hive_ui/models/event_creation_request.dart';
import 'package:hive_ui/models/recurring_event.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// State for the recurring event controller
class RecurringEventState {
  /// Whether an operation is in progress
  final bool isLoading;
  
  /// Any error message
  final String? error;
  
  /// The currently active recurring event
  final RecurringEvent? currentEvent;
  
  /// The instances of the current event
  final List<RecurringEvent> instances;
  
  /// Constructor
  const RecurringEventState({
    this.isLoading = false,
    this.error,
    this.currentEvent,
    this.instances = const [],
  });
  
  /// Create a copy with updated fields
  RecurringEventState copyWith({
    bool? isLoading,
    String? error,
    RecurringEvent? currentEvent,
    List<RecurringEvent>? instances,
  }) {
    return RecurringEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentEvent: currentEvent ?? this.currentEvent,
      instances: instances ?? this.instances,
    );
  }
  
  /// Create an initial state
  static RecurringEventState initial() {
    return const RecurringEventState();
  }
}

/// Controller for recurring events
class RecurringEventController extends StateNotifier<RecurringEventState> {
  final RecurringEventRepository _repository;
  final AppEventBus _eventBus;
  
  /// Constructor
  RecurringEventController({
    required RecurringEventRepository repository,
    AppEventBus? eventBus,
  }) : 
    _repository = repository,
    _eventBus = eventBus ?? AppEventBus(),
    super(RecurringEventState.initial());
  
  /// Create a new recurring event
  Future<RecurringEvent?> createRecurringEvent(EventCreationRequest request, String userId) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Validate request
      final validationError = request.validate();
      if (validationError != null) {
        state = state.copyWith(isLoading: false, error: validationError);
        return null;
      }
      
      // Convert request to recurrence pattern
      final recurrencePattern = _createRecurrencePattern(request);
      
      // Create event based on whether it's a club event
      final RecurringEvent event;
      if (request.isClubEvent && request.clubId != null) {
        event = RecurringEvent.createClubRecurringEvent(
          title: request.title,
          description: request.description,
          location: request.location,
          startDate: request.startDate,
          endDate: request.endDate,
          clubId: request.clubId!,
          clubName: request.organizerName,
          creatorId: userId,
          category: request.category,
          organizerEmail: request.organizerEmail,
          visibility: request.visibility,
          tags: request.tags,
          imageUrl: request.imageUrl,
          recurrencePattern: recurrencePattern,
        );
      } else {
        event = RecurringEvent.createUserRecurringEvent(
          title: request.title,
          description: request.description,
          location: request.location,
          startDate: request.startDate,
          endDate: request.endDate,
          userId: userId,
          organizerName: request.organizerName,
          category: request.category,
          organizerEmail: request.organizerEmail,
          visibility: request.visibility,
          tags: request.tags,
          imageUrl: request.imageUrl,
          recurrencePattern: recurrencePattern,
        );
      }
      
      // Save the event
      final savedEvent = await _repository.createRecurringEvent(event);
      
      if (savedEvent != null) {
        // Update state with the new event
        state = state.copyWith(
          isLoading: false,
          currentEvent: savedEvent,
        );
        
        // Load instances
        await loadEventInstances(savedEvent.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create recurring event',
        );
      }
      
      return savedEvent;
    } catch (e) {
      debugPrint('Error creating recurring event: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error creating recurring event: $e',
      );
      return null;
    }
  }
  
  /// Load a recurring event by ID
  Future<RecurringEvent?> loadEvent(String eventId) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Load the event
      final event = await _repository.getRecurringEventById(eventId);
      
      if (event != null) {
        // Update state with the loaded event
        state = state.copyWith(
          isLoading: false,
          currentEvent: event,
        );
        
        // Load instances if this is a master event
        if (event.isMasterEvent) {
          await loadEventInstances(eventId);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Event not found',
        );
      }
      
      return event;
    } catch (e) {
      debugPrint('Error loading recurring event: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading recurring event: $e',
      );
      return null;
    }
  }
  
  /// Load instances of a recurring event
  Future<List<RecurringEvent>> loadEventInstances(String parentEventId) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Load instances
      final instances = await _repository.getRecurringEventInstances(parentEventId);
      
      // Update state with instances
      state = state.copyWith(
        isLoading: false,
        instances: instances,
      );
      
      return instances;
    } catch (e) {
      debugPrint('Error loading recurring event instances: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading recurring event instances: $e',
      );
      return [];
    }
  }
  
  /// Update a recurring event
  Future<bool> updateRecurringEvent(
    RecurringEvent event, {
    bool updateAllInstances = false,
  }) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Update the event
      final success = await _repository.updateRecurringEvent(
        event, 
        updateAllInstances: updateAllInstances,
      );
      
      if (success) {
        // Update state with the updated event
        state = state.copyWith(
          isLoading: false,
          currentEvent: event,
        );
        
        // Reload instances if this is a master event and we're updating all instances
        if (event.isMasterEvent && updateAllInstances) {
          await loadEventInstances(event.id);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update recurring event',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error updating recurring event: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating recurring event: $e',
      );
      return false;
    }
  }
  
  /// Update a specific event instance
  Future<bool> updateEventInstance(RecurringEvent instance) async {
    try {
      // Ensure this is an instance
      if (instance.parentEventId == null) {
        throw Exception('Cannot update instance: not an instance of a recurring event');
      }
      
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Update the instance
      final success = await _repository.updateEventInstance(instance);
      
      if (success) {
        // Update state with the updated instance in the instances list
        final updatedInstances = [...state.instances];
        final index = updatedInstances.indexWhere((e) => e.id == instance.id);
        if (index >= 0) {
          updatedInstances[index] = instance;
        } else {
          updatedInstances.add(instance);
        }
        
        state = state.copyWith(
          isLoading: false,
          instances: updatedInstances,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update event instance',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error updating event instance: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating event instance: $e',
      );
      return false;
    }
  }
  
  /// Cancel a specific event instance
  Future<bool> cancelEventInstance(String instanceId, String parentEventId) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Cancel the instance
      final success = await _repository.cancelEventInstance(instanceId, parentEventId);
      
      if (success) {
        // Update the instance in the state to show as cancelled
        final updatedInstances = [...state.instances];
        final index = updatedInstances.indexWhere((e) => e.id == instanceId);
        if (index >= 0) {
          updatedInstances[index] = updatedInstances[index].copyWith(
            status: 'cancelled',
            isModifiedInstance: true,
          );
        }
        
        state = state.copyWith(
          isLoading: false,
          instances: updatedInstances,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to cancel event instance',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error cancelling event instance: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error cancelling event instance: $e',
      );
      return false;
    }
  }
  
  /// Cancel a recurring event (and optionally all its instances)
  Future<bool> cancelRecurringEvent(String eventId, {DateTime? afterDate}) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Cancel the event
      final success = await _repository.cancelRecurringEvent(eventId, afterDate: afterDate);
      
      if (success) {
        // Update the current event to show as cancelled
        if (state.currentEvent?.id == eventId) {
          state = state.copyWith(
            isLoading: false,
            currentEvent: state.currentEvent!.copyWith(
              status: 'cancelled',
            ),
          );
        } else {
          state = state.copyWith(
            isLoading: false,
          );
        }
        
        // Reload instances to reflect cancellation
        if (state.instances.isNotEmpty) {
          await loadEventInstances(eventId);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to cancel recurring event',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error cancelling recurring event: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error cancelling recurring event: $e',
      );
      return false;
    }
  }
  
  /// Generate new instances of a recurring event
  Future<List<RecurringEvent>> generateNewInstances(String eventId, {int count = 5}) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Generate new instances
      final newInstances = await _repository.generateNewInstances(eventId, count: count);
      
      if (newInstances.isNotEmpty) {
        // Update state with the new instances
        final allInstances = [...state.instances, ...newInstances];
        
        // Sort by start date
        allInstances.sort((a, b) => a.startDate.compareTo(b.startDate));
        
        state = state.copyWith(
          isLoading: false,
          instances: allInstances,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No new instances generated',
        );
      }
      
      return newInstances;
    } catch (e) {
      debugPrint('Error generating new instances: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error generating new instances: $e',
      );
      return [];
    }
  }
  
  /// Save RSVP status for a specific instance
  Future<bool> saveRsvpStatusForInstance(
    String instanceId, 
    String parentEventId, 
    String userId, 
    bool isAttending,
  ) async {
    try {
      // Update state to loading
      state = state.copyWith(isLoading: true, error: null);
      
      // Save RSVP status
      final success = await _repository.saveRsvpStatusForInstance(
        instanceId, 
        parentEventId, 
        userId, 
        isAttending,
      );
      
      if (success) {
        // Update the instance in the state with the updated attendees list
        final updatedInstances = [...state.instances];
        final index = updatedInstances.indexWhere((e) => e.id == instanceId);
        if (index >= 0) {
          final currentAttendees = [...updatedInstances[index].attendees];
          if (isAttending && !currentAttendees.contains(userId)) {
            currentAttendees.add(userId);
          } else if (!isAttending) {
            currentAttendees.removeWhere((id) => id == userId);
          }
          
          updatedInstances[index] = updatedInstances[index].copyWith(
            attendees: currentAttendees,
          );
          
          state = state.copyWith(
            isLoading: false,
            instances: updatedInstances,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save RSVP status',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error saving RSVP status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error saving RSVP status: $e',
      );
      return false;
    }
  }
  
  /// Clear any error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Reset state
  void reset() {
    state = RecurringEventState.initial();
  }
  
  /// Helper method to create a RecurrencePattern from an EventCreationRequest
  RecurrencePattern _createRecurrencePattern(EventCreationRequest request) {
    // Ensure this is a recurring event
    if (!request.isRecurring || request.recurrenceFrequency == null) {
      throw Exception('Cannot create recurrence pattern: not a recurring event');
    }
    
    // Parse frequency
    RecurrenceFrequency frequency;
    switch (request.recurrenceFrequency!.toLowerCase()) {
      case 'daily':
        frequency = RecurrenceFrequency.daily;
        break;
      case 'weekly':
        frequency = RecurrenceFrequency.weekly;
        break;
      case 'monthly':
        frequency = RecurrenceFrequency.monthly;
        break;
      case 'yearly':
        frequency = RecurrenceFrequency.yearly;
        break;
      default:
        throw Exception('Invalid recurrence frequency: ${request.recurrenceFrequency}');
    }
    
    // Parse days of week for weekly recurrence
    List<RecurrenceDay>? daysOfWeek;
    if (request.daysOfWeek != null && request.daysOfWeek!.isNotEmpty) {
      daysOfWeek = request.daysOfWeek!.map((day) {
        // Convert from 0-6 (Sunday-Saturday) to RecurrenceDay enum
        switch (day) {
          case 0:
            return RecurrenceDay.sunday;
          case 1:
            return RecurrenceDay.monday;
          case 2:
            return RecurrenceDay.tuesday;
          case 3:
            return RecurrenceDay.wednesday;
          case 4:
            return RecurrenceDay.thursday;
          case 5:
            return RecurrenceDay.friday;
          case 6:
            return RecurrenceDay.saturday;
          default:
            throw Exception('Invalid day of week: $day');
        }
      }).toList();
    } else if (frequency == RecurrenceFrequency.weekly) {
      // Default to the day of week of the start date
      final dayOfWeek = request.startDate.weekday; // 1-7 (Monday-Sunday)
      daysOfWeek = [RecurrenceDay.values[dayOfWeek - 1]];
    }
    
    return RecurrencePattern(
      frequency: frequency,
      interval: request.recurrenceInterval ?? 1,
      endDate: request.recurrenceEndDate,
      maxOccurrences: request.maxOccurrences,
      daysOfWeek: daysOfWeek,
      dayOfMonth: request.dayOfMonth,
      weekOfMonth: request.weekOfMonth,
      monthOfYear: request.monthOfYear,
      byDayOfWeek: request.byDayOfWeek ?? false,
    );
  }
}

/// Provider for the RecurringEventController
final recurringEventControllerProvider = StateNotifierProvider<RecurringEventController, RecurringEventState>((ref) {
  final repository = ref.watch(recurringEventRepositoryProvider);
  return RecurringEventController(repository: repository);
});

/// Provider for the current recurring event
final currentRecurringEventProvider = Provider<RecurringEvent?>((ref) {
  return ref.watch(recurringEventControllerProvider).currentEvent;
});

/// Provider for recurring event instances
final recurringEventInstancesProvider = Provider<List<RecurringEvent>>((ref) {
  return ref.watch(recurringEventControllerProvider).instances;
});

/// Provider to check if a recurring event operation is in progress
final recurringEventLoadingProvider = Provider<bool>((ref) {
  return ref.watch(recurringEventControllerProvider).isLoading;
});

/// Provider for recurring event error message
final recurringEventErrorProvider = Provider<String?>((ref) {
  return ref.watch(recurringEventControllerProvider).error;
}); 