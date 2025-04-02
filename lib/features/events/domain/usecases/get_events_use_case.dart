import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/models/event.dart';

/// Use case for fetching events
class GetEventsUseCase {
  final EventRepository _repository;

  /// Constructor
  GetEventsUseCase(this._repository);

  /// Execute the use case to fetch events
  Future<Map<String, dynamic>> execute({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return _repository.fetchEvents(
      forceRefresh: forceRefresh,
      page: page,
      pageSize: pageSize,
      startDate: startDate,
      endDate: endDate,
      category: category,
    );
  }
}

/// Provider for the GetEventsUseCase
final getEventsUseCaseProvider = Provider<GetEventsUseCase>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetEventsUseCase(repository);
}); 