import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Abstract interface for secure storage providers.
abstract class SecureStorage {
  /// Saves a string value securely with the given key.
  Future<Result<void, Failure>> saveString(String key, String value);

  /// Retrieves a string value for the given key, or null if not found.
  Future<Result<String?, Failure>> getString(String key);

  /// Deletes the value associated with the given key.
  Future<Result<void, Failure>> deleteKey(String key);

  /// Deletes all stored values.
  Future<Result<void, Failure>> clearAll();
}

/// Implementation of [SecureStorage] using flutter_secure_storage.
class FlutterSecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _secureStorage;

  // Common keys
  static const String kAuthToken = 'auth_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId = 'user_id';
  static const String kEmail = 'email';
  static const String kMagicLinkToken = 'magic_link_token';

  /// Creates a new instance with the given dependencies.
  FlutterSecureStorageImpl(this._secureStorage);

  @override
  Future<Result<void, Failure>> saveString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to save secure data: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<String?, Failure>> getString(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return Result.right(value);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to read secure data: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deleteKey(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to delete secure data: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to clear secure storage: ${e.toString()}'),
      );
    }
  }

  /// Saves authentication tokens securely.
  Future<Result<void, Failure>> saveAuthTokens({
    required String authToken,
    String? refreshToken,
    required String userId,
  }) async {
    try {
      await _secureStorage.write(key: kAuthToken, value: authToken);
      
      if (refreshToken != null) {
        await _secureStorage.write(key: kRefreshToken, value: refreshToken);
      }
      
      await _secureStorage.write(key: kUserId, value: userId);
      
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to save auth tokens: ${e.toString()}'),
      );
    }
  }

  /// Clears all authentication data on logout.
  Future<Result<void, Failure>> clearAuthData() async {
    try {
      await _secureStorage.delete(key: kAuthToken);
      await _secureStorage.delete(key: kRefreshToken);
      await _secureStorage.delete(key: kUserId);
      await _secureStorage.delete(key: kEmail);
      await _secureStorage.delete(key: kMagicLinkToken);
      
      return const Result.right(null);
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to clear auth data: ${e.toString()}'),
      );
    }
  }

  /// Saves the email being used for magic link authentication.
  Future<Result<void, Failure>> saveMagicLinkEmail(String email) async {
    return saveString(kEmail, email);
  }

  /// Retrieves the email being used for magic link authentication.
  Future<Result<String?, Failure>> getMagicLinkEmail() async {
    return getString(kEmail);
  }

  /// Saves a magic link token.
  Future<Result<void, Failure>> saveMagicLinkToken(String token) async {
    return saveString(kMagicLinkToken, token);
  }

  /// Retrieves a stored magic link token, if any.
  Future<Result<String?, Failure>> getMagicLinkToken() async {
    return getString(kMagicLinkToken);
  }
} 