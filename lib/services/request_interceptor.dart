import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Interceptor for Firestore requests to reduce redundant reads
/// This service hooks into all Firestore operations to prevent duplicates
class RequestInterceptor {
  // Counter for tracking request statistics
  static int _totalRequests = 0;
  static int _interceptedRequests = 0;
  static int _completedRequests = 0;
  static int _failedRequests = 0;

  // Request tracking
  static final Map<String, Future<dynamic>> _pendingRequests = {};
  static final Map<String, dynamic> _resultCache = {};
  static final Map<String, DateTime> _requestTimes = {};

  // Cache duration for different request types
  static const Duration _listDuration = Duration(minutes: 10);
  static const Duration _documentDuration = Duration(minutes: 20);

  // Tracking enabled flag
  static bool _isTrackingEnabled = false;

  /// Initialize the interceptor
  static void initialize() {
    _isTrackingEnabled = true;
    debugPrint('RequestInterceptor initialized');
  }

  /// Intercept a Firestore get operation
  static Future<DocumentSnapshot<Map<String, dynamic>>> interceptDocumentGet(
      DocumentReference<Map<String, dynamic>> reference,
      [GetOptions? options]) async {
    if (!_isTrackingEnabled) {
      return reference.get(options);
    }

    final requestKey = 'doc:${reference.path}';
    _totalRequests++;

    // Check if we have a fresh cached result
    if (_resultCache.containsKey(requestKey) &&
        _requestTimes.containsKey(requestKey) &&
        DateTime.now().difference(_requestTimes[requestKey]!) <
            _documentDuration &&
        options?.source != Source.server) {
      _interceptedRequests++;
      debugPrint('🔄 Intercepted document request: ${reference.path}');
      return _resultCache[requestKey] as DocumentSnapshot<Map<String, dynamic>>;
    }

    // Check if there's a pending request
    if (_pendingRequests.containsKey(requestKey)) {
      _interceptedRequests++;
      debugPrint('⏳ Reusing pending document request: ${reference.path}');
      return _pendingRequests[requestKey]
          as Future<DocumentSnapshot<Map<String, dynamic>>>;
    }

    // Make the actual request
    final future = reference.get(options);
    _pendingRequests[requestKey] = future;

    try {
      final result = await future;
      _resultCache[requestKey] = result;
      _requestTimes[requestKey] = DateTime.now();
      _completedRequests++;
      return result;
    } catch (e) {
      _failedRequests++;
      rethrow;
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  /// Intercept a Firestore query get operation
  static Future<QuerySnapshot<Map<String, dynamic>>> interceptQueryGet(
      Query<Map<String, dynamic>> query,
      [GetOptions? options]) async {
    if (!_isTrackingEnabled) {
      return query.get(options);
    }

    // Generate a key for this query based on its components
    String queryKey = 'query:${query.toString()}';
    _totalRequests++;

    // Check if we have a fresh cached result
    if (_resultCache.containsKey(queryKey) &&
        _requestTimes.containsKey(queryKey) &&
        DateTime.now().difference(_requestTimes[queryKey]!) < _listDuration &&
        options?.source != Source.server) {
      _interceptedRequests++;
      debugPrint('🔄 Intercepted query request: ${query.toString()}');
      return _resultCache[queryKey] as QuerySnapshot<Map<String, dynamic>>;
    }

    // Check if there's a pending request
    if (_pendingRequests.containsKey(queryKey)) {
      _interceptedRequests++;
      debugPrint('⏳ Reusing pending query request: ${query.toString()}');
      return _pendingRequests[queryKey]
          as Future<QuerySnapshot<Map<String, dynamic>>>;
    }

    // Make the actual request
    final future = query.get(options);
    _pendingRequests[queryKey] = future;

    try {
      final result = await future;
      _resultCache[queryKey] = result;
      _requestTimes[queryKey] = DateTime.now();
      _completedRequests++;
      return result;
    } catch (e) {
      _failedRequests++;
      rethrow;
    } finally {
      _pendingRequests.remove(queryKey);
    }
  }

  /// Clear cached results
  static void clearCache() {
    _resultCache.clear();
    _requestTimes.clear();
    debugPrint('Request interceptor cache cleared');
  }

  /// Get request statistics
  static Map<String, int> getStats() {
    return {
      'totalRequests': _totalRequests,
      'interceptedRequests': _interceptedRequests,
      'completedRequests': _completedRequests,
      'failedRequests': _failedRequests,
      'savedRequests': _interceptedRequests,
      'activeRequests': _pendingRequests.length,
      'cachedResults': _resultCache.length,
    };
  }

  /// Reset statistics
  static void resetStats() {
    _totalRequests = 0;
    _interceptedRequests = 0;
    _completedRequests = 0;
    _failedRequests = 0;
  }
}

/// Extension methods for Firestore to intercept requests
extension DocumentReferenceExtension
    on DocumentReference<Map<String, dynamic>> {
  /// Get a document with interception
  Future<DocumentSnapshot<Map<String, dynamic>>> getWithInterception(
      [GetOptions? options]) {
    return RequestInterceptor.interceptDocumentGet(this, options);
  }

  /// Alias for getWithInterception for semantic clarity
  Future<DocumentSnapshot<Map<String, dynamic>>> interceptedGet(
      [GetOptions? options]) {
    return RequestInterceptor.interceptDocumentGet(this, options);
  }
}

/// Extension methods for Query
extension QueryExtension on Query<Map<String, dynamic>> {
  /// Get query results with interception
  Future<QuerySnapshot<Map<String, dynamic>>> getWithInterception(
      [GetOptions? options]) {
    return RequestInterceptor.interceptQueryGet(this, options);
  }

  /// Alias for getWithInterception for semantic clarity
  Future<QuerySnapshot<Map<String, dynamic>>> interceptedGet(
      [GetOptions? options]) {
    return RequestInterceptor.interceptQueryGet(this, options);
  }
}
