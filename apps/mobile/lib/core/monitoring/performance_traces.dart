import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/monitoring/monitoring.dart';

/// A class that defines trace constants and utility methods for performance monitoring.
class PerformanceTraces {
  // Private constructor to prevent instantiation
  PerformanceTraces._();
  
  // Constants for trace names
  static const String magicLinkDelivery = 'magic_link_delivery';
  static const String appStartup = 'app_startup';
  static const String feedFirstLoad = 'feed_first_load';
  static const String onboardingComplete = 'onboarding_complete';
  static const String authFlow = 'auth_flow_complete';
  
  // Constants for attribute keys
  static const String keyConnectionType = 'connection_type';
  static const String keySource = 'source';
  static const String keyCacheHit = 'cache_hit';
  static const String keySuccess = 'success';
  static const String keyErrorCode = 'error_code';
  static const String keyStepCount = 'step_count';
  
  /// The monitoring service instance used for creating and managing traces
  static late MonitoringService _monitoringService;
  
  /// Initializes the performance traces system with the given monitoring service
  static void initialize(MonitoringService monitoringService) {
    _monitoringService = monitoringService;
  }
  
  /// Starts tracing magic link delivery performance
  /// 
  /// Call this when initiating the magic link sending process.
  /// Returns a trace that should be stopped with [stopMagicLinkDeliveryTrace].
  static Future<Trace?> startMagicLinkDeliveryTrace(String email) async {
    if (kDebugMode) {
      return null; // Don't measure in debug mode
    }
    
    final trace = await _monitoringService.startTrace(magicLinkDelivery);
    trace?.putAttribute('email_domain', email.split('@').last);
    return trace;
  }
  
  /// Stops the magic link delivery trace
  /// 
  /// Call this when the magic link process completes (successfully or with an error).
  /// [success] indicates whether the delivery was successful.
  /// [error] is the error message if delivery failed.
  static Future<void> stopMagicLinkDeliveryTrace(Trace? trace, {
    required bool success,
    String? error,
    int? deliveryTimeMs,
  }) async {
    if (trace == null) return;
    
    trace.putAttribute(keySuccess, success.toString());
    
    if (error != null) {
      trace.putAttribute(keyErrorCode, error);
    }
    
    if (deliveryTimeMs != null) {
      trace.putAttribute('delivery_time_ms', deliveryTimeMs.toString());
    }
    
    await _monitoringService.stopTrace(trace);
  }
  
  /// Starts tracing app startup performance
  /// 
  /// Call this at the very beginning of app initialization.
  /// Returns a trace that should be stopped when the app is fully loaded.
  static Future<Trace?> startAppStartupTrace() async {
    if (kDebugMode) {
      return null; // Don't measure in debug mode
    }
    
    return await _monitoringService.startTrace(appStartup);
  }
  
  /// Starts tracing feed loading performance
  /// 
  /// Call this when initiating feed loading.
  /// [source] can be 'initial', 'pull_refresh', etc.
  /// Returns a trace that should be stopped when the feed is displayed.
  static Future<Trace?> startFeedLoadTrace(String source) async {
    if (kDebugMode) {
      return null; // Don't measure in debug mode
    }
    
    final trace = await _monitoringService.startTrace(feedFirstLoad);
    trace?.putAttribute(keySource, source);
    return trace;
  }
  
  /// Stops the feed load trace
  /// 
  /// Call this when the feed is fully loaded and displayed.
  /// [itemCount] is the number of items loaded.
  /// [cacheHit] indicates whether the feed was loaded from cache.
  static Future<void> stopFeedLoadTrace(Trace? trace, {
    required bool success,
    int? itemCount,
    bool? cacheHit,
    int? renderTimeMs,
  }) async {
    if (trace == null) return;
    
    trace.putAttribute(keySuccess, success.toString());
    
    if (itemCount != null) {
      trace.putAttribute('item_count', itemCount.toString());
    }
    
    if (cacheHit != null) {
      trace.putAttribute(keyCacheHit, cacheHit.toString());
    }
    
    if (renderTimeMs != null) {
      trace.putAttribute('render_time_ms', renderTimeMs.toString());
    }
    
    await _monitoringService.stopTrace(trace);
  }
  
  /// Starts tracing the onboarding flow
  /// 
  /// Call this when the user begins the onboarding process.
  /// Returns a trace that should be stopped when onboarding is complete.
  static Future<Trace?> startOnboardingTrace() async {
    if (kDebugMode) {
      return null; // Don't measure in debug mode
    }
    
    return await _monitoringService.startTrace(onboardingComplete);
  }
  
  /// Stops the onboarding trace
  /// 
  /// Call this when the onboarding process is completed or abandoned.
  /// [completed] indicates whether onboarding was fully completed.
  /// [stepCount] is the number of steps completed.
  static Future<void> stopOnboardingTrace(Trace? trace, {
    required bool completed,
    int? stepCount,
    int? totalTimeMs,
  }) async {
    if (trace == null) return;
    
    trace.putAttribute('completed', completed.toString());
    
    if (stepCount != null) {
      trace.putAttribute(keyStepCount, stepCount.toString());
    }
    
    if (totalTimeMs != null) {
      trace.putAttribute('total_time_ms', totalTimeMs.toString());
    }
    
    await _monitoringService.stopTrace(trace);
  }
  
  /// Starts tracing the entire authentication flow
  /// 
  /// Call this at the beginning of the auth process.
  /// Returns a trace that should be stopped when auth is complete.
  static Future<Trace?> startAuthFlowTrace() async {
    if (kDebugMode) {
      return null; // Don't measure in debug mode
    }
    
    return await _monitoringService.startTrace(authFlow);
  }
  
  /// Stops the auth flow trace
  /// 
  /// Call this when authentication is completed (success or failure).
  /// [success] indicates whether authentication was successful.
  /// [error] is the error message if authentication failed.
  static Future<void> stopAuthFlowTrace(Trace? trace, {
    required bool success,
    String? error,
    int? totalTimeMs,
  }) async {
    if (trace == null) return;
    
    trace.putAttribute(keySuccess, success.toString());
    
    if (error != null) {
      trace.putAttribute(keyErrorCode, error);
    }
    
    if (totalTimeMs != null) {
      trace.putAttribute('total_time_ms', totalTimeMs.toString());
    }
    
    await _monitoringService.stopTrace(trace);
  }
} 