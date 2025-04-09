import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/usecases/get_event_by_id_use_case.dart';
import 'package:hive_ui/features/events/domain/usecases/get_events_use_case.dart';
import 'package:hive_ui/features/events/domain/usecases/save_rsvp_status_use_case.dart';
import 'package:hive_ui/features/events/presentation/routing/event_routes.dart';

/// Routes provider for event module
final eventRoutesProvider = Provider<List<RouteBase>>((ref) {
  return EventRoutes.getRoutes();
});

/// Initialize all event-related providers and routes
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
  
  // Initialize routing
  debugPrint('🚀 EVENTS MODULE: Initializing routing...');
  // Initialize routing directly with EventRoutes
  debugPrint('🚀 EVENTS MODULE: Configuring event routes');
  container.read(eventRoutesProvider);
  debugPrint('🚀 EVENTS MODULE: Routing initialized');
  
  debugPrint('🚀 EVENTS MODULE: Initialization complete!');
} 