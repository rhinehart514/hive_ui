import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/data/repositories/event_repository_impl.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';

/// Provider for the EventRepository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl();
}); 