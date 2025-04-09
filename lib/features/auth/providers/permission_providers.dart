import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/providers/role_checker_provider.dart';
import 'package:hive_ui/core/services/role_checker.dart';

/// Provider to check if a user has permission to perform a specific action.
/// Helps implement consistent permission checking throughout the app.
final hasPermissionProvider = FutureProvider.family<bool, PermissionType>(
  (ref, permissionType) async {
    final roleChecker = ref.watch(roleCheckerProvider);
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return false;
    }
    
    final userRole = await roleChecker.getUserRole(userId);
    
    switch (permissionType) {
      case PermissionType.createSpace:
        return userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
      
      case PermissionType.editSpace:
        // This is a simplified check, full implementation would check space leadership
        return userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
      
      case PermissionType.createEvent:
        return userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
      
      case PermissionType.joinSpace:
        return userRole == UserRole.verified || 
               userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
      
      case PermissionType.rsvpEvent:
        return userRole == UserRole.verified || 
               userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
              
      case PermissionType.useBoost:
        return userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
              
      case PermissionType.useHoneyMode:
        // This is a simplified check, full implementation would check space leadership
        return userRole == UserRole.verifiedPlus || 
               userRole == UserRole.moderator || 
               userRole == UserRole.admin;
              
      case PermissionType.moderation:
        return userRole == UserRole.moderator || 
               userRole == UserRole.admin;
              
      case PermissionType.administration:
        return userRole == UserRole.admin;
        
      case PermissionType.viewContent:
        // All users can view content
        return true;
    }
  },
);

/// Provider to check if a user has a specific space-related permission
final hasSpacePermissionProvider = FutureProvider.family<bool, SpacePermissionRequest>(
  (ref, request) async {
    final roleChecker = ref.watch(roleCheckerProvider);
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return false;
    }
    
    final userRole = await roleChecker.getUserRole(userId);
    
    // For admins and moderators, always grant access
    if (userRole == UserRole.admin || userRole == UserRole.moderator) {
      return true;
    }
    
    // Check if user is a leader of this space
    final isSpaceLeader = await roleChecker.isSpaceLeader(userId, request.spaceId);
    
    switch (request.permissionType) {
      case SpacePermissionType.view:
        // Check space visibility (simplified, actual implementation would check space privacy)
        return true;
        
      case SpacePermissionType.join:
        return userRole == UserRole.verified || userRole == UserRole.verifiedPlus;
        
      case SpacePermissionType.edit:
        return isSpaceLeader && userRole == UserRole.verifiedPlus;
        
      case SpacePermissionType.manage:
        return isSpaceLeader && userRole == UserRole.verifiedPlus;
        
      case SpacePermissionType.createEvent:
        return isSpaceLeader && userRole == UserRole.verifiedPlus;
        
      case SpacePermissionType.boost:
        return isSpaceLeader && userRole == UserRole.verifiedPlus;
        
      case SpacePermissionType.honeyMode:
        return isSpaceLeader && userRole == UserRole.verifiedPlus;
    }
  },
);

/// Provider to check if a user has a specific event-related permission
final hasEventPermissionProvider = FutureProvider.family<bool, EventPermissionRequest>(
  (ref, request) async {
    final roleChecker = ref.watch(roleCheckerProvider);
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return false;
    }
    
    // For simplicity - in a full implementation, we would check the event's space
    // and the user's relationship to that space
    final canEdit = await roleChecker.canEditEvent(userId, request.eventId);
    final userRole = await roleChecker.getUserRole(userId);
    
    switch (request.permissionType) {
      case EventPermissionType.view:
        // All users can view events
        return true;
        
      case EventPermissionType.rsvp:
        return userRole == UserRole.verified || 
               userRole == UserRole.verifiedPlus ||
               userRole == UserRole.moderator ||
               userRole == UserRole.admin;
        
      case EventPermissionType.edit:
        return canEdit;
        
      case EventPermissionType.cancel:
        return canEdit;
        
      case EventPermissionType.checkIn:
        return canEdit;
    }
  },
);

/// Types of permissions that can be checked across the app
enum PermissionType {
  createSpace,
  editSpace,
  createEvent,
  joinSpace,
  rsvpEvent,
  useBoost,
  useHoneyMode,
  moderation,
  administration,
  viewContent,
}

/// Types of space-specific permissions
enum SpacePermissionType {
  view,
  join,
  edit,
  manage,
  createEvent,
  boost,
  honeyMode,
}

/// Types of event-specific permissions
enum EventPermissionType {
  view,
  rsvp,
  edit,
  cancel,
  checkIn,
}

/// Request object for space permissions
class SpacePermissionRequest {
  final String spaceId;
  final SpacePermissionType permissionType;
  
  const SpacePermissionRequest({
    required this.spaceId, 
    required this.permissionType
  });
}

/// Request object for event permissions
class EventPermissionRequest {
  final String eventId;
  final EventPermissionType permissionType;
  
  const EventPermissionRequest({
    required this.eventId, 
    required this.permissionType
  });
} 