/// Central place for application-wide feature flags.
/// Helps in enabling/disabling features during development and rollout.

class FeatureFlags {
  /// Controls the visibility and behavior of the V1 feed loading improvements.
  /// Includes: HexagonalRippleLoader, updated empty state, caching, pull-to-refresh.
  static const bool feedLoadingV1 = true; // Default to true for development, gate in release/remote config
} 