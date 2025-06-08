import 'package:hive_ui/features/shared/domain/failures/failure.dart';

/// Abstract base class for all analytics-related failures
abstract class AnalyticsFailure extends Failure {
  @override
  String get message;
  
  @override
  String get reason;

  /// Returns true if this failure is recoverable through retry
  bool get isRecoverable;

  /// Returns true if this failure should be reported to error tracking
  bool get shouldReport;

  /// Returns a map of additional error context for logging/reporting
  Map<String, dynamic> get errorContext;

  /// Creates an AnalyticsFailure from a GrowthMetricsFailure
  static AnalyticsFailure fromGrowthMetricsFailure(GrowthMetricsFailure failure) {
    return GrowthMetricsFailure(
      operation: failure.operation,
      originalException: failure.originalException,
      context: failure.context,
    );
  }

  /// Creates an unknown AnalyticsFailure
  static AnalyticsFailure unknown(String error) {
    return GrowthMetricsFailure(
      operation: 'unknown',
      originalException: error,
    );
  }
}

/// Failure that occurs when event tracking fails
class EventTrackingFailure implements AnalyticsFailure {
  /// The event type that failed to track
  final String eventType;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  EventTrackingFailure({
    required this.eventType,
    this.originalException,
  });
  
  @override
  String get message => 'Could not track analytics event. This won\'t affect your experience.';
  
  @override
  String get reason => 'Failed to track event of type $eventType: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  bool get isRecoverable => true; // Event tracking can typically be retried
  
  @override
  bool get shouldReport => true; // We want to monitor failed events
  
  @override
  Map<String, dynamic> get errorContext => {
    'eventType': eventType,
    'error': originalException?.toString(),
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  @override
  String toString() => reason;
}

/// Failure that occurs when user metrics cannot be loaded
class MetricsLoadFailure implements AnalyticsFailure {
  /// The user ID for which metrics failed to load
  final String userId;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  MetricsLoadFailure({
    required this.userId,
    this.originalException,
  });
  
  @override
  String get message => 'Could not load user metrics. Please try again later.';
  
  @override
  String get reason => 'Failed to load metrics for user $userId: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  bool get isRecoverable => true; // Metrics loading can be retried
  
  @override
  bool get shouldReport => true; // Important to track metrics loading failures
  
  @override
  Map<String, dynamic> get errorContext => {
    'userId': userId,
    'error': originalException?.toString(),
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  @override
  String toString() => reason;
}

/// Failure that occurs when user events cannot be loaded
class EventsLoadFailure implements AnalyticsFailure {
  /// The user ID for which events failed to load
  final String userId;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  EventsLoadFailure({
    required this.userId,
    this.originalException,
  });
  
  @override
  String get message => 'Could not load user activity. Please try again later.';
  
  @override
  String get reason => 'Failed to load events for user $userId: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  bool get isRecoverable => true; // Events loading can be retried
  
  @override
  bool get shouldReport => true; // Important to track events loading failures
  
  @override
  Map<String, dynamic> get errorContext => {
    'userId': userId,
    'error': originalException?.toString(),
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  @override
  String toString() => reason;
}

/// Failure that occurs when user analytics export fails
class ExportFailure implements AnalyticsFailure {
  /// The user ID for which export failed
  final String userId;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Constructor
  ExportFailure({
    required this.userId,
    this.originalException,
  });
  
  @override
  String get message => 'Could not export your data. Please try again later.';
  
  @override
  String get reason => 'Failed to export analytics for user $userId: ${originalException?.toString() ?? "Unknown error"}';
  
  @override
  bool get isRecoverable => true; // Exports can be retried
  
  @override
  bool get shouldReport => true; // Export failures should be monitored
  
  @override
  Map<String, dynamic> get errorContext => {
    'userId': userId,
    'error': originalException?.toString(),
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  @override
  String toString() => reason;
}

/// Failure that occurs when growth metrics operations fail
class GrowthMetricsFailure implements AnalyticsFailure {
  /// Description of the operation that failed
  final String operation;
  
  /// The original exception that caused this failure
  final Object? originalException;
  
  /// Additional context about the failure
  final String? context;
  
  /// Constructor
  GrowthMetricsFailure({
    required this.operation,
    this.originalException,
    this.context,
  });
  
  @override
  String get message => 'Could not process growth metrics data. Please try again later.';
  
  @override
  String get reason => 'Growth metrics $operation failed: ${originalException?.toString() ?? "Unknown error"}${context != null ? ' ($context)' : ''}';
  
  @override
  bool get isRecoverable => true; // Growth metrics operations can be retried
  
  @override
  bool get shouldReport => true; // Growth metrics failures are important to track
  
  @override
  Map<String, dynamic> get errorContext => {
    'operation': operation,
    'error': originalException?.toString(),
    'context': context,
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  @override
  String toString() => reason;
} 