import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enum representing the different user roles in the system
enum UserRole {
  /// Unverified user - limited access
  public,
  
  /// Verified student at a participating university
  verified,
  
  /// Student leader or organizational officer
  verifiedPlus,
  
  /// System moderator
  moderator,
  
  /// System or institutional administrator
  admin
}

/// Extension to parse role from string
extension UserRoleExtension on UserRole {
  /// Convert string to UserRole enum
  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'verified':
        return UserRole.verified;
      case 'verifiedplus':
        return UserRole.verifiedPlus;
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.public;
    }
  }
  
  /// Convert UserRole enum to string
  String toShortString() {
    return toString().split('.').last;
  }
}

/// A service that handles role-based access control checks throughout the app
class RoleChecker {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Cache user roles to avoid excessive Firestore reads
  final Map<String, UserRole> _userRoleCache = {};
  
  /// Constructor
  RoleChecker({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance;
  
  /// Check if the current user has at least the specified role
  Future<bool> hasRole(UserRole minimumRole) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final userRole = await getUserRole(currentUser.uid);
      return _compareRoles(userRole, minimumRole);
    } catch (e) {
      debugPrint('Error checking role: $e');
      return false;
    }
  }
  
  /// Get the role of a user
  Future<UserRole> getUserRole(String userId) async {
    // Check cache first
    if (_userRoleCache.containsKey(userId)) {
      return _userRoleCache[userId]!;
    }
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return UserRole.public;
      
      final role = userDoc.data()?['role'] as String?;
      final userRole = UserRoleExtension.fromString(role);
      
      // Cache the result
      _userRoleCache[userId] = userRole;
      
      return userRole;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return UserRole.public;
    }
  }
  
  /// Check if the user is a space leader
  Future<bool> isSpaceLeader(String userId, String spaceId) async {
    try {
      final doc = await _firestore
          .collection('space_leader_index')
          .doc('${userId}_$spaceId')
          .get();
      
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking space leadership: $e');
      return false;
    }
  }
  
  /// Check if user is a member of a space
  Future<bool> isSpaceMember(String userId, String spaceId) async {
    try {
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) return false;
      
      final List<dynamic> members = spaceDoc.data()?['members'] ?? [];
      return members.contains(userId);
    } catch (e) {
      debugPrint('Error checking space membership: $e');
      return false;
    }
  }
  
  /// Check if a user has permission to edit an event
  Future<bool> canEditEvent(String userId, String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final eventData = eventDoc.data()!;
      final isCreator = eventData['creatorId'] == userId;
      final userRole = await getUserRole(userId);
      
      // Admin can edit any event
      if (userRole == UserRole.admin) return true;
      
      // Get event state
      final state = eventData['state'] as String? ?? 'draft';
      
      switch (state) {
        case 'draft':
          // In draft, creator can edit everything
          return isCreator;
        case 'published':
          // In published, creator can edit non-core details
          return isCreator;
        case 'live':
          // In live state, only admin can edit (checked above)
          return false;
        case 'completed':
        case 'archived':
          // No edits allowed in these states (except by admin, checked above)
          return false;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking event edit permission: $e');
      return false;
    }
  }
  
  /// Check if user can create a space
  Future<bool> canCreateSpace(String userId, String spaceType) async {
    try {
      final userRole = await getUserRole(userId);
      
      // Types that require verified status
      if (spaceType == 'hive_exclusive' || spaceType == 'other') {
        return _compareRoles(userRole, UserRole.verified);
      }
      
      // Types that require admin (pre-seeded spaces)
      return _compareRoles(userRole, UserRole.admin);
    } catch (e) {
      debugPrint('Error checking space creation permission: $e');
      return false;
    }
  }
  
  /// Check if user can use boost functionality
  Future<bool> canUseBoost(String userId) async {
    try {
      final userRole = await getUserRole(userId);
      return _compareRoles(userRole, UserRole.verifiedPlus);
    } catch (e) {
      debugPrint('Error checking boost permission: $e');
      return false;
    }
  }
  
  /// Check if user can use honey mode
  Future<bool> canUseHoneyMode(String userId, String spaceId) async {
    try {
      // Must be verified+ AND a space leader
      final userRole = await getUserRole(userId);
      final isLeader = await isSpaceLeader(userId, spaceId);
      
      return _compareRoles(userRole, UserRole.verifiedPlus) && isLeader;
    } catch (e) {
      debugPrint('Error checking honey mode permission: $e');
      return false;
    }
  }
  
  /// Clear cache for a specific user
  void clearCacheForUser(String userId) {
    _userRoleCache.remove(userId);
  }
  
  /// Clear entire role cache
  void clearCache() {
    _userRoleCache.clear();
  }
  
  /// Compare roles to check if user has sufficient permissions
  bool _compareRoles(UserRole userRole, UserRole minimumRole) {
    final roleValues = {
      UserRole.public: 0,
      UserRole.verified: 1,
      UserRole.verifiedPlus: 2,
      UserRole.moderator: 3,
      UserRole.admin: 4,
    };
    
    return roleValues[userRole]! >= roleValues[minimumRole]!;
  }
} 