import 'dart:async';

/// Simple event bus for the application
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  
  /// The singleton instance of the AppEventBus
  static AppEventBus get instance => _instance;

  /// Stream controller for event bus
  final StreamController _streamController = StreamController.broadcast();

  /// Private constructor for singleton pattern
  AppEventBus._internal();

  /// Get the stream to listen to all events
  Stream get stream => _streamController.stream;

  /// Emit an event to all listeners
  void emit(dynamic event) {
    _streamController.add(event);
  }

  /// Dispose the event bus
  void dispose() {
    _streamController.close();
  }
} 