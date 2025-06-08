import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/stubs/firebase_windows_stubs.dart' as stubs;

/// Provider for the Crashlytics service
final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});

/// Service for handling Crashlytics reporting throughout the app
class CrashlyticsService {
  /// Whether Crashlytics collection is enabled
  bool _isEnabled = !kDebugMode;
  
  /// Whether Crashlytics collection is enabled
  bool get isEnabled => _isEnabled;
  
  /// Initialize Crashlytics service
  Future<void> initialize() async {
    // Skip for Windows platform or debug mode
    if (Platform.isWindows || kDebugMode) {
      _isEnabled = false;
      debugPrint('Skipping Crashlytics initialization');
      return;
    }
    
    try {
      // Enable collection
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(_isEnabled);
      
      // Set up default keys
      FirebaseCrashlytics.instance.setCustomKey('build_mode', kDebugMode ? 'debug' : 'release');
      FirebaseCrashlytics.instance.setCustomKey('platform', Platform.operatingSystem);
      FirebaseCrashlytics.instance.setCustomKey('platform_version', Platform.operatingSystemVersion);
      
      debugPrint('Crashlytics initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Crashlytics: $e');
      _isEnabled = false;
    }
  }
  
  /// Enable or disable Crashlytics collection
  Future<void> setEnabled(bool enabled) async {
    if (Platform.isWindows) {
      debugPrint('Crashlytics is not available on Windows');
      _isEnabled = false;
      return;
    }
    
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      _isEnabled = enabled;
    } catch (e) {
      debugPrint('Error setting Crashlytics enabled state: $e');
    }
  }
  
  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    if (!_isEnabled) return;
    
    try {
      if (Platform.isWindows) {
        stubs.FirebaseCrashlytics.instance.setUserIdentifier(identifier);
      } else {
        await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
      }
    } catch (e) {
      debugPrint('Error setting user identifier: $e');
    }
  }
  
  /// Log an error to Crashlytics
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
    bool fatal = false,
  }) async {
    if (!_isEnabled) return;
    
    try {
      if (Platform.isWindows) {
        stubs.FirebaseCrashlytics.instance.recordError(
          exception,
          stackTrace,
          fatal: fatal,
        );
      } else {
        // Create a non-nullable list from the nullable information
        final List<Object> errorInfo = information?.toList() ?? [];
        
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stackTrace,
          reason: reason,
          information: errorInfo,
          fatal: fatal,
        );
      }
    } catch (e) {
      debugPrint('Error logging to Crashlytics: $e');
    }
  }
  
  /// Record a domain failure to Crashlytics
  Future<void> recordFailure(
    AppFailure failure,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    if (!_isEnabled) return;
    
    try {
      if (Platform.isWindows) {
        stubs.FirebaseCrashlytics.instance.recordError(
          failure,
          stackTrace,
          fatal: fatal,
        );
      } else {
        final List<Object> errorInfo = [];
        errorInfo.add(failure.technicalMessage);
        if (failure.exception != null) {
          errorInfo.add('Original exception: ${failure.exception}');
        }
        
        await FirebaseCrashlytics.instance.recordError(
          failure,
          stackTrace,
          reason: failure.code,
          information: errorInfo,
          fatal: fatal,
        );
        
        // Add custom keys for better filtering
        await FirebaseCrashlytics.instance.setCustomKey('error_code', failure.code);
        await FirebaseCrashlytics.instance.setCustomKey('error_type', failure.runtimeType.toString());
      }
    } catch (e) {
      debugPrint('Error recording domain failure to Crashlytics: $e');
    }
  }
  
  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    if (!_isEnabled) return;
    
    try {
      if (!Platform.isWindows) {
        await FirebaseCrashlytics.instance.log(message);
      }
    } catch (e) {
      debugPrint('Error logging message to Crashlytics: $e');
    }
  }
  
  /// Record a fatal Flutter error
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    if (!_isEnabled) return;
    
    try {
      if (Platform.isWindows) {
        stubs.FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    } catch (e) {
      debugPrint('Error recording Flutter error to Crashlytics: $e');
    }
  }
} 