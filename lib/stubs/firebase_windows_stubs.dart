// This file provides stub implementations for Firebase plugins on Windows
// Import this file in your main.dart for Windows platform

import 'package:flutter/foundation.dart';

/// Helper class to initialize Firebase stubs for Windows platform
class FirebaseWindowsStubs {
  /// Initialize stub implementations for Firebase on Windows
  static void initialize() {
    if (kDebugMode) {
      print('Firebase stubs initialized for Windows platform');
    }
    
    // Make the mock Firebase instance available globally
    Firebase._instance = FirebaseMock._();
  }

  /// Check if this code is running on Windows
  static bool get isWindowsPlatform => defaultTargetPlatform == TargetPlatform.windows;
}

/// Mock of the Firebase class for Windows platform
class Firebase {
  static Firebase? _instance;
  
  // Private constructor
  Firebase._();
  
  // Factory constructor for accessing the instance
  factory Firebase() {
    return _instance ?? (throw Exception("Firebase not initialized"));
  }
  
  // Static getter to mimic Firebase.instance
  static Firebase get instance {
    if (_instance == null) {
      throw Exception("Firebase not initialized");
    }
    return _instance!;
  }
  
  // Mock of Firebase.apps
  static List<FirebaseAppMock> get apps => [FirebaseAppMock._()];
  
  // Mock of Firebase.initializeApp
  static Future<FirebaseAppMock> initializeApp({Object? options}) async {
    if (kDebugMode) {
      print('Firebase stub: initializeApp called with options: $options');
    }
    _instance = FirebaseMock._();
    return FirebaseAppMock._();
  }
}

/// Mock implementation of FirebaseApp
class FirebaseAppMock {
  FirebaseAppMock._();
  
  String get name => 'stub-app';
  
  Future<void> delete() async {
    if (kDebugMode) {
      print('Firebase stub: app.delete() called');
    }
  }
}

/// Private implementation of the mock Firebase
class FirebaseMock extends Firebase {
  FirebaseMock._() : super._();
}

// Stub implementation for Firebase Core
class FirebaseCoreStub {
  static final FirebaseCoreStub _instance = FirebaseCoreStub._internal();
  
  FirebaseCoreStub._internal();
  
  factory FirebaseCoreStub() {
    return _instance;
  }
  
  Future<void> initializeApp() async {
    if (kDebugMode) {
      print('Firebase Core stub: initializeApp called');
    }
    return Future.value();
  }
}

// Stub implementation for Firebase Auth
class FirebaseAuthStub {
  static final FirebaseAuthStub _instance = FirebaseAuthStub._internal();
  
  FirebaseAuthStub._internal();
  
  factory FirebaseAuthStub() {
    return _instance;
  }
  
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) {
      print('Firebase Auth stub: signInWithEmailAndPassword called with $email');
    }
    // Return mock user data
    return Future.value({
      'uid': 'mock-uid-123',
      'email': email,
      'isAnonymous': false,
    });
  }
  
  Future<void> signOut() async {
    if (kDebugMode) {
      print('Firebase Auth stub: signOut called');
    }
    return Future.value();
  }
  
  Stream<Map<String, dynamic>?> authStateChanges() {
    return Stream.value({
      'uid': 'mock-uid-123',
      'email': 'mock@example.com',
      'isAnonymous': false,
    });
  }
}

// Stub implementation for Firebase Crashlytics
class FirebaseCrashlytics {
  static final FirebaseCrashlytics _instance = FirebaseCrashlytics._internal();
  
  FirebaseCrashlytics._internal();
  
