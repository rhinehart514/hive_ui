import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/data/repositories/recurring_event_repository_impl.dart';
import 'package:hive_ui/features/events/domain/repositories/recurring_event_repository.dart';

/// Provider for the RecurringEventRepository
final recurringEventRepositoryProvider = Provider<RecurringEventRepository>((ref) {
  return RecurringEventRepositoryImpl();
}); 