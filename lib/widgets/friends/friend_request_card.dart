import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:hive_ui/widgets/common/glass_container.dart';
import 'package:hive_ui/providers/friend_providers.dart';

/// A card displaying a friend request with accept/reject actions
class FriendRequestCard extends ConsumerWidget {
  /// The unique ID of this friend request
  final String requestId;
  
  /// The ID of the sender
  final String senderId;
  
  /// The sender's display name
  final String senderName;
  
  /// Optional image URL for the sender's profile picture
  final String? senderImageUrl;
  
  /// The sender's academic major
  final String senderMajor;
  
  /// The sender's academic year (freshman, sophomore, etc)
  final String senderYear;
  
  /// When the request was created
  final DateTime createdAt;
  
  /// Callback when the request has been handled (accepted or rejected)
  final VoidCallback? onRequestHandled;

  const FriendRequestCard({
    super.key,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.senderMajor,
    required this.senderYear,
    required this.createdAt,
    this.onRequestHandled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For tracking accept/reject operations
    final acceptingState = ref.watch(
      acceptFriendRequestProvider((requestId: requestId, friendId: senderId)),
    );
    
    final rejectingState = ref.watch(
      rejectFriendRequestProvider(requestId),
    );
    
    final isAccepting = acceptingState is AsyncLoading;
    final isRejecting = rejectingState is AsyncLoading;
    
    // Format time since request
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    String timeAgo;
    
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays}d ago';
    } else {
      final date = createdAt;
      timeAgo = '${date.month}/${date.day}/${date.year}';
    }
    
    return GlassContainer(
      blur: 5,
      opacity: 0.1,
      borderRadius: 16,
      withBorder: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    shape: BoxShape.circle,
                    image: senderImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(senderImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: senderImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.white.withOpacity(0.2),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Sender info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: AppTextStyles.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$senderYear · $senderMajor',
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Time stamp
                Text(
                  timeAgo,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Request message
            Text(
              '$senderName wants to connect with you',
              style: AppTextStyles.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Reject button
                OutlinedButton(
                  onPressed: isRejecting || isAccepting
                      ? null
                      : () => _handleReject(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.white.withOpacity(0.1);
                        }
                        return null;
                      },
                    ),
                  ),
                  child: isRejecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Decline'),
                ),
                
                const SizedBox(width: 12),
                
                // Accept button
                ElevatedButton(
                  onPressed: isRejecting || isAccepting
                      ? null
                      : () => _handleAccept(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.black,
                          ),
                        )
                      : const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    
    try {
      final accepted = await ref.read(
        acceptFriendRequestProvider((requestId: requestId, friendId: senderId)).future,
      );
      
      if (accepted && onRequestHandled != null) {
        onRequestHandled!();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are now friends with $senderName'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept friend request: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
  
  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    
    try {
      final rejected = await ref.read(
        rejectFriendRequestProvider(requestId).future,
      );
      
      if (rejected && onRequestHandled != null) {
        onRequestHandled!();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request from $senderName declined'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline friend request: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
} 