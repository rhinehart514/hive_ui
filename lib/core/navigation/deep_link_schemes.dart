/// Defines all the deep link schemes for the HIVE app
/// 
/// This file serves as a central reference for all URI schemes and patterns
/// used in deep linking throughout the app.
/// 
/// The schemes support both custom URI (`hive://`) and web URL (`https://hiveapp.com/`) formats.

/// Base URL for web links (fallback for platforms that don't support custom schemes)
const String kBaseWebUrl = 'https://hiveapp.com';

/// Custom URI scheme for app-specific deep links
const String kCustomScheme = 'hive';

/// Deep Link Scheme Patterns
class DeepLinkSchemes {
  // Existing deep link schemes
  
  /// Event deep link pattern: hive://events/{id}
  static const String events = 'events/:eventId';
  
  /// Space deep link pattern: hive://spaces/{type}/spaces/{id}
  static const String spaces = 'spaces/:spaceType/spaces/:spaceId';
  
  /// Profile deep link pattern: hive://profiles/{id}
  static const String profiles = 'profiles/:profileId';
  
  // New deep link schemes
  
  /// Chat/messaging deep link pattern: hive://messages/chat/{id}
  static const String messages = 'messages/chat/:chatId';
  
  /// Group chat deep link pattern: hive://messages/group/{id}
  static const String groupMessages = 'messages/group/:groupId';
  
  /// Post deep link pattern: hive://posts/{id}
  static const String posts = 'posts/:postId';
  
  /// Search results deep link pattern: hive://search?q={query}&filter={filter}
  static const String search = 'search';
  
  /// Organization deep link pattern: hive://organizations/{id}
  static const String organizations = 'organizations/:organizationId';

  /// Check-in deep link pattern: hive://events/{id}/check-in/{code}
  static const String eventCheckIn = 'events/:eventId/check-in/:code';
}

/// Deep Link URL Generators
/// 
/// These methods generate properly formatted deep links
class DeepLinkUrlGenerator {
  /// Generate an event deep link
  static String eventLink(String eventId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/events/$eventId';
    } else {
      return '$kCustomScheme://events/$eventId';
    }
  }
  
  /// Generate a space deep link
  static String spaceLink(String spaceType, String spaceId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/spaces/$spaceType/spaces/$spaceId';
    } else {
      return '$kCustomScheme://spaces/$spaceType/spaces/$spaceId';
    }
  }
  
  /// Generate a profile deep link
  static String profileLink(String profileId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/profiles/$profileId';
    } else {
      return '$kCustomScheme://profiles/$profileId';
    }
  }
  
  /// Generate a chat deep link
  static String chatLink(String chatId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/messages/chat/$chatId';
    } else {
      return '$kCustomScheme://messages/chat/$chatId';
    }
  }
  
  /// Generate a group chat deep link
  static String groupChatLink(String groupId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/messages/group/$groupId';
    } else {
      return '$kCustomScheme://messages/group/$groupId';
    }
  }
  
  /// Generate a post deep link
  static String postLink(String postId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/posts/$postId';
    } else {
      return '$kCustomScheme://posts/$postId';
    }
  }
  
  /// Generate a search results deep link
  static String searchLink(String query, {Map<String, String>? filters, bool useWebUrl = true}) {
    final queryParams = <String, String>{'q': query};
    if (filters != null) {
      queryParams.addAll(filters);
    }
    
    final Uri uri;
    if (useWebUrl) {
      uri = Uri.https('hiveapp.com', '/search', queryParams);
      return uri.toString();
    } else {
      uri = Uri(
        scheme: kCustomScheme,
        host: '',
        path: '/search',
        queryParameters: queryParams,
      );
      return uri.toString().replaceFirst('//', '://');
    }
  }
  
  /// Generate an organization deep link
  static String organizationLink(String organizationId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/organizations/$organizationId';
    } else {
      return '$kCustomScheme://organizations/$organizationId';
    }
  }
  
  /// Generate an event check-in deep link
  static String eventCheckInLink(String eventId, String code, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$kBaseWebUrl/events/$eventId/check-in/$code';
    } else {
      return '$kCustomScheme://events/$eventId/check-in/$code';
    }
  }
} 