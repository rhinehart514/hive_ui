import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_member_management.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth;
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';

/// A tab to display members of a space with admin management capabilities
class SpaceMembersTab extends ConsumerStatefulWidget {
  /// The ID of the space
  final String spaceId;

  /// Constructor
  const SpaceMembersTab({
    Key? key,
    required this.spaceId,
  }) : super(key: key);

  @override
  ConsumerState<SpaceMembersTab> createState() => _SpaceMembersTabState();
}

class _SpaceMembersTabState extends ConsumerState<SpaceMembersTab> {
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _checkIfManager();
  }

  Future<void> _checkIfManager() async {
    final spaceAsync = ref.read(spaceProvider(widget.spaceId));
    
    if (!spaceAsync.hasValue) return;
    
    final space = spaceAsync.value;
    if (space == null) return;
    
    final currentUser = ref.read(auth.currentUserProvider);
    
    if (currentUser.isNotEmpty) {
      setState(() {
        _isManager = space.admins.contains(currentUser.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaceMembersAsync = ref.watch(_spaceMembersProvider(widget.spaceId));
    final spaceAsync = ref.watch(spaceProvider(widget.spaceId));

    return spaceAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error loading space: $err',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      data: (space) {
        if (space == null) {
          return const Center(
            child: Text(
              'Space not found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return spaceMembersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error loading members: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (members) {
            // Separate admins and regular members
            final admins = members.where((m) => m.role == 'admin').toList();
            final regularMembers = members.where((m) => m.role != 'admin').toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.black.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Space Members',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${members.length} members',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Admins section
                        if (admins.isNotEmpty) ...[
                          Text(
                            'Admins',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...admins.map((member) => _buildMemberTile(member, true)),
                          const Divider(color: Colors.white24, height: 32),
                        ],
                        
                        // Regular members section
                        if (regularMembers.isNotEmpty) ...[
                          Text(
                            'Members',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...regularMembers.map((member) => _buildMemberTile(member, false)),
                        ],
                        
                        if (members.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No members yet',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This space doesn\'t have any members yet.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Show member management for admins
                if (_isManager) ...[
                  const SizedBox(height: 24),
                  SpaceMemberManagement(spaceId: widget.spaceId),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMemberTile(SpaceMemberEntity member, bool isAdmin) {
    return Consumer(
      builder: (context, ref, child) {
        final userProfileAsync = ref.watch(userProfileProvider(member.userId));
        
        return userProfileAsync.when(
          loading: () => const ListTile(
            leading: CircleAvatar(),
            title: LinearProgressIndicator(),
          ),
          error: (_, __) => ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              member.displayName ?? 'Unknown User',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Error loading profile',
              style: TextStyle(color: Colors.red.shade300),
            ),
          ),
          data: (profile) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: profile?.photoUrl != null
                    ? NetworkImage(profile!.photoUrl!)
                    : null,
                backgroundColor: profile?.photoUrl == null
                    ? isAdmin
                        ? AppColors.gold.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2)
                    : null,
                child: profile?.photoUrl == null
                    ? Icon(
                        Icons.person,
                        color: isAdmin ? AppColors.gold : Colors.white,
                      )
                    : null,
              ),
              title: Text(
                profile?.displayName ?? member.displayName ?? 'Unknown User',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                isAdmin ? 'Admin' : 'Member since ${_formatDate(member.joinedAt)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isAdmin ? AppColors.gold : Colors.white.withOpacity(0.7),
                ),
              ),
              trailing: _isManager && !isAdmin
                  ? IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showMemberOptions(member, profile),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
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

  void _showMemberOptions(SpaceMemberEntity member, UserProfile? profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: AppColors.gold),
                  title: Text(
                    'Make Admin',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _promoteToAdmin(member);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: Text(
                    'Remove from Space',
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeMember(member);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promoteToAdmin(SpaceMemberEntity member) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Make Admin',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to make ${member.displayName} an admin? This will give them full control over the space.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Make Admin', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(spaceRepositoryProvider);
      await repository.updateSpaceMemberRole(
        widget.spaceId,
        member.userId,
        'admin',
      );
      
      // Refresh space and members
      ref.refresh(_spaceMembersProvider(widget.spaceId));
      ref.read(spacesProvider.notifier).refreshSpace(widget.spaceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} is now an admin'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(SpaceMemberEntity member) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Member',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this space?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(spaceRepositoryProvider);
      await repository.leaveSpace(widget.spaceId, userId: member.userId);
      
      // Refresh space and members
      ref.refresh(_spaceMembersProvider(widget.spaceId));
      ref.read(spacesProvider.notifier).refreshSpace(widget.spaceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} has been removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Provider for space members
final _spaceMembersProvider = FutureProvider.family<List<SpaceMemberEntity>, String>(
  (ref, spaceId) async {
    final repository = ref.watch(spaceRepositoryProvider);
    return repository.getSpaceMembersWithDetails(spaceId);
  },
); 