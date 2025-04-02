import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/firebase/firebase_core_service.dart';
import 'package:uuid/uuid.dart';

/// Manager for FCM tokens that handles saving them to Firestore
class FCMTokenManager {
  static FCMTokenManager? _instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _currentToken;
  String? _tokenId;
  bool _isListening = false;

  FCMTokenManager._();

  static FCMTokenManager get instance {
    _instance ??= FCMTokenManager._();
    return _instance!;
  }

  /// Initialize the token manager and set up token listeners
  Future<void> initialize() async {
    if (_isListening) return;

    try {
      // Set up listener for token refresh
      _messaging.onTokenRefresh.listen(_updateToken);
      
      // Get the current token
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateToken(token);
      }
      
      _isListening = true;
      debugPrint('FCM Token Manager initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM Token Manager: $e');
    }
  }

  /// Update the FCM token in Firestore
  Future<void> _updateToken(String token) async {
    try {
      _currentToken = token;
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Cannot save FCM token - no user logged in');
        return;
      }

      // Generate a token ID if we don't have one
      _tokenId ??= const Uuid().v4();
      
      // Save the token to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': {
          _tokenId: token,
        },
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Clear the FCM token from Firestore when user logs out
  Future<void> clearToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _tokenId == null) return;

      // Remove the token from Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens.${_tokenId}': FieldValue.delete(),
      });
      
      debugPrint('FCM token removed from Firestore');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }
  
  /// Get the current FCM token
  String? get currentToken => _currentToken;
}

/// Provider for the FCM token manager
final fcmTokenManagerProvider = Provider<FCMTokenManager>((ref) {
  return FCMTokenManager.instance;
}); 