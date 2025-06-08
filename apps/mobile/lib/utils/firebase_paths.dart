/// Class containing Firestore collection path constants
class FirebasePaths {
  /// Path to the users collection
  static const String users = 'users';
  
  /// Path to the events collection
  static const String events = 'events';
  
  /// Path to the spaces collection
  static const String spaces = 'spaces';
  
  /// Path to the clubs collection
  static const String clubs = 'clubs';
  
  /// Path to the recurring events collection
  static const String recurringEvents = 'recurring_events';
  
  /// Path to the sessions collection
  static const String sessions = 'sessions';
  
  /// Path to the posts collection
  static const String posts = 'posts';
  
  /// Path to the feed collection
  static const String feed = 'feed';
  
  /// Path to the notifications collection
  static const String notifications = 'notifications';
  
  /// Path to the messages collection
  static const String messages = 'messages';
  
  /// Path to the chats collection
  static const String chats = 'chats';
  
  /// Get event ID from a document reference path
  static String getEventIdFromPath(String path) {
    final pathComponents = path.split('/');
    for (int i = 0; i < pathComponents.length - 1; i++) {
      if (pathComponents[i] == 'events') {
        return pathComponents[i + 1];
      }
    }
    return '';
  }
  
  /// Get space ID from a document reference path
  static String getSpaceIdFromPath(String path) {
    final pathComponents = path.split('/');
    for (int i = 0; i < pathComponents.length - 1; i++) {
      if (pathComponents[i] == 'spaces') {
        return pathComponents[i + 1];
      }
    }
    return '';
  }
} 