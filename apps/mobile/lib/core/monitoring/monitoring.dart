import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/application/services/error_logger.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// A service that manages application monitoring including error tracking
/// and performance monitoring.
class MonitoringService {
  final ErrorLogger _errorLogger;
  final FirebasePerformance _performance;
  final bool _isEnabled;

  /// Creates a new MonitoringService
  /// 
  /// The [isEnabled] flag allows disabling monitoring in development
  MonitoringService(this._errorLogger, this._performance, {bool isEnabled = true})
      : _isEnabled = isEnabled && !kDebugMode;

  /// Initialize external error monitoring (e.g., Sentry)
  /// 
  /// Should be called before runApp()
  static Future<void> initializeErrorMonitoring({
    required String dsn,
    String environment = 'production',
  }) async {
    // Integration with Sentry or other error monitoring system would go here
    // For now, this is a placeholder
    if (kDebugMode) {
      print('Error monitoring initialized with DSN: $dsn, environment: $environment');
    }
  }

  /// Create a performance trace for measuring a specific operation
  /// 
  /// Returns a [Trace] that should be started and stopped manually.
  Trace? createTrace(String name) {
    if (!_isEnabled) return null;
    return _performance.newTrace(name);
  }

  /// Start a performance trace with the given name
  /// 
  /// Returns a [Trace] that should be stopped using [stopTrace]
  Future<Trace?> startTrace(String name) async {
    if (!_isEnabled) return null;
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Stop the given trace and record metrics
  Future<void> stopTrace(Trace? trace) async {
    if (trace == null || !_isEnabled) return;
    await trace.stop();
  }

  /// Add a custom attribute to a trace
  void putTraceAttribute(Trace? trace, String name, String value) {
    if (trace == null || !_isEnabled) return;
    trace.putAttribute(name, value);
  }

  /// Create and start a performance metric for HTTP network requests
  /// 
  /// Returns a [HttpMetric] that should be stopped using [stopHttpMetric]
  Future<HttpMetric?> startHttpMetric(
    String url,
    HttpMethod method,
  ) async {
    if (!_isEnabled) return null;
    final metric = _performance.newHttpMetric(url, method);
    await metric.start();
    return metric;
  }

  /// Stop the given HTTP metric and record it
  Future<void> stopHttpMetric(HttpMetric? metric, {int? responseCode, int? requestPayloadSize, int? responsePayloadSize}) async {
    if (metric == null || !_isEnabled) return;
    
    if (responseCode != null) {
      metric.httpResponseCode = responseCode;
    }
    
    if (requestPayloadSize != null) {
      metric.requestPayloadSize = requestPayloadSize;
    }
    
    if (responsePayloadSize != null) {
      metric.responsePayloadSize = responsePayloadSize;
    }
    
    await metric.stop();
  }

  /// Log an error to ErrorLogger and external monitoring services
  Future<void> logError(dynamic error, StackTrace stackTrace, {String? reason}) async {
    if (!_isEnabled) return;
    
    // Log to Firebase Crashlytics via ErrorLogger
    _errorLogger.reportError(error, stackTrace, reason: reason);
    
    // External error tracking would go here (e.g., Sentry)
  }

  /// Log a domain failure to ErrorLogger and external monitoring services
  Future<void> logFailure(Failure failure) async {
    if (!_isEnabled) return;
    
    // Log to Firebase Crashlytics via ErrorLogger
    _errorLogger.reportFailure(failure);
    
    // External error tracking would go here (e.g., Sentry)
  }

  /// Set the current user context for error reporting
  void setUserContext(String userId, {String? email, String? username}) {
    if (!_isEnabled) return;
    
    // Set in ErrorLogger (Crashlytics)
    _errorLogger.setUserId(userId);
    
    // External user context tracking would go here (e.g., Sentry)
  }

  /// Track a custom event for monitoring
  void trackEvent(String name, {Map<String, dynamic>? parameters}) {
    if (!_isEnabled) return;
    
    // This could be integrated with various monitoring systems
    if (kDebugMode) {
      print('Tracking event: $name, parameters: $parameters');
    }
  }
} 