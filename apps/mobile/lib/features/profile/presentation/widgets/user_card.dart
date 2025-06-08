import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A card that displays a user profile with their basic information
class UserCard extends StatelessWidget {
  /// The user profile to display
  final UserProfile user;
  
  /// Callback when the card is tapped
  final VoidCallback onTap;
  
  /// Callback when the follow button is tapped
  final Function(bool isFollowing) onFollow;
  
  /// Whether the user is currently being followed
  final bool isFollowing;

  /// Constructor
  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
    required this.onFollow,
    this.isFollowing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Profile Image
            _buildProfileImage(),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameWithVerification(),
                  const SizedBox(height: 4),
                  _buildMajorAndYear(),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildBio(),
                  ],
                  const SizedBox(height: 8),
                  _buildInterestTags(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Follow Button
            SizedBox(
              width: 100,
              child: _buildFollowButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.gold.withOpacity(0.1),
      backgroundImage: user.profileImageUrl != null
          ? NetworkImage(user.profileImageUrl!)
          : null,
      child: user.profileImageUrl == null
          ? Text(
              user.displayName[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            )
          : null,
    );
  }

  Widget _buildNameWithVerification() {
    return Row(
      children: [
        Flexible(
          child: Text(
            user.displayName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (user.isVerified)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.verified,
              size: 16,
              color: AppColors.gold,
            ),
          ),
      ],
    );
  }

  Widget _buildMajorAndYear() {
    return Text(
      '${user.major} • ${user.year}',
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.grey[400],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBio() {
    return Text(
      user.bio!,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.grey[300],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInterestTags() {
    final interests = user.interests.take(3).toList();
    
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            interest,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.gold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: () => onFollow(!isFollowing),
      style: ElevatedButton.styleFrom(
        foregroundColor: isFollowing ? Colors.black : Colors.white,
        backgroundColor: isFollowing ? AppColors.gold : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isFollowing ? Colors.transparent : AppColors.gold,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 