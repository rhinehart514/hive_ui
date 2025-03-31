import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

enum MessagingAppBarType {
  chatList,
  chat,
}

class MessagingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MessagingAppBarType type;
  final String title;
  final String? subtitle;
  final String? avatar;
  final bool isOnline;
  final int? onlineCount;
  final bool isGroupChat;
  final VoidCallback? onInfoTap;
  final VoidCallback? onSearchTap;
  final TextEditingController? searchController;
  final bool isSearchActive;
  final Function(String)? onSearchChanged;
  final List<String> filterOptions;
  final String selectedFilter;
  final Function(String)? onFilterChanged;

  const MessagingAppBar({
    Key? key,
    required this.type,
    required this.title,
    this.subtitle,
    this.avatar,
    this.isOnline = false,
    this.onlineCount,
    this.isGroupChat = false,
    this.onInfoTap,
    this.onSearchTap,
    this.searchController,
    this.isSearchActive = false,
    this.onSearchChanged,
    this.filterOptions = const [],
    this.selectedFilter = '',
    this.onFilterChanged,
  }) : super(key: key);

  @override
  Size get preferredSize =>
      Size.fromHeight(type == MessagingAppBarType.chatList ? 140 : 60);

  @override
  Widget build(BuildContext context) {
    return type == MessagingAppBarType.chatList
        ? _buildChatListAppBar(context)
        : _buildChatAppBar(context);
  }

  Widget _buildChatListAppBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with title and actions
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isSearchActive ? Icons.close : Icons.search,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: onSearchTap,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_square,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: onInfoTap,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Search bar if active
            if (isSearchActive && searchController != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),

            // Filter options
            if (!isSearchActive && filterOptions.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterOptions.length,
                  itemBuilder: (context, index) {
                    final filter = filterOptions[index];
                    final isSelected = filter == selectedFilter;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onFilterChanged?.call(filter);
                        },
                        backgroundColor: AppColors.cardBackground,
                        selectedColor: AppColors.gold.withOpacity(0.2),
                        checkmarkColor: AppColors.gold,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.cardBorder,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatAppBar(BuildContext context) {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBackground,
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.0,
              ),
              image: avatar != null
                  ? DecorationImage(
                      image: NetworkImage(avatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatar == null
                ? Icon(
                    isGroupChat ? Icons.group : Icons.person,
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
          ),

          const SizedBox(width: 12),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null ||
                    (isGroupChat && onlineCount != null) ||
                    isOnline)
                  Text(
                    subtitle ??
                        (isGroupChat ? '$onlineCount members' : 'Online'),
                    style: GoogleFonts.inter(
                      color: isOnline && !isGroupChat
                          ? Colors.green
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textPrimary,
          ),
          onPressed: onInfoTap,
        ),
      ],
    );
  }
}
