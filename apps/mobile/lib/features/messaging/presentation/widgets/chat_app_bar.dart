import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

class ChatAppBar extends StatelessWidget {
  final String chatName;
  final String? chatAvatar;
  final bool isOnline;
  final int? onlineCount;
  final bool isGroupChat;
  final VoidCallback? onInfoTap;

  const ChatAppBar({
    Key? key,
    required this.chatName,
    this.chatAvatar,
    this.isOnline = false,
    this.onlineCount,
    this.isGroupChat = false,
    this.onInfoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          _buildAvatar(),

          const SizedBox(width: 12),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chatName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isGroupChat && onlineCount != null)
                  Text(
                    '$onlineCount members',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  )
                else if (isOnline)
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Info/Options Button
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textPrimary,
          ),
          onPressed: onInfoTap ??
              () {
                // Show chat options
                _showChatOptions(context);
              },
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardBackground,
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        image: chatAvatar != null
            ? DecorationImage(
                image: NetworkImage(chatAvatar!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: chatAvatar == null
          ? isGroupChat
              ? const Icon(
                  Icons.group,
                  color: AppColors.gold,
                  size: 20,
                )
              : const Icon(
                  Icons.person,
                  color: AppColors.gold,
                  size: 20,
                )
          : isOnline && !isGroupChat
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                )
              : null,
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Menu options
            _buildOptionTile(
              icon: Icons.search,
              label: 'Search conversation',
              onTap: () {
                Navigator.pop(context);
                // Implement search functionality
              },
            ),

            if (isGroupChat)
              _buildOptionTile(
                icon: Icons.group,
                label: 'View members',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to group members screen
                },
              ),

            _buildOptionTile(
              icon: Icons.notifications,
              label: 'Mute notifications',
              onTap: () {
                Navigator.pop(context);
                // Implement mute notifications
              },
            ),

            _buildOptionTile(
              icon: Icons.wallpaper,
              label: 'Change background',
              onTap: () {
                Navigator.pop(context);
                // Implement background change
              },
            ),

            _buildOptionTile(
              icon: Icons.block,
              label: isGroupChat ? 'Leave group' : 'Block user',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                // Implement block or leave
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.gold,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
