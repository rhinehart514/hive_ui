import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:hive_ui/theme/app_colors.dart';

/// A simplified screen for creating a new chat with another user
class BasicChatCreationScreen extends ConsumerStatefulWidget {
  const BasicChatCreationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BasicChatCreationScreen> createState() =>
      _BasicChatCreationScreenState();
}

class _BasicChatCreationScreenState
    extends ConsumerState<BasicChatCreationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<ChatUser> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_isUserSelected(user)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  bool _isUserSelected(ChatUser user) {
    return _selectedUsers.any((u) => u.id == user.id);
  }

  Future<void> _createChat() async {
    if (_selectedUsers.isEmpty) {
      return;
    }

    try {
      final targetUserId = _selectedUsers.first.id;
      final chatId = await ref
          .read(injection.createDirectChatProvider(targetUserId).future);

      if (!mounted) return;

      // Navigate to the new chat
      context.push('/messaging/chat/$chatId', extra: {
        'chatName': _selectedUsers.first.name,
        'chatAvatar': _selectedUsers.first.avatarUrl,
        'isGroupChat': false,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This would normally be a real search against the server
    // For this example, we'll simulate with sample data
    final searchResults = _generateSampleUsers().where((user) {
      if (_searchQuery.isEmpty) return true;
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('New Chat'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedUsers.isNotEmpty)
            TextButton(
              onPressed: _createChat,
              child: const Text(
                'Start',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                hintText: 'Search for people',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Selected users chips
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundImage:
                            user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                        backgroundColor: Colors.grey.shade700,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      label: Text(user.name),
                      backgroundColor: Colors.grey.shade800,
                      labelStyle: const TextStyle(color: Colors.white),
                      deleteIconColor: Colors.white70,
                      onDeleted: () => _toggleUserSelection(user),
                    ),
                  );
                },
              ),
            ),

          // Search results
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                final isSelected = _isUserSelected(user);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                    backgroundColor: Colors.grey.shade700,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(user.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    user.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: user.isOnline ? Colors.green : Colors.white54,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.gold)
                      : const Icon(Icons.add_circle_outline,
                          color: Colors.white54),
                  onTap: () => _toggleUserSelection(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Sample data for demo purposes
  List<ChatUser> _generateSampleUsers() {
    return [
      const ChatUser(
        id: '1',
        name: 'Alice Johnson',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      const ChatUser(
        id: '2',
        name: 'Bob Smith',
        isOnline: false,
        avatarUrl: 'https://i.pravatar.cc/150?img=2',
      ),
      const ChatUser(
        id: '3',
        name: 'Charlie Brown',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=3',
      ),
      const ChatUser(
        id: '4',
        name: 'Diana Prince',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=4',
      ),
      const ChatUser(
        id: '5',
        name: 'Edward Cullen',
        isOnline: false,
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
      ),
      const ChatUser(
        id: '6',
        name: 'Fiona Apple',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=6',
      ),
      const ChatUser(
        id: '7',
        name: 'George Michael',
        isOnline: false,
        avatarUrl: 'https://i.pravatar.cc/150?img=7',
      ),
      const ChatUser(
        id: '8',
        name: 'Hannah Montana',
        isOnline: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=8',
      ),
    ];
  }
}
