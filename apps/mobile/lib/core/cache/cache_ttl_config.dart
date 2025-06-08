/// Configuration for Time-To-Live durations of different cache types
/// This centralizes all TTL configurations to make cache policies consistent
class CacheTTLConfig {
  /// Private constructor to prevent instantiation
  CacheTTLConfig._();
  
  // User-related cache durations
  
  /// User profile caching duration - balance between freshness and performance
  static const Duration userProfile = Duration(minutes: 5);
  
  /// User's own profile should be cached for less time since it may be updated frequently
  static const Duration currentUserProfile = Duration(minutes: 2);
  
  /// Friend list can be cached longer since it changes less frequently
  static const Duration userFriends = Duration(minutes: 10);
  
  /// Spaces joined by user - medium cache duration
  static const Duration userSpaces = Duration(minutes: 10);
  
  /// Events saved by user - medium cache duration
  static const Duration userSavedEvents = Duration(minutes: 10);
  
  /// Friend requests - short TTL to ensure user sees updates quickly
  static const Duration friendRequests = Duration(minutes: 2);
  
  // Event-related cache durations
  
  /// Individual event details - can be cached longer 
  static const Duration eventDetails = Duration(minutes: 15);
  
  /// Events feed requires more frequent updates
  static const Duration eventsFeed = Duration(minutes: 5);
  
  /// Events by space - cached for a moderately long time
  static const Duration eventsBySpace = Duration(minutes: 15);
  
  /// RSVP status - short cache to ensure UI is responsive to user actions
  static const Duration rsvpStatus = Duration(minutes: 1);
  
  // Space-related cache durations
  
  /// Individual space details - can be cached for longer periods
  static const Duration spaceDetails = Duration(minutes: 30);
  
  /// Space list - moderate caching since new spaces are added infrequently
  static const Duration spacesList = Duration(minutes: 15);
  
  /// Space members - moderate caching time
  static const Duration spaceMembers = Duration(minutes: 10);
  
  // Content-related cache durations
  
  /// User feed content - requires frequent updates
  static const Duration feedContent = Duration(minutes: 5);
  
  /// Content interactions - minimal caching to show near real-time updates
  static const Duration contentInteractions = Duration(minutes: 1);
  
  // Media-related cache durations
  
  /// Profile images - long cache time since they rarely change
  static const Duration profileImages = Duration(days: 7);
  
  /// Event images - can be cached for long periods
  static const Duration eventImages = Duration(days: 7);
  
  /// Thumbnails can be cached longer than full images
  static const Duration thumbnails = Duration(days: 14);
  
  // Default/fallback durations
  
  /// Default cache duration for items not explicitly categorized
  static const Duration defaultTTL = Duration(minutes: 5);
  
  /// Maximum TTL for any cached data (prevents indefinite caching)
  static const Duration maximumTTL = Duration(days: 30);
  
  /// Minimum TTL to avoid excessive network requests
  static const Duration minimumTTL = Duration(seconds: 30);
} 