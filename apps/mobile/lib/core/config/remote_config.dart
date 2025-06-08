import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/core/result/result.dart';

/// Keys for Remote Config parameters used in the app
class RemoteConfigKeys {
  /// Whether Auth V1 is enabled
  static const String authV1Enabled = 'auth_v1_enabled';
  
  /// Minimum app version required
  static const String minRequiredVersion = 'min_required_version';
  
  /// Whether to use the new onboarding flow
  static const String newOnboardingEnabled = 'new_onboarding_enabled';
  
  /// Whether to show the verification feature
  static const String verificationEnabled = 'verification_enabled';
  
  /// Maximum attempts for username selection
  static const String maxUsernameAttempts = 'max_username_attempts';
  
  /// Whether to enable analytics
  static const String analyticsEnabled = 'analytics_enabled';
  
  /// Feature flags section
  static const String featureFlagPrefix = 'feature_';
  
  /// Whether to enable dark mode toggling
  static const String darkModeToggleEnabled = '${featureFlagPrefix}dark_mode_toggle';
}

/// A service that handles Firebase Remote Config functionality
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  
  /// Default values for remote config parameters
  static final Map<String, dynamic> _defaults = {
    RemoteConfigKeys.authV1Enabled: false,
    RemoteConfigKeys.minRequiredVersion: '1.0.0',
    RemoteConfigKeys.newOnboardingEnabled: true,
    RemoteConfigKeys.verificationEnabled: true,
    RemoteConfigKeys.maxUsernameAttempts: 3,
    RemoteConfigKeys.analyticsEnabled: !kDebugMode,
    RemoteConfigKeys.darkModeToggleEnabled: false,
  };
  
  /// Creates a new RemoteConfigService with the given FirebaseRemoteConfig instance
  RemoteConfigService(this._remoteConfig);
  
  /// Initializes the Remote Config service
  /// 
  /// Sets default values and configures refresh settings.
  /// Returns a [Result] with void on success or a [Failure] on error.
  Future<Result<void, Failure>> initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults(_defaults);
      
      // Configure settings based on environment
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          // In debug, fetch more frequently to aid testing
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode 
              ? const Duration(minutes: 5) 
              : const Duration(hours: 12),
        ),
      );
      
      // Perform initial fetch
      await _remoteConfig.fetchAndActivate();
      
      return const Result.right(null);
    } catch (e) {
      return Result.left(ServerFailure('Failed to initialize RemoteConfig: ${e.toString()}'));
    }
  }
  
  /// Fetches the latest Remote Config values from the server
  /// 
  /// Returns a [Result] with bool (whether values were activated) on success
  /// or a [Failure] on error.
  Future<Result<bool, Failure>> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      return Result.right(activated);
    } catch (e) {
      return Result.left(ServerFailure('Failed to fetch remote config: ${e.toString()}'));
    }
  }
  
  /// Gets a boolean value from Remote Config
  bool getBool(String key) {
    return _remoteConfig.getBool(key);
  }
  
  /// Gets an integer value from Remote Config
  int getInt(String key) {
    return _remoteConfig.getInt(key);
  }
  
  /// Gets a double value from Remote Config
  double getDouble(String key) {
    return _remoteConfig.getDouble(key);
  }
  
  /// Gets a string value from Remote Config
  String getString(String key) {
    return _remoteConfig.getString(key);
  }
  
  /// Checks if Auth V1 is enabled
  bool get isAuthV1Enabled => getBool(RemoteConfigKeys.authV1Enabled);
  
  /// Gets the minimum required app version
  String get minRequiredVersion => getString(RemoteConfigKeys.minRequiredVersion);
  
  /// Checks if the new onboarding flow is enabled
  bool get isNewOnboardingEnabled => getBool(RemoteConfigKeys.newOnboardingEnabled);
  
  /// Checks if the verification feature is enabled
  bool get isVerificationEnabled => getBool(RemoteConfigKeys.verificationEnabled);
  
  /// Gets the maximum attempts allowed for username selection
  int get maxUsernameAttempts => getInt(RemoteConfigKeys.maxUsernameAttempts);
  
  /// Checks if analytics is enabled
  bool get isAnalyticsEnabled => getBool(RemoteConfigKeys.analyticsEnabled);
  
  /// Checks if a feature flag is enabled
  bool isFeatureEnabled(String featureName) {
    final key = RemoteConfigKeys.featureFlagPrefix + featureName;
    return getBool(key);
  }
} 