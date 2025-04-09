import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// A service that handles encryption and secure storage of sensitive user data
class SensitiveDataEncryption {
  // Constants
  static const _keyName = 'encryption_key';
  static const _ivName = 'encryption_iv';

  // Singleton instance
  static SensitiveDataEncryption? _instance;
  
  // Secure storage
  final FlutterSecureStorage _secureStorage;
  
  // Encryption components
  encrypt.Encrypter? _encrypter;
  encrypt.IV? _iv;
  
  // Private constructor
  SensitiveDataEncryption._({FlutterSecureStorage? secureStorage}) 
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  /// Factory that returns the singleton instance
  factory SensitiveDataEncryption() {
    _instance ??= SensitiveDataEncryption._();
    return _instance!;
  }
  
  /// Initialize the encryption service
  /// This should be called during app startup
  Future<void> initialize() async {
    if (_encrypter != null) return; // Already initialized
    
    try {
      // Try to retrieve existing key and IV
      String? storedKey = await _secureStorage.read(key: _keyName);
      String? storedIv = await _secureStorage.read(key: _ivName);
      
      if (storedKey != null && storedIv != null) {
        // Use existing encryption keys
        final key = encrypt.Key.fromBase64(storedKey);
        _iv = encrypt.IV.fromBase64(storedIv);
        _encrypter = encrypt.Encrypter(encrypt.AES(key));
        debugPrint('Encryption initialized with existing keys');
      } else {
        // Generate new encryption keys
        await _generateNewEncryptionKeys();
        debugPrint('Encryption initialized with new keys');
      }
    } catch (e) {
      debugPrint('Error initializing encryption: $e');
      // Fallback to runtime-only keys if secure storage fails
      _generateFallbackKeys();
    }
  }
  
  /// Generate new encryption keys and store them securely
  Future<void> _generateNewEncryptionKeys() async {
    // Generate a secure random key
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    _iv = encrypt.IV(Uint8List.fromList(ivBytes));
    
    // Store the keys
    await _secureStorage.write(key: _keyName, value: key.base64);
    await _secureStorage.write(key: _ivName, value: _iv!.base64);
    
    // Create encrypter
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }
  
  /// Generate fallback keys that only last for the runtime session
  /// This is used if secure storage fails
  void _generateFallbackKeys() {
    debugPrint('Warning: Using fallback encryption (runtime only)');
    final key = encrypt.Key.fromLength(32);
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }
  
  /// Encrypt sensitive data
  String encryptData(String data) {
    _ensureInitialized();
    try {
      return _encrypter!.encrypt(data, iv: _iv).base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      return _fallbackEncryption(data);
    }
  }
  
  /// Decrypt encrypted data
  String decryptData(String encryptedData) {
    _ensureInitialized();
    try {
      return _encrypter!.decrypt64(encryptedData, iv: _iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return _fallbackDecryption(encryptedData);
    }
  }
  
  /// Hash data for non-recoverable storage (like password hashing)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Securely store a value with a given key
  Future<void> secureStore(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: encryptData(value));
    } catch (e) {
      debugPrint('Secure storage write error: $e');
    }
  }
  
  /// Retrieve a securely stored value by key
  Future<String?> secureRetrieve(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue == null) return null;
      return decryptData(encryptedValue);
    } catch (e) {
      debugPrint('Secure storage read error: $e');
      return null;
    }
  }
  
  /// Delete a securely stored value
  Future<void> secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('Secure storage delete error: $e');
    }
  }
  
  /// Delete all securely stored values
  Future<void> secureDeleteAll() async {
    try {
      await _secureStorage.deleteAll();
      // Regenerate keys
      await _generateNewEncryptionKeys();
    } catch (e) {
      debugPrint('Secure storage delete all error: $e');
    }
  }
  
  /// Check if the encryption system is initialized
  void _ensureInitialized() {
    if (_encrypter == null || _iv == null) {
      _generateFallbackKeys();
    }
  }
  
  /// Simple fallback encryption when the main encryption fails
  /// This is not as secure but prevents crashes
  String _fallbackEncryption(String data) {
    // Simple scrambling as a last resort
    final bytes = utf8.encode(data);
    final encoded = base64Encode(bytes);
    return encoded;
  }
  
  /// Simple fallback decryption when the main decryption fails
  String _fallbackDecryption(String data) {
    try {
      final bytes = base64Decode(data);
      return utf8.decode(bytes);
    } catch (_) {
      return data; // Return as-is if all else fails
    }
  }
} 