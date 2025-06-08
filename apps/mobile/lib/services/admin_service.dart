import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';

/// Service to handle admin-related operations
class AdminService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Internal cache for admin status
  static bool? _cachedAdminStatus;

  /// Check if the current user has admin privileges
  static Future<bool> isUserAdmin() async {
    try {
      // Return cached result if available
      if (_cachedAdminStatus != null) {
        return _cachedAdminStatus!;
      }

      final user = _auth.currentUser;
      if (user == null) {
        _cachedAdminStatus = false;
        return false;
      }

      // Check if user exists in admin_users collection
      final adminDoc =
          await _firestore.collection('admin_users').doc(user.uid).get();

      _cachedAdminStatus = adminDoc.exists;
      return _cachedAdminStatus!;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Navigate to admin verification panel if user is admin
  static Future<void> navigateToAdminVerificationPanel(
      BuildContext context) async {
    try {
      final isAdmin = await isUserAdmin();
      if (isAdmin && context.mounted) {
        // Only navigate if user is admin
        context.go(AppRoutes.adminVerificationRequests);
      }
    } catch (e) {
      debugPrint('Error navigating to admin panel: $e');
    }
  }

  /// Clear the cached admin status when needed (e.g., after logout)
  static void clearCachedStatus() {
    _cachedAdminStatus = null;
  }
}
