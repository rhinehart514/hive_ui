import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Data class for representing a space member
class SpaceMember {
  final String id;
  final String name;
  final String? imageUrl;
  final String? role;
  final bool isAdmin;
  final bool isModerator;
  final DateTime joinedAt;
  
  const SpaceMember({
    required this.id,
    required this.name,
    this.imageUrl,
    this.role,
    this.isAdmin = false,
    this.isModerator = false,
    required this.joinedAt,
  });
}

/// A tab to display members of a space
class SpaceMembersTab extends StatelessWidget {
  final List<SpaceMember> members;
  final Function(SpaceMember) onMemberTap;
  final VoidCallback? onInviteMember;
  final bool isManager;
  
  const SpaceMembersTab({
    Key? key,
    required this.members,
    required this.onMemberTap,
    this.onInviteMember,
    this.isManager = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Sort members with admins and moderators first
    final sortedMembers = [...members]..sort((a, b) {
      if (a.isAdmin && !b.isAdmin) return -1;
      if (!a.isAdmin && b.isAdmin) return 1;
      if (a.isModerator && !b.isModerator) return -1;
      if (!a.isModerator && b.isModerator) return 1;
      return a.name.compareTo(b.name); // Alphabetical for same roles
    });
    
    return Column(
      children: [
        // Header with optional invite button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
              ),
              if (isManager && onInviteMember != null)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onInviteMember!();
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18),
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
        
        // Member count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Text(
                '${members.length} members',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        
        // Members grid/list
        Expanded(
          child: members.isEmpty 
              ? _buildEmptyState() 
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: sortedMembers.length,
                  itemBuilder: (context, index) => _buildMemberCard(sortedMembers[index]),
                ),
        ),
      ],
    );
  }
  
  Widget _buildMemberCard(SpaceMember member) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onMemberTap(member);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          // Profile picture with role indicator
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Profile picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: member.isAdmin ? AppColors.gold : AppColors.cardBorder,
                    width: member.isAdmin ? 2 : 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(member.isAdmin ? 10 : 11.5),
                  child: member.imageUrl != null
                      ? Image.network(
                          member.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.white.withOpacity(0.3),
                                  size: 32,
                                ),
                              ),
                        )
                      : Center(
                          child: Icon(
                            Icons.person,
                            color: AppColors.white.withOpacity(0.3),
                            size: 32,
                          ),
                        ),
                ),
              ),
              
              // Role indicator badge
              if (member.isAdmin || member.isModerator)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: member.isAdmin 
                        ? AppColors.gold 
                        : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
          
          const SizedBox(height: 8),
          
          // Name
          Text(
            member.name,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          
          // Role
          if (member.role != null) ...[
            const SizedBox(height: 2),
            Text(
              member.role!,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outlined,
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
            'Be the first to join this space',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (isManager && onInviteMember != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onInviteMember!();
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Invite Members'),
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
} 