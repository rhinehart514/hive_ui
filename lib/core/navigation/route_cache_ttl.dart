import 'package:flutter/foundation.dart';

/// Constants for route cache time-to-live (TTL) durations.
/// 
/// These values define how long different types of routes should remain in cache
/// before being considered stale and requiring a refresh.
@immutable
class RouteCacheTTL {
  /// TTL for feed routes (3 minutes)
  /// Feed content updates frequently, so we use a shorter TTL
  static const Duration feedRoute = Duration(minutes: 3);

  /// TTL for profile routes (10 minutes)
  /// Profile data changes infrequently during a session
  static const Duration profileRoute = Duration(minutes: 10);

  /// TTL for event routes (5 minutes)
  /// Event details may be updated occasionally
  static const Duration eventRoute = Duration(minutes: 5);
  
  /// TTL for space routes (8 minutes)
  /// Space content is relatively stable
  static const Duration spaceRoute = Duration(minutes: 8);
  
  /// TTL for organization routes (8 minutes)
  /// Organization information changes infrequently
  static const Duration organizationRoute = Duration(minutes: 8);
  
  /// TTL for settings routes (15 minutes)
  /// Settings rarely change during a session
  static const Duration settingsRoute = Duration(minutes: 15);
  
  /// Default TTL for routes not categorized elsewhere (5 minutes)
  static const Duration defaultTTL = Duration(minutes: 5);
  
  /// Short TTL for testing or rapidly changing content (1 minute)
  static const Duration shortTTL = Duration(minutes: 1);
  
  /// Zero TTL for routes that should never be cached
  static const Duration noCaching = Duration.zero;
  
  /// Extended TTL for static content (30 minutes)
  static const Duration staticContent = Duration(minutes: 30);
  
  /// Factory constructor to get TTL based on route path pattern
  static Duration forRoute(String routePath) {
    if (routePath.contains('/feed') || routePath.contains('/timeline')) {
      return feedRoute;
    } else if (routePath.contains('/profile')) {
      return profileRoute;
    } else if (routePath.contains('/event')) {
      return eventRoute;
    } else if (routePath.contains('/space')) {
      return spaceRoute;
    } else if (routePath.contains('/org') || routePath.contains('/organization')) {
      return organizationRoute;
    } else if (routePath.contains('/settings')) {
      return settingsRoute;
    } else if (routePath.contains('/static')) {
      return staticContent;
    } else {
      return defaultTTL;
    }
  }
  
  /// Private constructor to prevent instantiation
  const RouteCacheTTL._();
} 