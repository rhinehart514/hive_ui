import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Utility functions for authentication-related operations
class AuthUtils {
  /// Get the current authenticated user ID or throws an exception if not authenticated
  static String getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to perform this action');
    }
    return user.uid;
  }
  
  /// Get the current authenticated user ID or returns null if not authenticated
  static String? getCurrentUserIdOrNull() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
  
  /// Check if a user is authenticated
  static bool isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }
  
  /// Require authentication, showing a snackbar if not authenticated
  /// Returns true if authenticated, false otherwise
  static bool requireAuth(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need to sign in to perform this action'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'SIGN IN',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to login page
              Navigator.of(context).pushNamed('/login');
            },
          ),
        ),
      );
      return false;
    }
    return true;
  }
} 