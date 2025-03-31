import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_ui/widgets/profile/profile_image_picker.dart';
import 'package:hive_ui/widgets/profile/pulsing_verified_badge.dart';

/// Widget for displaying the user's header information
class ProfileHeaderSection extends StatelessWidget {
  final UserProfile profile;
  final double? width;
  final double? height;
  final bool isCurrentUser;
  final bool isImagePickerEnabled;
  final VoidCallback? onImageTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onVerifiedPlusTap;

  const ProfileHeaderSection({
    super.key,
    required this.profile,
    this.width,
    this.height,
    required this.isCurrentUser,
    this.isImagePickerEnabled = false,
    this.onImageTap,
    this.onCameraTap,
    this.onGalleryTap,
    this.onVerifiedPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileImagePicker(
          imageUrl: profile.profileImageUrl,
          width: width ?? 80.0,
          height: height ?? 80.0,
          onImageFromCamera: (imagePath) {
            if (onCameraTap != null) onCameraTap!();
          },
          onImageFromGallery: (imagePath) {
            if (onGalleryTap != null) onGalleryTap!();
          },
          onImageRemoved: () {
            // Add empty callback to satisfy the required parameter
          },
          onImageTap: onImageTap,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  profile.username,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (profile.accountTier != AccountTier.public)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: profile.accountTier == AccountTier.verifiedPlus
                        ? PulsingVerifiedBadge(onTap: onVerifiedPlusTap)
                        : const Icon(
                            Icons.verified_user,
                            size: 18,
                            color: Colors.blue,
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.school,
                  color: Colors.white60,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${profile.year} · ${profile.major}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.home,
                  color: Colors.white60,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  profile.residence,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for displaying the user's statistics (followers, following, etc.)
class ProfileStatsSection extends StatelessWidget {
  final UserProfile profile;

  const ProfileStatsSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildStatItem(
            count: profile.eventCount,
            label: 'Events',
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            count: profile.clubCount,
            label: 'Spaces',
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            count: profile.friendCount,
            label: 'Friends',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying and editing the user's bio
class ProfileBioSection extends StatelessWidget {
  final UserProfile profile;
  final bool isCurrentUser;
  final bool isEditingBio;
  final TextEditingController bioController;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  const ProfileBioSection({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    required this.isEditingBio,
    required this.bioController,
    required this.onEditToggle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bio',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isCurrentUser)
                GestureDetector(
                  onTap: onEditToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isEditingBio ? 'Cancel' : 'Edit',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEditingBio) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: bioController,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  hintText: 'Write something about yourself...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  counterStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              profile.bio ?? 'No bio yet.',
              style: GoogleFonts.inter(
                color: profile.bio != null ? Colors.white : Colors.white38,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying action buttons (follow, message, settings)
class ProfileActionSection extends StatelessWidget {
  final UserProfile profile;
  final bool isCurrentUser;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final VoidCallback onMessage;
  final VoidCallback onSettings;

  const ProfileActionSection({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onMessage,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          if (isCurrentUser) ...[
            // Edit Profile Button
            Expanded(
              child: ElevatedButton(
                onPressed: onSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Follow/Unfollow Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onToggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.gold,
                  foregroundColor: isFollowing ? Colors.white : Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Message Button
            Expanded(
              child: ElevatedButton(
                onPressed: onMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Message',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tab content for displaying user's events
class EventsGridTab extends StatelessWidget {
  final UserProfile profile;

  const EventsGridTab({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data - in a real app, this would come from a repository
    final List<Map<String, dynamic>> events = [
      {
        'id': '1',
        'title': 'Campus Hackathon',
        'date': 'Mar 15',
        'imageUrl': null,
      },
      {
        'id': '2',
        'title': 'AI Workshop',
        'date': 'Apr 2',
        'imageUrl': null,
      },
      {
        'id': '3',
        'title': 'Career Fair',
        'date': 'Apr 10',
        'imageUrl': null,
      },
    ];

    if (events.isEmpty) {
      return _buildEmptyState('No events yet');
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildEventCard(events[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: event['imageUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(event['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: event['imageUrl'] == null
                  ? const Center(
                      child: Icon(
                        Icons.event,
                        color: Colors.white30,
                        size: 40,
                      ),
                    )
                  : null,
            ),
          ),
          // Event Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  event['date'],
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            color: Colors.white30,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab content for displaying user's spaces
class SpacesGridTab extends StatelessWidget {
  final UserProfile profile;

  const SpacesGridTab({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data - in a real app, this would come from a repository
    final List<Map<String, dynamic>> spaces = [
      {
        'id': '1',
        'name': 'Computer Science Space',
        'role': 'Member',
        'imageUrl': null,
      },
      {
        'id': '2',
        'name': 'Photography Society',
        'role': 'Admin',
        'imageUrl': null,
      },
    ];

    if (spaces.isEmpty) {
      return _buildEmptyState('No spaces yet');
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: spaces.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildSpaceCard(spaces[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpaceCard(Map<String, dynamic> space) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Space Logo
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: space['imageUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(space['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: space['imageUrl'] == null
                  ? const Center(
                      child: Icon(
                        Icons.groups,
                        color: Colors.white30,
                        size: 40,
                      ),
                    )
                  : null,
            ),
          ),
          // Space Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space['name'],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  space['role'],
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups_outlined,
            color: Colors.white30,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab content for displaying user's interests
class InterestsGridTab extends StatelessWidget {
  final UserProfile profile;

  const InterestsGridTab({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Use the interests from the profile model if available, otherwise use empty list
    final List<String> interests = profile.interests ?? [];

    if (interests.isEmpty) {
      return _buildEmptyState('No interests added yet');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests
                .map((interest) => _buildInterestChip(interest))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        interest,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.interests_outlined,
            color: Colors.white30,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
