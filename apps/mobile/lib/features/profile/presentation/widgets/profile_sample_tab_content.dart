import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays a sample item card in the profile tabs
class ProfileItemCard extends StatelessWidget {
  /// The title of the item
  final String title;
  
  /// The subtitle of the item
  final String subtitle;
  
  /// The icon to display
  final IconData icon;
  
  /// The callback when the card is tapped
  final VoidCallback? onTap;

  /// Constructor
  const ProfileItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays a sample empty state for profile tabs
class ProfileEmptyState extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// The title to display
  final String title;
  
  /// The message to display
  final String message;
  
  /// The action button label
  final String actionLabel;
  
  /// The callback when the action button is tapped
  final VoidCallback? onActionPressed;

  /// Constructor
  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[850]!.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onActionPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onActionPressed!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget that displays sample content for the "Spaces" tab
class SampleSpacesTabContent extends ConsumerWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Constructor
  const SampleSpacesTabContent({
    super.key,
    required this.profile,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For demo purposes, we'll show either sample data or an empty state
    final hasSampleData = profile.clubCount > 0;
    
    if (!hasSampleData) {
      return ProfileEmptyState(
        icon: Icons.group,
        title: 'No Spaces Yet',
        message: isCurrentUser
            ? 'Join or create spaces to see them here'
            : '${profile.username} hasn\'t joined any spaces yet',
        actionLabel: 'Explore Spaces',
        onActionPressed: () {
          // Navigate to spaces explorer
        },
      );
    }
    
    // Show sample spaces
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Spaces (${profile.clubCount})',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        
        // Sample space items
        ProfileItemCard(
          title: 'HIVE Developers',
          subtitle: 'A community for sharing code and building apps',
          icon: Icons.code,
          onTap: () {
            // Navigate to space details
          },
        ),
        
        ProfileItemCard(
          title: 'Campus Events',
          subtitle: 'Discover and share events happening around campus',
          icon: Icons.event,
          onTap: () {
            // Navigate to space details
          },
        ),
        
        ProfileItemCard(
          title: 'Photography Club',
          subtitle: 'Share your photos and learn new techniques',
          icon: Icons.camera_alt,
          onTap: () {
            // Navigate to space details
          },
        ),
      ],
    );
  }
}

/// A widget that displays sample content for the "Events" tab
class SampleEventsTabContent extends ConsumerWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Constructor
  const SampleEventsTabContent({
    super.key,
    required this.profile,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For demo purposes, we'll show either sample data or an empty state
    final hasSampleData = profile.eventCount > 0;
    
    if (!hasSampleData) {
      return ProfileEmptyState(
        icon: Icons.event,
        title: 'No Events Yet',
        message: isCurrentUser
            ? 'Save events to see them here'
            : '${profile.username} hasn\'t saved any events yet',
        actionLabel: 'Find Events',
        onActionPressed: () {
          // Navigate to events explorer
        },
      );
    }
    
    // Show sample events
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Upcoming Events (${profile.eventCount})',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        
        // Sample event items
        ProfileItemCard(
          title: 'End of Year Party',
          subtitle: 'Dec 15, 2023 • 8:00 PM • Main Campus',
          icon: Icons.celebration,
          onTap: () {
            // Navigate to event details
          },
        ),
        
        ProfileItemCard(
          title: 'Tech Workshop: Flutter',
          subtitle: 'Jan 10, 2024 • 3:00 PM • Engineering Building',
          icon: Icons.code,
          onTap: () {
            // Navigate to event details
          },
        ),
        
        ProfileItemCard(
          title: 'Career Fair',
          subtitle: 'Jan 25, 2024 • 10:00 AM • Student Center',
          icon: Icons.work,
          onTap: () {
            // Navigate to event details
          },
        ),
      ],
    );
  }
}

/// A widget that displays sample content for the "Friends" tab
class SampleFriendsTabContent extends ConsumerWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Constructor
  const SampleFriendsTabContent({
    super.key,
    required this.profile,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For demo purposes, we'll show either sample data or an empty state
    final hasSampleData = profile.friendCount > 0;
    
    if (!hasSampleData) {
      return ProfileEmptyState(
        icon: Icons.people,
        title: 'No Friends Yet',
        message: isCurrentUser
            ? 'Connect with friends to see them here'
            : '${profile.username} hasn\'t connected with friends yet',
        actionLabel: 'Find Friends',
        onActionPressed: () {
          // Navigate to find friends
        },
      );
    }
    
    // Show sample friends
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Friends (${profile.friendCount})',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        
        // Sample friend items
        ProfileItemCard(
          title: 'Alex Johnson',
          subtitle: 'Computer Science • Junior',
          icon: Icons.person,
          onTap: () {
            // Navigate to friend profile
          },
        ),
        
        ProfileItemCard(
          title: 'Sara Williams',
          subtitle: 'Business • Senior',
          icon: Icons.person,
          onTap: () {
            // Navigate to friend profile
          },
        ),
        
        ProfileItemCard(
          title: 'Michael Chen',
          subtitle: 'Engineering • Sophomore',
          icon: Icons.person,
          onTap: () {
            // Navigate to friend profile
          },
        ),
      ],
    );
  }
} 