  static FirebaseCrashlytics get instance => _instance;
  
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    if (kDebugMode) {
      print('Firebase Crashlytics stub: setCrashlyticsCollectionEnabled($enabled)');
    }
    return Future.value();
  }
  
  Future<void> setUserIdentifier(String identifier) async {
    if (kDebugMode) {
      print('Firebase Crashlytics stub: setUserIdentifier($identifier)');
    }
    return Future.value();
  }
  
  Future<void> recordError(dynamic exception, StackTrace? stack, {bool fatal = false}) async {
    if (kDebugMode) {
      print('Firebase Crashlytics stub: recordError($exception, fatal: $fatal)');
    }
    return Future.value();
  }
  
  void recordFlutterFatalError(dynamic details) {
    if (kDebugMode) {
      print('Firebase Crashlytics stub: recordFlutterFatalError($details)');
    }
  }
}

// Stub implementation for Cloud Firestore
class FirestoreStub {
  static final FirestoreStub _instance = FirestoreStub._internal();
  
  FirestoreStub._internal();
  
  factory FirestoreStub() {
    return _instance;
  }
  
  dynamic collection(String path) {
    return FirestoreCollectionStub(path);
  }
}

class FirestoreCollectionStub {
  final String path;
  
  FirestoreCollectionStub(this.path);
  
  dynamic doc(String docId) {
    return FirestoreDocumentStub('$path/$docId');
  }
  
  Future<List<Map<String, dynamic>>> get() async {
    if (kDebugMode) {
      print('Firestore stub: get collection $path');
    }
    return Future.value([]);
  }
}

class FirestoreDocumentStub {
  final String path;
  
  FirestoreDocumentStub(this.path);
  
  Future<Map<String, dynamic>> get() async {
    if (kDebugMode) {
      print('Firestore stub: get document $path');
    }
    return Future.value({'id': path.split('/').last, 'exists': false});
  }
  
  Future<void> set(Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('Firestore stub: set document $path with data: $data');
    }
    return Future.value();
  }
  
  Future<void> update(Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('Firestore stub: update document $path with data: $data');
    }
    return Future.value();
  }
  
  Future<void> delete() async {
    if (kDebugMode) {
      print('Firestore stub: delete document $path');
    }
    return Future.value();
  }
}

// Stub implementation for Firebase Remote Config
class FirebaseRemoteConfig {
  static final FirebaseRemoteConfig _instance = FirebaseRemoteConfig._internal();
  
  FirebaseRemoteConfig._internal();
  
  static FirebaseRemoteConfig get instance => _instance;
  
  // Default values for parameters
  final Map<String, dynamic> _defaults = {
    'enable_optimized_caching': true,
    'cache_ttl_minutes': 60,
    'enable_debug_features': false,
    'enable_offline_mode': true,
    'enable_lazy_initialization': true,
  };
  
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: setConfigSettings($settings)');
    }
    return Future.value();
  }
  
  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: setDefaults($defaults)');
    }
    _defaults.addAll(defaults);
    return Future.value();
  }
  
  Future<bool> fetchAndActivate() async {
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: fetchAndActivate()');
    }
    return Future.value(true);
  }
  
  bool getBool(String key) {
    final value = _defaults[key];
    if (value is bool) {
      return value;
    }
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: getBool($key) - defaulting to true');
    }
    return true;
  }
  
  int getInt(String key) {
    final value = _defaults[key];
    if (value is int) {
      return value;
    }
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: getInt($key) - defaulting to 0');
    }
    return 0;
  }
  
  double getDouble(String key) {
    final value = _defaults[key];
    if (value is double) {
      return value;
    }
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: getDouble($key) - defaulting to 0.0');
    }
    return 0.0;
  }
  
  String getString(String key) {
    final value = _defaults[key];
    if (value is String) {
      return value;
    }
    if (kDebugMode) {
      print('Firebase RemoteConfig stub: getString($key) - defaulting to empty string');
    }
    return '';
  }
}

class RemoteConfigSettings {
  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  
  const RemoteConfigSettings({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
  });
  
  @override
  String toString() => 'RemoteConfigSettings(fetchTimeout: $fetchTimeout, minimumFetchInterval: $minimumFetchInterval)';
} 