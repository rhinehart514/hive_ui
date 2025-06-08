import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A class representing a member of a space
class SpaceMember {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isAdmin;
  final bool isModerator;
  final DateTime joinedAt;
  final int activityLevel; // 0-100 indicating activity level

  const SpaceMember({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isAdmin = false,
    this.isModerator = false,
    required this.joinedAt,
    this.activityLevel = 0,
  });
}

/// A tab to display members of a space
class SpaceMembersTab extends ConsumerStatefulWidget {
  final List<SpaceMember> members;
  final Function(SpaceMember) onMemberTap;
  final bool isManager;
  final VoidCallback? onInviteMember;
  final String? spaceId;
  
  const SpaceMembersTab({
    Key? key,
    required this.members,
    required this.onMemberTap,
    this.isManager = false,
    this.onInviteMember,
    this.spaceId,
  }) : super(key: key);
  
  @override
  ConsumerState<SpaceMembersTab> createState() => _SpaceMembersTabState();
}

class _SpaceMembersTabState extends ConsumerState<SpaceMembersTab> {
  List<SpaceMember> _loadedMembers = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    
    // Load members from repository if we have a spaceId
    if (widget.spaceId != null) {
      _loadMembers();
    } else if (widget.members.isNotEmpty) {
      // Use provided members if spaceId is not available
      setState(() {
        _loadedMembers = widget.members;
        _isLoading = false;
      });
    } else {
      // No data source available
      setState(() {
        _isLoading = false;
        _error = 'No members data available';
      });
    }
  }
  
  Future<void> _loadMembers() async {
    if (widget.spaceId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Get the member IDs from repository
      final repository = ref.read(spaceRepositoryProvider);
      final memberIds = await repository.getSpaceMembers(widget.spaceId!);
      
      if (memberIds.isEmpty) {
        setState(() {
          _loadedMembers = [];
          _isLoading = false;
        });
        return;
      }
      
      // Get the space to check admins and moderators
      final space = await repository.getSpaceById(widget.spaceId!);
      final adminIds = space?.admins ?? [];
      final modIds = space?.moderators ?? [];
      
      // Load member data from Firestore
      final List<SpaceMember> members = [];
      final firestore = FirebaseFirestore.instance;
      
      for (final id in memberIds) {
        try {
          final doc = await firestore.collection('users').doc(id).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final displayName = data['displayName'] as String? ?? 'User';
            final photoUrl = data['profileImageUrl'] as String?;
            final joinedAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            members.add(SpaceMember(
              id: id,
              name: displayName,
              imageUrl: photoUrl,
              isAdmin: adminIds.contains(id),
              isModerator: modIds.contains(id),
              joinedAt: joinedAt,
              activityLevel: 50, // Default activity level
            ));
          }
        } catch (e) {
          debugPrint('Error loading member $id: $e');
        }
      }
      
      // Sort members: admins first, then moderators, then alphabetically
      members.sort((a, b) {
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        if (a.isModerator && !b.isModerator) return -1;
        if (!a.isModerator && b.isModerator) return 1;
        return a.name.compareTo(b.name);
      });
      
      if (mounted) {
        setState(() {
          _loadedMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load members: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Current user
    final currentUser = ref.watch(currentUserProvider);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadMembers(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }
    
    final members = _loadedMembers.isEmpty ? widget.members : _loadedMembers;
    
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No members yet',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to join this space!',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (widget.isManager && widget.onInviteMember != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onInviteMember!();
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Invite People'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed)) {
                        return AppColors.gold.withOpacity(0.15);
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Header with optional invite button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${members.length})',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
              ),
              if (widget.isManager && widget.onInviteMember != null)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onInviteMember!();
                  },
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return AppColors.gold.withOpacity(0.15);
                        }
                        return null;
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Member list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isCurrentUser = member.id == currentUser.id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onMemberTap(member);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: member.isAdmin ? AppColors.gold : AppColors.cardBorder,
                        width: member.isAdmin ? 2 : 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Profile image
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(member.isAdmin ? 10 : 11.5),
                            color: Colors.grey[800],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: member.imageUrl != null
                              ? Image.network(
                                  member.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 24,
                                ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Member info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and role badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      member.name + (isCurrentUser ? ' (You)' : ''),
                                      style: GoogleFonts.inter(
                                        color: AppColors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  
                                  if (member.isAdmin || member.isModerator)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: member.isAdmin
                                            ? AppColors.gold
                                            : Colors.blueGrey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        member.isAdmin ? 'Admin' : 'Mod',
                                        style: GoogleFonts.inter(
                                          color: member.isAdmin ? AppColors.black : AppColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Activity and join date
                              Text(
                                'Joined ${_formatJoinDate(member.joinedAt)}',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action icon
                        if (widget.isManager && !isCurrentUser)
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _showMemberActionSheet(member);
                            },
                            splashRadius: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Format join date as "X days ago" or date
  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 2) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  
  // Show action sheet for member management
  void _showMemberActionSheet(SpaceMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Member name title
              Text(
                member.name,
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Make admin/Remove admin action
              ListTile(
                leading: Icon(
                  member.isAdmin ? Icons.person_remove : Icons.admin_panel_settings,
                  color: member.isAdmin ? Colors.orange : AppColors.gold,
                ),
                title: Text(
                  member.isAdmin ? 'Remove as Admin' : 'Make Admin',
                  style: GoogleFonts.inter(color: AppColors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAdminStatus(member);
                },
              ),
              
              // Remove from space
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: Text(
                  'Remove from Space',
                  style: GoogleFonts.inter(color: AppColors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveMember(member);
                },
              ),
              
              // View profile
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.white),
                title: Text(
                  'View Profile',
                  style: GoogleFonts.inter(color: AppColors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onMemberTap(member);
                },
              ),
              
              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Toggle admin status for a member
  Future<void> _toggleAdminStatus(SpaceMember member) async {
    if (widget.spaceId == null) return;
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      
      if (member.isAdmin) {
        // Remove admin
        await repository.removeAdmin(widget.spaceId!, member.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} is no longer an admin'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Make admin
        await repository.addAdmin(widget.spaceId!, member.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} is now an admin'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Refresh member list
      _loadMembers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // Confirm removing a member from the space
  void _confirmRemoveMember(SpaceMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove ${member.name} from this space?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  // Remove a member from the space
  Future<void> _removeMember(SpaceMember member) async {
    if (widget.spaceId == null) return;
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      
      // Remove user from space
      await repository.leaveSpace(widget.spaceId!, userId: member.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} has been removed from the space'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Refresh member list
      _loadMembers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 