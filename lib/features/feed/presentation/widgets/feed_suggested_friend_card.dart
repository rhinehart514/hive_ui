import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/features/friends/presentation/providers/suggested_friends_provider.dart' as friends_providers;
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'dart:ui';

/// Card widget displaying a suggested friend in the feed
class FeedSuggestedFriendCard extends StatefulWidget {
  /// The suggested friend to display
  final SuggestedFriend suggestedFriend;
  
  /// Callback when user taps the connect button
  final VoidCallback? onConnect;
  
  /// Callback when user dismisses the suggestion
  final VoidCallback? onDismiss;
  
  /// Constructor
  const FeedSuggestedFriendCard({
    Key? key,
    required this.suggestedFriend,
    this.onConnect,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<FeedSuggestedFriendCard> createState() => _FeedSuggestedFriendCardState();
}

class _FeedSuggestedFriendCardState extends State<FeedSuggestedFriendCard> {
  /// Access the suggestedFriend from widget
  SuggestedFriend get suggestedFriend => widget.suggestedFriend;

  @override
  Widget build(BuildContext context) {
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

    return Consumer(
      builder: (context, ref, child) {
        return GestureDetector(
          onTap: () => _viewProfile(context, ref),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Section title with premium styling
                      Row(
                        children: [
                          Icon(
                            HugeIcons.user,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SUGGESTED CONNECTION',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // User info section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Premium styled avatar
                      _buildAvatar(),
                      
                      const SizedBox(width: 16),
                      
                      // User details with HIVE typography
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestedFriend.name,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              suggestedFriend.status,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Match criteria row - styled like event details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        _getMatchIcon(),
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          matchDescription,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // View profile button - styled like secondary action
                      Expanded(
                        child: _AnimatedButton(
                          onTap: () => _viewProfile(context, ref),
                          text: 'View Profile',
                          isPrimary: false,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Request button - styled like primary action (RSVP)
                      Expanded(
                        child: _AnimatedButton(
                          onTap: () => _sendFriendRequest(context, ref),
                          text: suggestedFriend.isRequestSent ? 'Requested' : 'Connect',
                          isPrimary: true,
                          iconData: suggestedFriend.isRequestSent ? 
                            HugeIcons.strokeRoundedTick01 : HugeIcons.strokeRoundedUserGroup03,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Get the appropriate HugeIcon for the match criteria
  IconData _getMatchIcon() {
    switch (suggestedFriend.matchCriteria) {
      case MatchCriteria.major:
        return HugeIcons.strokeRoundedMortarboard02;
      case MatchCriteria.residence:
        return HugeIcons.strokeRoundedHouse03;
      case MatchCriteria.interest:
        return HugeIcons.tag;
    }
  }
  
  /// Build avatar with user image or initials
  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: suggestedFriend.profileImage != null && suggestedFriend.profileImage!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                suggestedFriend.profileImage!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar();
                },
              ),
            )
          : _buildInitialsAvatar(),
    );
  }
  
  /// Build avatar with user initials when image is not available
  Widget _buildInitialsAvatar() {
    // Get the first letter of first and last name
    final nameParts = suggestedFriend.name.split(' ');
    String initials = '';
    
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0];
      if (nameParts.length > 1) {
        initials += nameParts[nameParts.length - 1][0];
      }
    }
    
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Navigate to user profile
  void _viewProfile(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    // Navigate to the user's profile
    context.push('/profile/${suggestedFriend.id}');
  }
  
  /// Send friend request
  void _sendFriendRequest(BuildContext context, WidgetRef ref) async {
    // Provide haptic feedback for better UX
    HapticFeedback.mediumImpact();
    
    // Store context-dependent values before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userName = suggestedFriend.name;
    final userId = suggestedFriend.id;
    
    try {
      // Update UI optimistically for better UX
      final isAlreadyRequested = suggestedFriend.isRequestSent;
      
      if (!isAlreadyRequested) {
        // Send the request through the provider
        await ref.read(friends_providers.sendFriendRequestProvider(userId).future);
        
        // Check if still mounted before using context
        if (!mounted) return;
        
        // Show success message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Request sent to $userName'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Check if still mounted before using context
      if (!mounted) return;
      
      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send request: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Animated button with tap animation and styling based on HIVE design
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final bool isPrimary;
  final IconData? iconData;

  const _AnimatedButton({
    required this.onTap,
    required this.text,
    this.isPrimary = false,
    this.iconData,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              decoration: BoxDecoration(
                color: isPrimary 
                  ? Colors.white 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPrimary 
                    ? Colors.transparent 
                    : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.iconData != null) ...[
                    Icon(
                      widget.iconData,
                      size: 18,
                      color: isPrimary ? Colors.black : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isPrimary ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 