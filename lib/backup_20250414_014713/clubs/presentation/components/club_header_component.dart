import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Models
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';

/// A reusable card-style header component that can be used across the platform
/// for displaying club information in a consistent way.
class ClubHeaderCard extends StatelessWidget {
  final Club? club;
  final Space? space;
  final bool isFollowing;
  final int followerCount;
  final int eventCount;
  final int mediaCount;
  final bool chatUnlocked;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onChatLockedMessage;

  const ClubHeaderCard({
    Key? key,
    this.club,
    this.space,
    this.isFollowing = false,
    this.followerCount = 0,
    this.eventCount = 0,
    this.mediaCount = 0,
    this.chatUnlocked = false,
    this.onFollowPressed,
    this.onMessagePressed,
    this.onChatLockedMessage,
  })  : assert(club != null || space != null,
            'Either club or space must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine name and description based on available data
    final name = club?.name ?? space?.name ?? 'Club Space';
    final description = club?.description ?? space?.description ?? '';
    final icon = club?.icon ?? Icons.groups;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Club profile section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Club icon with gold circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gold.withOpacity(0.8),
                          AppColors.gold.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Container(
                        color: Colors.black,
                        child: Icon(
                          icon,
                          size: 34,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Club name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.3,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats row - inside container with slight color difference
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('$followerCount', 'Followers'),
                  _buildVerticalDivider(),
                  _buildStatItem('$eventCount', 'Events'),
                  _buildVerticalDivider(),
                  _buildStatItem('$mediaCount', 'Photos'),
                ],
              ),
            ),

            // Action buttons (follow, message)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  // Follow button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onFollowPressed?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFollowing ? Colors.green : AppColors.gold,
                        foregroundColor:
                            isFollowing ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
                        shadowColor: isFollowing
                            ? Colors.green.withOpacity(0.4)
                            : AppColors.gold.withOpacity(0.4),
                        minimumSize: const Size(0, 48), // Better touch target
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Message button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: chatUnlocked
                          ? () {
                              HapticFeedback.mediumImpact();
                              onMessagePressed?.call();
                            }
                          : () {
                              HapticFeedback.mediumImpact();
                              onChatLockedMessage?.call();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: chatUnlocked
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: chatUnlocked
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        minimumSize: const Size(0, 48), // Better touch target
                      ),
                      child: Text(
                        chatUnlocked ? 'Message' : 'Chat Locked',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build stat item
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Helper to build vertical divider between stats
  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }
}
