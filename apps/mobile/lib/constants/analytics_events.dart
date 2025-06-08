/// Defines constants for analytics events used throughout the HIVE application.

class AnalyticsEvents {
  // Feed Events
  static const String feedLoadStarted = 'feed_load_started';
  static const String feedLoadSuccess = 'feed_load_success';
  static const String feedLoadFailure = 'feed_load_failure';
  static const String feedCacheHit = 'feed_cache_hit';
  static const String feedCacheMiss = 'feed_cache_miss';
  static const String pullToRefreshStarted = 'pull_to_refresh_started';
  static const String pullToRefreshSuccess = 'pull_to_refresh_success';
  static const String pullToRefreshFailure = 'pull_to_refresh_failure';
  static const String emptyStateCtaTapped = 'empty_state_cta_tapped';
  static const String offlineBannerShown = 'offline_banner_shown';
  static const String offlineBannerRetryTapped = 'offline_banner_retry_tapped';

  // Feed Event Payload Keys
  static const String source = 'source'; // 'cache' or 'server'
  static const String errorType = 'error_type';
  static const String cacheAgeSeconds = 'cache_age_seconds';
  static const String ctaName = 'cta_name';
} 