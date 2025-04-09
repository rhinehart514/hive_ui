import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth;
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_members_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as providers;
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that displays and manages members of a space
/// Allows admins to promote/demote other members
class SpaceMemberManagement extends ConsumerWidget {
  /// The ID of the space
  final String spaceId;
  
  /// Constructor
  const SpaceMemberManagement({
    Key? key,
    required this.spaceId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceAsync = ref.watch(providers.spaceProvider(spaceId));
    final membersAsync = ref.watch(spaceMembersProvider(spaceId));
    final operationState = ref.watch(memberOperationStateProvider);
    final operationError = ref.watch(memberOperationErrorProvider);
    final currentUser = ref.watch(auth.currentUserProvider);
    
    return spaceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (err, stack) => Center(
        child: Text('Error loading space: $err', style: const TextStyle(color: Colors.white)),
      ),
      data: (space) {
        if (space == null) {
          return const Center(
            child: Text('Space not found', style: TextStyle(color: Colors.white)),
          );
        }
        
        final isCurrentUserAdmin = space.admins.contains(currentUser.id);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Space Members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Members: ${membersAsync.asData?.value.length ?? 0}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  if (isCurrentUserAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'As an admin, you can manage member roles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Error message if any
            if (operationError != null && operationState == MemberOperationState.error)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Text(
                  operationError,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            
            // Success message
            if (operationState == MemberOperationState.success)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Text(
                  'Member role updated successfully',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            
            // Members list
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  
                  // Convert UserProfile list to SpaceMemberEntity list
                  final memberEntities = members.map((member) => SpaceMemberEntity(
                    id: member.id,
                    userId: member.id,
                    role: space.admins.contains(member.id) ? 'admin' : 'member',
                    displayName: member.displayName,
                    joinedAt: DateTime.now(), // Use appropriate date if available
                  )).toList();
                  
                  // Sort members: admins first, then regular members
                  final sortedMembers = [...memberEntities];
                  sortedMembers.sort((a, b) {
                    final aIsAdmin = space.admins.contains(a.userId);
                    final bIsAdmin = space.admins.contains(b.userId);
                    
                    if (aIsAdmin && !bIsAdmin) return -1;
                    if (!aIsAdmin && bIsAdmin) return 1;
                    return (a.displayName ?? '').compareTo(b.displayName ?? '');
                  });
                  
                  return ListView.builder(
                    itemCount: sortedMembers.length,
                    itemBuilder: (context, index) {
                      final member = sortedMembers[index];
                      final isAdmin = space.admins.contains(member.userId);
                      final isMemberCurrentUser = member.userId == currentUser.id;
                      
                      return _buildMemberTile(
                        context,
                        ref,
                        member,
                        isAdmin,
                        isCurrentUserAdmin && !isMemberCurrentUser,
                        operationState == MemberOperationState.loading,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading members: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    SpaceMemberEntity member,
    bool isAdmin,
    bool canManage,
    bool isLoading,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isAdmin ? AppColors.gold.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: isAdmin ? 1.0 : 0.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? AppColors.gold : Colors.grey.shade800,
          child: Text(
            (member.displayName ?? 'User')[0].toUpperCase(),
            style: TextStyle(
              color: isAdmin ? Colors.black : Colors.white,
            ),
          ),
        ),
        title: Text(
          member.displayName ?? 'User',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          isAdmin ? 'Admin' : 'Member',
          style: GoogleFonts.inter(
            color: isAdmin ? AppColors.gold : Colors.white70,
            fontStyle: isAdmin ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        trailing: canManage
            ? _buildManageButton(context, ref, member, isAdmin, isLoading)
            : null,
      ),
    );
  }
  
  Widget _buildManageButton(
    BuildContext context,
    WidgetRef ref,
    SpaceMemberEntity member,
    bool isAdmin,
    bool isLoading,
  ) {
    return isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          )
        : IconButton(
            icon: Icon(
              isAdmin ? Icons.person_remove : Icons.admin_panel_settings,
              color: isAdmin ? Colors.red : AppColors.gold,
            ),
            onPressed: () => _showRoleChangeDialog(
              context,
              ref,
              member,
              isAdmin,
            ),
            tooltip: isAdmin ? 'Remove admin role' : 'Make admin',
          );
  }
  
  Future<void> _showRoleChangeDialog(
    BuildContext context,
    WidgetRef ref,
    SpaceMemberEntity member,
    bool isAdmin,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          isAdmin ? 'Remove Admin Role?' : 'Make User Admin?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isAdmin
              ? 'Are you sure you want to remove ${member.displayName ?? "this user"} as an admin of this space?'
              : 'Are you sure you want to make ${member.displayName ?? "this user"} an admin of this space?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      if (isAdmin) {
        await removeUserAdmin(ref, spaceId, member.userId);
      } else {
        await makeUserAdmin(ref, spaceId, member.userId);
      }
    }
  }
}