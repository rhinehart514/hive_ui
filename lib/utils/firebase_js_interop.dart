import 'package:flutter/foundation.dart';

/// This file previously provided mock implementations for JavaScript interoperability
/// It's now simplified as we use real Firebase on all platforms
///
/// Keeping minimal stubs for backward compatibility

/// Mock Promise implementation - simplified for backward compatibility
class PromiseJsImpl<T> {
  final Future<T> _future;

  PromiseJsImpl(this._future);

  Future<T> get future => _future;

  static PromiseJsImpl<T> resolve<T>(T value) {
    return PromiseJsImpl<T>(Future.value(value));
  }

  static PromiseJsImpl<T> reject<T>(Object error) {
    return PromiseJsImpl<T>(Future.error(error));
  }
}

// Log that this file is deprecated
void _logDeprecation() {
  debugPrint(
      'Warning: firebase_js_interop.dart is deprecated and will be removed in a future version.');
  debugPrint('The app now uses real Firebase implementation on all platforms.');
}

// Call the log function when the file is imported
// ignore: unused_element
final bool _initialized = (() {
  _logDeprecation();
  return true;
})();
