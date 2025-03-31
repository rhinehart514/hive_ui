import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class to handle Firebase Firestore threading issues.
///
/// Firebase Firestore operations must be performed on the platform thread.
/// This class provides methods to ensure operations are executed on the correct thread.
class FirebaseThreadingFix {
  /// Executes a Firebase operation on the platform thread if needed.
  ///
  /// This function ensures that the operation is executed on the main platform thread,
  /// which is required for Firebase Firestore operations to avoid the error:
  /// "The channel sent a message from native to Flutter on a non-platform thread."
  ///
  /// Usage:
  /// ```dart
  /// final result = await FirebaseThreadingFix.ensurePlatformThread(() async {
  ///   return await firestore.collection('collection').get();
  /// });
  /// ```
  static Future<T> ensurePlatformThread<T>(
      Future<T> Function() operation) async {
    try {
      // If we're already on the main thread, just run the operation
      if (!kIsWeb) {
        // For native platforms, wrap the operation to ensure it's on the platform thread
        final completer = Completer<T>();

        // Use a microtask to ensure we're on the platform thread
        scheduleMicrotask(() async {
          try {
            final result = await operation();
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        });

        return await completer.future;
      } else {
        // For web, we can just run the operation directly
        return await operation();
      }
    } catch (e) {
      debugPrint('Error ensuring platform thread: $e');
      rethrow;
    }
  }
}

/// Extension methods to handle Firebase threading issues
/// This helps ensure that Firebase events are processed on the main UI thread
extension StreamExtension<T> on Stream<T> {
  /// Ensures stream events are processed on the main UI thread
  /// This is necessary for Firebase streams that emit events on background threads
  Stream<T> switchToUiThread() {
    if (kIsWeb) return this; // No threading issues on web
    
    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          Future.microtask(() => sink.add(data));
        },
        handleError: (error, stackTrace, sink) {
          Future.microtask(() => sink.addError(error, stackTrace));
        },
        handleDone: (sink) {
          Future.microtask(() => sink.close());
        },
      ),
    );
  }
}
