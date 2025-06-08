import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/presentation/providers/social_providers.dart';

/// A button that handles following/unfollowing users with proper state management
class FollowButton extends ConsumerStatefulWidget {
  /// The ID of the user to follow/unfollow
  final String userId;

  /// Optional callback when the follow state changes
  final void Function(bool isFollowing)? onFollowStateChanged;

  /// Constructor
  const FollowButton({
    super.key,
    required this.userId,
    this.onFollowStateChanged,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize following status
    _initializeFollowingStatus();
  }

  Future<void> _initializeFollowingStatus() async {
    try {
      await ref.read(socialProvider.notifier).initializeFollowingStatus(widget.userId);
    } catch (e) {
      debugPrint('Error initializing following status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the following status stream
    final followingStatus = ref.watch(followingStatusProvider(widget.userId));
    final socialState = ref.watch(socialProvider);

    // Handle loading state
    if (socialState.isLoading || _isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final isFollowing = followingStatus.value ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _handleToggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white.withOpacity(0.1) : AppColors.gold,
          foregroundColor: isFollowing ? Colors.white : Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isFollowing
                ? BorderSide(color: AppColors.gold.withOpacity(0.3))
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isFollowing) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check,
                size: 16,
                color: AppColors.gold,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleFollow() async {
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);

    try {
      await ref.read(socialProvider.notifier).toggleFollow(widget.userId);
      
      // Notify parent of state change if callback provided
      final newFollowingStatus = await ref.read(isFollowingUseCaseProvider).execute(widget.userId);
      widget.onFollowStateChanged?.call(newFollowingStatus);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update following status: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 