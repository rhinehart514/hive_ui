import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Windows-specific implementation of AuthRepository
/// This provides a local authentication experience on Windows
/// while maintaining API compatibility with Firebase auth
class WindowsAuthRepository implements AuthRepository {
  // Local cache
  AuthUser? _cachedUser;
  final Map<String, String> _userCredentials = {};
  final String _localUsersKey = 'local_windows_users';
  static const Duration _userCacheDuration = Duration(minutes: 5);
  DateTime? _lastUserCheck;
  
  // Stream controller for auth state changes
  final _authStateController = StreamController<AuthUser>.broadcast();
  
  WindowsAuthRepository() {
    _loadLocalUsers();
    debugPrint('Windows Auth Repository initialized for local authentication');
  }
  
  /// Load saved users from local storage
  Future<void> _loadLocalUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_localUsersKey);
      
      if (usersJson != null) {
        final Map<String, dynamic> users = jsonDecode(usersJson);
        users.forEach((email, password) {
          _userCredentials[email] = password;
        });
        
        debugPrint('Loaded ${_userCredentials.length} local user(s)');
      }
    } catch (e) {
      debugPrint('Error loading local users: $e');
    }
  }
  
  /// Save users to local storage
  Future<void> _saveLocalUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = jsonEncode(_userCredentials);
      await prefs.setString(_localUsersKey, usersJson);
    } catch (e) {
      debugPrint('Error saving local users: $e');
    }
  }
  
  /// Generate a hash for password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  @override
  Stream<AuthUser> get authStateChanges => _authStateController.stream;
  
  @override
  AuthUser getCurrentUser() {
    // Check if we have a cached user that's still valid
    final now = DateTime.now();
    if (_cachedUser != null && 
        _lastUserCheck != null &&
        now.difference(_lastUserCheck!) < _userCacheDuration) {
      return _cachedUser!;
    }
    
    // Check if email is stored in preferences
    final email = UserPreferencesService.getUserEmail();
    if (email.isNotEmpty && _userCredentials.containsKey(email)) {
      final userId = const Uuid().v5(Uuid.NAMESPACE_URL, email);
      
      final user = AuthUser(
        id: userId,
        email: email,
        displayName: email.split('@').first,
        isEmailVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastSignInTime: DateTime.now(),
        providers: ['windows.local'],
      );
      
      _cachedUser = user;
      _lastUserCheck = now;
      return user;
    }
    
    return AuthUser.empty();
  }
  
  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    if (!_userCredentials.containsKey(email)) {
      throw 'No account found with this email. Please register first.';
    }
    
    final storedHash = _userCredentials[email]!;
    final inputHash = _hashPassword(password);
    
    if (storedHash != inputHash) {
      throw 'Invalid password. Please try again.';
    }
    
    // Create a user with the provided email
    final userId = const Uuid().v5(Uuid.NAMESPACE_URL, email);
    
    final user = AuthUser(
      id: userId,
      email: email,
      displayName: email.split('@').first,
      isEmailVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      lastSignInTime: DateTime.now(),
      providers: ['windows.local'],
    );
    
    // Save email to preferences
    await UserPreferencesService.saveUserEmail(email);
    
    // Update cache
    _cachedUser = user;
    _lastUserCheck = DateTime.now();
    
    // Notify listeners
    _authStateController.add(user);
    
    return user;
  }
  
  @override
  Future<AuthUser> createUserWithEmailPassword(String email, String password) async {
    if (_userCredentials.containsKey(email)) {
      throw 'An account already exists with this email.';
    }
    
    // Hash and store the password
    final passwordHash = _hashPassword(password);
    _userCredentials[email] = passwordHash;
    
    // Save to local storage
    await _saveLocalUsers();
    
    // Create a user with the provided email
    final userId = const Uuid().v5(Uuid.NAMESPACE_URL, email);
    
    final user = AuthUser(
      id: userId,
      email: email,
      displayName: email.split('@').first,
      isEmailVerified: true,
      createdAt: DateTime.now(),
      lastSignInTime: DateTime.now(),
      providers: ['windows.local'],
    );
    
    // Save email to preferences
    await UserPreferencesService.saveUserEmail(email);
    
    // Update cache
    _cachedUser = user;
    _lastUserCheck = DateTime.now();
    
    // Notify listeners
    _authStateController.add(user);
    
    return user;
  }
  
  @override
  Future<void> signOut() async {
    // Clear user email
    await UserPreferencesService.saveUserEmail('');
    _cachedUser = null;
    _lastUserCheck = null;
    
    // Notify listeners
    _authStateController.add(AuthUser.empty());
  }
  
  @override
  Future<AuthUser> signInWithGoogle() async {
    throw 'Google sign-in is not available on Windows';
  }
  
  @override
  Future<AuthUser> signInWithApple() async {
    throw 'Apple sign-in is not available on Windows';
  }
  
  @override
  Future<AuthUser> signInWithFacebook() async {
    throw 'Facebook sign-in is not available on Windows';
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_userCredentials.containsKey(email)) {
      throw 'No account found with this email.';
    }
    
    // For Windows, just remove the password so they can set a new one
    _userCredentials.remove(email);
    await _saveLocalUsers();
  }
  
  @override
  Future<bool> checkIfUserExists(String email) async {
    return _userCredentials.containsKey(email);
  }
  
  @override
  Future<bool> checkEmailVerified() async {
    // Always return true for Windows
    return true;
  }
  
  @override
  Future<void> sendEmailVerification() async {
    // No-op for Windows
  }
  
  @override
  Future<void> updateEmailVerificationStatus() async {
    // No-op for Windows
  }
  
  @override
  Future<List<String>> getAvailableSignInMethods(String email) async {
    if (_userCredentials.containsKey(email)) {
      return ['password'];
    }
    return [];
  }
  
  @override
  Future<void> linkEmailPassword(String email, String password) async {
    // No-op for Windows as we don't have multiple auth providers
    throw 'Operation not supported on Windows';
  }
  
  // Clean up
  void dispose() {
    _authStateController.close();
  }
} 