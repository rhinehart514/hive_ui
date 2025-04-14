/// Standardized error codes for application failures
///
/// These codes provide a consistent way to categorize errors across the application.
/// They are used with AppFailure classes to identify the type of error.
enum AppFailureCode {
  /// Unknown or unspecified error
  unknown,
  
  /// Network-related errors (connectivity, server unreachable)
  network,
  
  /// Server returned an error response
  server,
  
  /// Authentication-related errors (invalid credentials, expired token)
  authentication,
  
  /// Authorization-related errors (insufficient permissions)
  unauthorized,
  
  /// Resource not found
  notFound,
  
  /// Input validation failures
  invalidArgument,
  
  /// Data parsing or format errors
  dataFormat,
  
  /// Operation timeout
  timeout,
  
  /// Operation cancelled
  cancelled,
  
  /// Operation failed (general failure)
  operationFailed,
  
  /// Offline mode - cannot perform online operation
  offline,
  
  /// Conflict with existing data
  conflict,
  
  /// Rate limiting or quota exceeded
  rateLimited,
  
  /// Feature not available or implemented
  unsupported,
  
  /// System or hardware limitations
  resourceExhausted,
  
  /// External service integration error
  externalService,
  
  /// Database operation error
  database,
  
  /// File system operation error
  fileSystem,
  
  /// Configuration error
  configuration,
  
  /// State error (operation cannot be performed in current state)
  invalidState
} 