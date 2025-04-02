import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/data/repositories/event_repository_impl.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/features/events/domain/usecases/get_event_by_id_use_case.dart';
import 'package:hive_ui/features/events/domain/usecases/get_events_use_case.dart';
import 'package:hive_ui/features/events/domain/usecases/save_rsvp_status_use_case.dart';

/// Initialize all event-related providers
void initializeEventsModule(ProviderContainer container) {
  debugPrint('🚀 EVENTS MODULE: Starting initialization...');
  
  // Initialize repositories
  debugPrint('🚀 EVENTS MODULE: Initializing event repository...');
  final repository = container.read(eventRepositoryProvider);
  debugPrint('🚀 EVENTS MODULE: Repository initialized: ${repository.runtimeType}');
  
  // Initialize use cases
  debugPrint('🚀 EVENTS MODULE: Initializing use cases...');
  final getEventsUseCase = container.read(getEventsUseCaseProvider);
  final getEventByIdUseCase = container.read(getEventByIdUseCaseProvider);
  final saveRsvpStatusUseCase = container.read(saveRsvpStatusUseCaseProvider);
  
  debugPrint('🚀 EVENTS MODULE: Use cases initialized:');
  debugPrint('   - GetEventsUseCase: ${getEventsUseCase.runtimeType}');
  debugPrint('   - GetEventByIdUseCase: ${getEventByIdUseCase.runtimeType}');
  debugPrint('   - SaveRsvpStatusUseCase: ${saveRsvpStatusUseCase.runtimeType}');
  
  debugPrint('🚀 EVENTS MODULE: Initialization complete!');
} 