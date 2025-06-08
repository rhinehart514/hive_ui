import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/repositories/analytics_repository_interface.dart';
import '../providers/repository_providers.dart';

/// Use case for tracking analytics events in the system
class TrackEventUseCase {
  final AnalyticsRepositoryInterface _repository;

  /// Constructor
  TrackEventUseCase(this._repository);

  /// Execute the use case to track an analytics event
  /// 
  /// [eventType] Type of event being tracked
  /// [properties] Additional properties/data for the event
  /// [userId] Optional user ID, or uses current user if not specified
  Future<void> execute({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  }) {
    return _repository.trackEvent(
      eventType: eventType,
      properties: properties,
      userId: userId,
    );
  }
}

/// Provider for the TrackEventUseCase
final trackEventUseCaseProvider = Provider<TrackEventUseCase>((ref) {
  final repository = ref.watch(analyticsRepositoryInterfaceProvider);
  return TrackEventUseCase(repository);
}); 