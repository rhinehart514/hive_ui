import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/remote_config_source.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Service that manages application configuration and feature flags.
class ConfigService {
  final ConfigDataSource _configDataSource;

  /// Default domains allowed for registration.
  static const List<String> _defaultAllowedDomains = ['buffalo.edu'];

  /// Default interests for onboarding.
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

  /// Creates a new instance with the given data source.
  ConfigService(this._configDataSource);

  /// Gets the list of allowed email domains for registration.
  /// 
  /// If the remote config fails, returns the default list.
  Future<Result<List<String>, Failure>> getAllowedDomains() async {
    final result = await _configDataSource.getAllowedDomains();
    if (result.isFailure) {
      return const Result.right(_defaultAllowedDomains);
    }
    return result;
  }

  /// Checks if an email domain is allowed for registration.
  Future<Result<bool, Failure>> isEmailDomainAllowed(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return const Result.left(InvalidEmailFailure('Invalid email format'));
    }

    final domainPart = email.split('@').last.toLowerCase();
    final domainsResult = await getAllowedDomains();
    
    if (domainsResult.isFailure) {
      return Result.left(domainsResult.getFailure);
    }
    
    final domains = domainsResult.getSuccess;
    return Result.right(domains.any(
      (domain) => domainPart == domain.toLowerCase(),
    ));
  }

  /// Gets the list of available interests for onboarding.
  /// 
  /// If the remote config fails, returns the default list.
  Future<Result<List<String>, Failure>> getInterestsList() async {
    final result = await _configDataSource.getInterestsList();
    if (result.isFailure) {
      return const Result.right(_defaultInterests);
    }
    return result;
  }

  /// Checks if a specific feature is enabled.
  Future<Result<bool, Failure>> isFeatureEnabled(String featureKey) async {
    return _configDataSource.isFeatureEnabled(featureKey);
  }

  /// Refreshes configuration from remote sources.
  Future<Result<void, Failure>> refreshConfig() async {
    if (_configDataSource is FirebaseRemoteConfigSource) {
      return (_configDataSource).refreshConfig();
    }
    return const Result.right(null);
  }

  /// Validates an email address format.
  Result<bool, Failure> isValidEmailFormat(String email) {
    if (email.isEmpty) {
      return const Result.left(InvalidEmailFailure('Email cannot be empty'));
    }

    // Simple regex for validating email format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return const Result.left(InvalidEmailFailure('Invalid email format'));
    }

    return const Result.right(true);
  }
} 