import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Abstract interface for configuration data sources.
abstract class ConfigDataSource {
  /// Gets the list of available interests.
  Future<Result<List<String>, Failure>> getInterestsList();

  /// Gets the list of allowed email domains.
  Future<Result<List<String>, Failure>> getAllowedDomains();

  /// Checks if a feature is enabled.
  Future<Result<bool, Failure>> isFeatureEnabled(String featureKey);
}

/// Implementation of [ConfigDataSource] using Firebase Remote Config.
class FirebaseRemoteConfigSource implements ConfigDataSource {
  final FirebaseRemoteConfig _remoteConfig;

  // Remote config keys
  static const String _kInterestsList = 'interests_list';
  static const String _kAllowedDomains = 'allowed_domains';
  static const String _kAuthEnabled = 'auth_v1_enabled';

  // Default values (fallbacks)
  static const List<String> _defaultInterests = [
    'Art',
    'Business',
    'Computer Science',
    'Engineering',
    'Health',
    'Literature',
    'Mathematics',
    'Music',
    'Photography',
    'Physics',
    'Sports',
    'Theatre',
  ];

  static const List<String> _defaultAllowedDomains = ['buffalo.edu'];

  /// Creates a new instance with the given dependencies.
  FirebaseRemoteConfigSource(this._remoteConfig);

  /// Initializes Firebase Remote Config with default values and fetches config.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.setDefaults({
        _kInterestsList: json.encode(_defaultInterests),
        _kAllowedDomains: json.encode(_defaultAllowedDomains),
        _kAuthEnabled: true,
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Log error but don't throw - we'll use default values as fallback
      print('Error initializing RemoteConfig: $e');
    }
  }

  @override
  Future<Result<List<String>, Failure>> getInterestsList() async {
    try {
      final String interestsJson = _remoteConfig.getString(_kInterestsList);
      if (interestsJson.isEmpty) {
        return const Result.right(_defaultInterests);
      }

      final List<dynamic> decodedList = json.decode(interestsJson);
      final List<String> interests = decodedList.map((e) => e.toString()).toList();
      
      return Result.right(interests);
    } catch (e) {
      // On error, return default list
      return const Result.right(_defaultInterests);
    }
  }

  @override
  Future<Result<List<String>, Failure>> getAllowedDomains() async {
    try {
      final String domainsJson = _remoteConfig.getString(_kAllowedDomains);
      if (domainsJson.isEmpty) {
        return const Result.right(_defaultAllowedDomains);
      }

      final List<dynamic> decodedList = json.decode(domainsJson);
      final List<String> domains = decodedList.map((e) => e.toString()).toList();
      
      return Result.right(domains);
    } catch (e) {
      // On error, return default domains
      return const Result.right(_defaultAllowedDomains);
    }
  }

  @override
  Future<Result<bool, Failure>> isFeatureEnabled(String featureKey) async {
    try {
      // For predefined keys, we can use them directly
      if (featureKey == 'auth_v1') {
        return Result.right(_remoteConfig.getBool(_kAuthEnabled));
      }
      
      // For dynamic keys, just check if they exist and are boolean
      return Result.right(_remoteConfig.getBool(featureKey));
    } catch (e) {
      // On error, default to disabled for safety
      return const Result.right(false);
    }
  }

  /// Force a fresh fetch of remote config values.
  Future<Result<void, Failure>> refreshConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to refresh configuration: ${e.toString()}'),
      );
    }
  }
} 