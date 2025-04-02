import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/presentation/providers/user_search_provider.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';

/// Screen for creating a new chat (direct message or group)
class ChatCreationScreen extends ConsumerStatefulWidget {
  const ChatCreationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatCreationScreen> createState() => _ChatCreationScreenState();
}

class _ChatCreationScreenState extends ConsumerState<ChatCreationScreen> {
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController();
  bool _isCreatingGroup = false;
  final List<ChatUser> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.length > 2) {
        ref.read(userSearchResultsProvider.notifier).searchUsers(query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _toggleGroupCreation() {
    setState(() {
      _isCreatingGroup = !_isCreatingGroup;
    });
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _createDirectChat(String userId) async {
    try {
      final controller = ref.read(messagingControllerProvider);
      final chatId = await controller.createDirectChat(userId);
      if (mounted) {
        context.go('/messaging/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat: $e')),
        );
      }
    }
  }

  Future<void> _createGroupChat() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    try {
      final userIds = _selectedUsers.map((user) => user.id).toList();
      final controller = ref.read(messagingControllerProvider);
      final chatId = await controller.createGroupChat(
        groupName,
        userIds,
      );
      if (mounted) {
        context.go('/messaging/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(userSearchResultsProvider);
    final isSearching = ref.watch(isSearchingProvider);

    // Convert User objects to ChatUser objects for display
    final chatUsers = searchResults.map((user) => ChatUser(
      id: user.id,
      name: user.displayName,
      avatarUrl: user.profilePicture,
      isOnline: false,
      lastActive: DateTime.now(),
    )).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: HiveAppBar(
        title: _isCreatingGroup ? 'New Group' : 'New Message',
        actions: [
          // Toggle between direct message and group chat
          IconButton(
            icon: Icon(
              _isCreatingGroup ? Icons.person : Icons.group,
              color: AppColors.gold, // Using the AppColors.gold for consistency
            ),
            onPressed: _toggleGroupCreation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for users...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Group name input (only for group creation)
          if (_isCreatingGroup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _groupNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Group name',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.group, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),

          // Selected users list (only for group creation)
          if (_isCreatingGroup && _selectedUsers.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  const Color(0xFFE2B253).withOpacity(0.2),
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(user.name[0],
                                      style:
                                          const TextStyle(color: Colors.white))
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _toggleUserSelection(user),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.name.length > 8
                              ? '${user.name.substring(0, 8)}...'
                              : user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Create group button (only for group creation)
          if (_isCreatingGroup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUsers.isEmpty ? null : _createGroupChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2B253),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Create Group',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),

          // Search results
          Expanded(
            child: ListView.builder(
              itemCount: chatUsers.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final user = chatUsers[index];
                final isSelected = _selectedUsers.any((u) => u.id == user.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE2B253).withOpacity(0.2),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(user.name[0],
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _isCreatingGroup
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleUserSelection(user),
                          activeColor: const Color(0xFFE2B253),
                          checkColor: Colors.black,
                        )
                      : Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                  onTap: _isCreatingGroup
                      ? () => _toggleUserSelection(user)
                      : () => _createDirectChat(user.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
