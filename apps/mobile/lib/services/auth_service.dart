import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service for handling user authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get the current user ID if logged in
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Check if a user is currently logged in
  bool get isLoggedIn => _auth.currentUser != null;
  
  /// Get the current Firebase user
  User? get currentUser => _auth.currentUser;
} 