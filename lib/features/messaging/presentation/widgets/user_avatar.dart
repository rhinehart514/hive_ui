import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A user avatar widget with optional online status indicator
class UserAvatar extends ConsumerWidget {
  final String userId;
  final String? imageUrl;
  final double size;
  final bool showOnlineStatus;
  
  const UserAvatar({
    Key? key,
    required this.userId,
    this.imageUrl,
    this.size = 40.0,
    this.showOnlineStatus = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Avatar image
        _buildAvatarImage(),
        
        // Online status indicator (if enabled)
        if (showOnlineStatus) 
          _buildOnlineIndicator(ref),
      ],
    );
  }
  
  /// Builds the avatar image (either from URL or placeholder)
  Widget _buildAvatarImage() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade800,
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }
  
  /// Builds a placeholder for when there's no image
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
  
  /// Gets initials from user ID for the placeholder
  String _getInitials() {
    if (userId.isEmpty) return '?';
    
    // Just use the first character as an initial
    return userId[0].toUpperCase();
  }
  
  /// Builds the online status indicator dot
  Widget _buildOnlineIndicator(WidgetRef ref) {
    // Watch the online status for this user
    final onlineStatusAsync = ref.watch(userOnlineStatusProvider(userId));
    
    return Positioned(
      right: 0,
      bottom: 0,
      child: onlineStatusAsync.when(
        data: (isOnline) => Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: 1.5,
            ),
          ),
        ),
        loading: () => SizedBox(
          width: size * 0.3,
          height: size * 0.3,
        ),
        error: (_, __) => SizedBox(
          width: size * 0.3,
          height: size * 0.3,
        ),
      ),
    );
  }
} 
 
 