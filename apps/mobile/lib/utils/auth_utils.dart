import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

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

  /// Check if user has a profile and show message if not
  /// Returns true if profile exists, false otherwise
  static bool requireProfile(BuildContext context, WidgetRef ref) {
    try {
      final profileState = ref.read(profileProvider);
      debugPrint('Profile check - State: isLoading=${profileState.isLoading}, hasError=${profileState.hasError}, profile=${profileState.profile != null}');
      
      if (profileState.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please wait while we load your profile...'),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 2),
          ),
        );
        return false;
      }
      
      if (profileState.hasError) {
        debugPrint('Profile error: ${profileState.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${profileState.error}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
          ),
        );
        return false;
      }
      
      final profile = profileState.profile;
      if (profile == null) {
        // Try to load the profile if it's not loaded yet
        ref.read(profileProvider.notifier).loadProfile().then((_) {
          // Check profile state again after loading
          final updatedProfile = ref.read(profileProvider).profile;
          // Check if the context is still valid before showing the SnackBar
          if (!context.mounted) return;
          if (updatedProfile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Please complete your profile to perform this action'),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'PROFILE',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate to profile page
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
              ),
            );
          }
        });
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error in requireProfile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking profile: $e'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }
  
  /// Require authentication, showing a snackbar if not authenticated
  /// Returns true if authenticated, false otherwise
  static bool requireAuth(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.read(profileProvider).profile;
    
    if (user == null || profile == null) {
      debugPrint('Auth check failed - Firebase user: ${user != null}, Profile: ${profile != null}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please ensure you are fully logged in to perform this action'),
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