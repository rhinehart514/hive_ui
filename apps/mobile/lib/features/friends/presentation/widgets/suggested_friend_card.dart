import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'dart:ui';

/// A card widget that displays a suggested friend with matching criteria
class SuggestedFriendCard extends ConsumerWidget {
  /// The suggested friend to display
  final SuggestedFriend suggestedFriend;
  
  /// Callback when the request button is pressed
  final VoidCallback? onRequestPressed;
  
  /// Callback when the card is tapped to view profile
  final VoidCallback? onCardTapped;
  
  const SuggestedFriendCard({
    super.key,
    required this.suggestedFriend,
    this.onRequestPressed,
    this.onCardTapped,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Match criteria description
    String matchDescription;
    switch (suggestedFriend.matchCriteria) {
      case MatchCriteria.major:
        matchDescription = 'Same major: ${suggestedFriend.matchValue}';
        break;
      case MatchCriteria.residence:
        matchDescription = 'Lives in ${suggestedFriend.matchValue}';
        break;
      case MatchCriteria.interest:
        matchDescription = 'Shares interest: ${suggestedFriend.matchValue}';
        break;
    }
    
    return GestureDetector(
      onTap: () {
        if (onCardTapped != null) {
          HapticFeedback.lightImpact();
          onCardTapped!();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Using subtle decoration with depth following brand aesthetic
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile image
                      _buildProfileImage(),
                      
                      const SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestedFriend.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestedFriend.status,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Match description with highlight icon
                            Row(
                              children: [
                                // Use gold icon to highlight the match - following brand aesthetic
                                Icon(
                                  _getMatchIcon(),
                                  color: AppColors.gold,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    matchDescription,
                                    style: GoogleFonts.inter(
                                      color: AppColors.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Request button - following brand aesthetic for buttons
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        if (onRequestPressed != null) {
                          HapticFeedback.mediumImpact();
                          onRequestPressed!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'Request',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get the appropriate icon for the match criteria
  IconData _getMatchIcon() {
    switch (suggestedFriend.matchCriteria) {
      case MatchCriteria.major:
        return Icons.school_outlined;
      case MatchCriteria.residence:
        return Icons.home_outlined;
      case MatchCriteria.interest:
        return Icons.star_outline;
    }
  }
  
  /// Build the profile image with fallback
  Widget _buildProfileImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[900],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: suggestedFriend.profileImage != null && suggestedFriend.profileImage!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                suggestedFriend.profileImage!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar();
                },
              ),
            )
          : _buildInitialsAvatar(),
    );
  }
  
  /// Build an avatar with user's initials
  Widget _buildInitialsAvatar() {
    final initials = suggestedFriend.name.isNotEmpty
        ? suggestedFriend.name.characters.first.toUpperCase()
        : '?';
        
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 