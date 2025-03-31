/// This file previously provided platform-specific Firebase implementations.
/// It's now simplified as we use real Firebase on all platforms
///
/// Keeping minimal stubs for backward compatibility

/// These were previously used to fix JS dependencies for Windows testing
/// Now they are just stubs for backward compatibility

/// Converts a Dart object to JavaScript.
dynamic jsify(Object? dartObject) {
  return dartObject;
}

/// Converts a JavaScript object to Dart.
dynamic dartify(Object? jsObject) {
  return jsObject;
}

/// Handles a JavaScript Promise and converts it to a Dart Future.
Future<T> handleThenable<T>(Object jsPromise) {
  return Future<T>.value(null as T);
}

/// Mock class for backward compatibility
class FirebaseMock {
  // This is always false now
  static bool get isActive => false;
}
