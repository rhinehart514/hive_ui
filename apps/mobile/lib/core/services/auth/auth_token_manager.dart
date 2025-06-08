import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages authentication tokens and session lifecycle
class AuthTokenManager {
  // Storage keys
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _userIdKey = 'auth_user_id';
  
  // Refresh settings
  static const int _refreshBeforeExpirySeconds = 300; // Refresh 5 minutes before expiry
  static const int _sessionTimeoutMinutes = 120; // 2 hour session timeout
  
  final FlutterSecureStorage _secureStorage;
  final FirebaseAuth _firebaseAuth;
  
  // Timers and controllers
  Timer? _refreshTimer;
  Timer? _sessionTimeoutTimer;
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  
  // Singleton instance
  static final AuthTokenManager _instance = AuthTokenManager._internal(
    const FlutterSecureStorage(),
    FirebaseAuth.instance,
  );
  
  /// Creates an instance of [AuthTokenManager]
  factory AuthTokenManager() => _instance;
  
  /// Internal constructor with dependencies
  AuthTokenManager._internal(this._secureStorage, this._firebaseAuth);
  
  /// Stream that emits events when auth state changes
  Stream<bool> get authStateChanges => _authStateController.stream;
  
  /// Initialize the token manager
  Future<void> initialize() async {
    // Check for existing tokens on startup
    final hasValidToken = await _hasValidToken();
    
    if (hasValidToken) {
      _startRefreshTimer();
      _startSessionTimeoutTimer();
      _authStateController.add(true);
    } else {
      await clearTokens();
      _authStateController.add(false);
    }
    
    // Listen to Firebase Auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user == null) {
        clearTokens();
        _authStateController.add(false);
      } else {
        _refreshIdToken();
        _authStateController.add(true);
      }
    });
  }
  
  /// Saves the auth tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
    required String userId,
  }) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      await _secureStorage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
      await _secureStorage.write(key: _userIdKey, value: userId);
      
      _startRefreshTimer();
      _startSessionTimeoutTimer();
      _authStateController.add(true);
    } catch (e) {
      // Handle secure storage errors
    }
  }
  
  /// Get the current access token
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Get the current refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Get the current user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if we have a valid token
  Future<bool> _hasValidToken() async {
    try {
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      
      if (expiryString == null || accessToken == null) {
        return false;
      }
      
      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();
      
      return expiry.isAfter(now);
    } catch (e) {
      return false;
    }
  }
  
  /// Refresh the Firebase ID token
  Future<void> _refreshIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;
      
      final idTokenResult = await user.getIdTokenResult(true);
      final expirationTime = idTokenResult.expirationTime ?? 
          DateTime.now().add(const Duration(hours: 1));
      
      await saveTokens(
        accessToken: idTokenResult.token!,
        refreshToken: '', // Firebase handles refresh tokens internally
        expiry: expirationTime,
        userId: user.uid,
      );
    } catch (e) {
      // Handle refresh errors
    }
  }
  
  /// Start a timer to refresh the token before it expires
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    
    _secureStorage.read(key: _tokenExpiryKey).then((expiryString) {
      if (expiryString == null) return;
      
      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();
      final refreshTime = expiry.subtract(const Duration(seconds: _refreshBeforeExpirySeconds));
      
      if (refreshTime.isAfter(now)) {
        final delay = refreshTime.difference(now);
        _refreshTimer = Timer(delay, _refreshIdToken);
      } else {
        // Token is already close to expiring or expired
        _refreshIdToken();
      }
    });
  }
  
  /// Start a timer for session timeout (auto-signout after inactivity)
  void _startSessionTimeoutTimer() {
    _sessionTimeoutTimer?.cancel();
    
    const sessionTimeout = Duration(minutes: _sessionTimeoutMinutes);
    _sessionTimeoutTimer = Timer(sessionTimeout, () {
      // Auto sign-out after session timeout
      signOut();
    });
  }
  
  /// Reset the session timeout timer (call this when user is active)
  void resetSessionTimer() {
    _startSessionTimeoutTimer();
  }
  
  /// Sign out and clear tokens
  Future<void> signOut() async {
    await clearTokens();
    await _firebaseAuth.signOut();
    _authStateController.add(false);
  }
  
  /// Clear all stored tokens
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _userIdKey);
      
      _refreshTimer?.cancel();
      _sessionTimeoutTimer?.cancel();
    } catch (e) {
      // Handle secure storage errors
    }
  }
  
  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _sessionTimeoutTimer?.cancel();
    _authStateController.close();
  }
} 