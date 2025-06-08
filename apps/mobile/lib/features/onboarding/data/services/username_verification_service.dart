import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for checking username availability and validating format.
class UsernameVerificationService {
  /// Checks if the username is available (not taken by another user).
  ///
  /// Returns a Future<bool> that completes with true if the username is available,
  /// false otherwise.
  Future<bool> checkUsernameAvailability(String username) async {
    // In a real implementation, this would make an API call to check 
    // if the username is already taken in the database.
    // For now, we'll simulate a network request with some delay
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // List of usernames that are considered "taken" for testing
    final takenUsernames = [
      'admin', 'test', 'user', 'hive', 'moderator', 
      'support', 'system', 'root', 'guest'
    ];
    
    final isAvailable = !takenUsernames.contains(username.toLowerCase());
    debugPrint('UsernameVerificationService: Username "$username" is ${isAvailable ? "available" : "taken"}');
    
    return isAvailable;
  }
  
  /// Validates username format.
  ///
  /// Returns a validation error message if the username format is invalid,
  /// null if the format is valid.
  String? validateUsernameFormat(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    
    // Minimum length check
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    // Maximum length check
    if (username.length > 20) {
      return 'Username cannot exceed 20 characters';
    }
    
    // Format check - only allow letters, numbers, and underscores
    // No spaces or special characters
    final RegExp validFormat = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validFormat.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    // Must start with a letter
    final RegExp startsWithLetter = RegExp(r'^[a-zA-Z]');
    if (!startsWithLetter.hasMatch(username)) {
      return 'Username must start with a letter';
    }
    
    return null; // Username format is valid
  }
}

/// Provider for the UsernameVerificationService
final usernameVerificationServiceProvider = Provider<UsernameVerificationService>((ref) {
  return UsernameVerificationService();
}); 