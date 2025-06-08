/// Base abstract class for all application failures
/// 
/// This provides a consistent interface for all domain-specific failures in the app.
/// It implements Exception to be compatible with Dart's exception handling mechanisms.
abstract class AppFailure implements Exception {
  /// Short code identifying the failure type (used for logging and analytics)
  final String code;
  
  /// User-friendly message suitable for display in the UI
  final String userMessage;
  
  /// Technical message with more details (for logging, not for UI display)
  final String technicalMessage;
  
  /// Original exception that caused this failure (if applicable)
  final dynamic exception;
  
  /// Whether this is a critical error that should be reported to crash reporting services
  final bool isCritical;
  
  /// Constructor
  const AppFailure({
    required this.code,
    required this.userMessage,
    required this.technicalMessage,
    this.exception,
    this.isCritical = false,
  });
  
  /// String representation (defaults to technical message)
  @override
  String toString() => technicalMessage;
} 