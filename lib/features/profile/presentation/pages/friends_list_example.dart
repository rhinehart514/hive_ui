import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/widgets/offline_action_status.dart';
import 'package:hive_ui/core/widgets/optimistic_action_builder.dart';
import 'package:uuid/uuid.dart';

// Friend model
class Friend {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isFavorite;

  Friend({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isFavorite = false,
  });

  Friend copyWith({
    String? name,
    String? avatarUrl,
    bool? isFavorite,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// Mock friend repository
class FriendRepository {
  final List<Friend> _friends = [
    Friend(id: '1', name: 'Alex Johnson', isFavorite: true),
    Friend(id: '2', name: 'Taylor Smith', isFavorite: false),
    Friend(id: '3', name: 'Jordan Williams', isFavorite: true),
    Friend(id: '4', name: 'Casey Brown', isFavorite: false),
    Friend(id: '5', name: 'Riley Davis', isFavorite: false),
  ];

  Future<List<Friend>> getFriends() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _friends;
  }

  Future<void> toggleFavorite(String friendId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Toggle favorite status
    final index = _friends.indexWhere((friend) => friend.id == friendId);
    if (index >= 0) {
      _friends[index] = _friends[index].copyWith(
        isFavorite: !_friends[index].isFavorite,
      );
    }

    // Simulate occasional failure (1 in 5 requests fail)
    if (DateTime.now().microsecond % 5 == 0) {
      throw Exception('Network error');
    }
  }

  Future<void> removeFriend(String friendId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Remove friend
    _friends.removeWhere((friend) => friend.id == friendId);

    // Simulate occasional failure (1 in 5 requests fail)
    if (DateTime.now().microsecond % 5 == 0) {
      throw Exception('Network error');
    }
  }

  Future<Friend> addFriend(String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create new friend
    final newFriend = Friend(
      id: const Uuid().v4(),
      name: name,
      isFavorite: false,
    );

    // Add to list
    _friends.add(newFriend);

    // Simulate occasional failure (1 in 5 requests fail)
    if (DateTime.now().microsecond % 5 == 0) {
      throw Exception('Network error');
    }

    return newFriend;
  }
}

// Friend repository provider
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

// Provider for friends list
final friendsProvider = FutureProvider<List<Friend>>((ref) async {
  final repository = ref.watch(friendRepositoryProvider);
  return repository.getFriends();
});

// Controller for friends list with offline support
class FriendsController {
  final FriendRepository _repository;
  final OfflineQueueManager _offlineQueueManager;
  final ConnectivityService _connectivityService;

  FriendsController({
    required FriendRepository repository,
    required OfflineQueueManager offlineQueueManager,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _offlineQueueManager = offlineQueueManager,
        _connectivityService = connectivityService {
    _registerOfflineHandlers();
  }

  // Register offline action handlers
  void _registerOfflineHandlers() {
    _offlineQueueManager.registerExecutor(
      'friends',
      _executeFriendAction,
    );
  }

  // Execute a friend action when online
  Future<bool> _executeFriendAction(OfflineAction action) async {
    try {
      final friendId = action.resourceId;

      switch (action.type) {
        case OfflineActionType.create:
          final name = action.payload['name'] as String;
          await _repository.addFriend(name);
          return true;

        case OfflineActionType.update:
          if (friendId == null) return false;
          if (action.payload['toggleFavorite'] == true) {
            await _repository.toggleFavorite(friendId);
          }
          return true;

        case OfflineActionType.delete:
          if (friendId == null) return false;
          await _repository.removeFriend(friendId);
          return true;

        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error executing friend action: $e');
      return false;
    }
  }

  // Get friends list
  Future<List<Friend>> getFriends() async {
    return _repository.getFriends();
  }

  // Toggle favorite status with offline support
  Future<void> toggleFavorite(String friendId) async {
    try {
      if (_connectivityService.hasConnectivity) {
        // We're online, update directly
        await _repository.toggleFavorite(friendId);
      } else {
        // We're offline, queue the update for later
        final action = OfflineAction(
          type: OfflineActionType.update,
          resourceType: 'friends',
          resourceId: friendId,
          payload: {'toggleFavorite': true},
        );

        await _offlineQueueManager.enqueueAction(action);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Remove friend with offline support
  Future<void> removeFriend(String friendId) async {
    try {
      if (_connectivityService.hasConnectivity) {
        // We're online, update directly
        await _repository.removeFriend(friendId);
      } else {
        // We're offline, queue the update for later
        final action = OfflineAction(
          type: OfflineActionType.delete,
          resourceType: 'friends',
          resourceId: friendId,
          payload: {},
        );

        await _offlineQueueManager.enqueueAction(action);
      }
    } catch (e) {
      debugPrint('Error removing friend: $e');
      rethrow;
    }
  }

  // Add friend with offline support
  Future<Friend?> addFriend(String name) async {
    try {
      if (_connectivityService.hasConnectivity) {
        // We're online, update directly
        return await _repository.addFriend(name);
      } else {
        // We're offline, queue the update for later
        final newFriendId = const Uuid().v4();
        final action = OfflineAction(
          type: OfflineActionType.create,
          resourceType: 'friends',
          resourceId: newFriendId,
          payload: {'name': name},
        );

        await _offlineQueueManager.enqueueAction(action);

        // Return an optimistic friend object
        return Friend(
          id: newFriendId,
          name: name,
          isFavorite: false,
        );
      }
    } catch (e) {
      debugPrint('Error adding friend: $e');
      rethrow;
    }
  }
}

// Provider for friends controller
final friendsControllerProvider = Provider<FriendsController>((ref) {
  final repository = ref.watch(friendRepositoryProvider);
  final offlineQueueManager = ref.watch(offlineQueueManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return FriendsController(
    repository: repository,
    offlineQueueManager: offlineQueueManager,
    connectivityService: connectivityService,
  );
});

/// Friends list example page with offline support
class FriendsListExample extends ConsumerStatefulWidget {
  const FriendsListExample({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsListExample> createState() => _FriendsListExampleState();
}

class _FriendsListExampleState extends ConsumerState<FriendsListExample> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addFriend() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final controller = ref.read(friendsControllerProvider);
      await controller.addFriend(name);
      _nameController.clear();
      ref.invalidate(friendsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding friend: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final pendingActions = ref.watch(pendingOfflineActionsProvider);

    // Check if there are pending friend actions
    final hasFriendPendingActions = pendingActions.any(
      (action) => action.resourceType == 'friends',
    );

    final isOffline = connectivityStatus.maybeWhen(
      data: (result) => result.name == 'none',
      orElse: () => true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          if (hasFriendPendingActions)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: PendingActionBadge(
                  isPending: true,
                  size: 10,
                  color: isOffline ? Colors.red : Colors.orange,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Add friend form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Friend Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addFriend,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          // Offline indicator
          if (isOffline)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Changes will be saved when you reconnect.',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Friends list
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                // Use OptimisticListBuilder to handle pending actions
                return OptimisticListBuilder<Friend>(
                  resourceType: 'friends',
                  remoteItems: friends,
                  itemIdExtractor: (friend) => friend.id,
                  createItemBuilder: (action) {
                    final payload = action.payload;
                    return Friend(
                      id: action.resourceId!,
                      name: payload['name'] as String,
                      isFavorite: false,
                    );
                  },
                  updateItemBuilder: (currentItem, action) {
                    if (action.payload['toggleFavorite'] == true) {
                      return currentItem.copyWith(
                        isFavorite: !currentItem.isFavorite,
                      );
                    }
                    return currentItem;
                  },
                  builder: (context, displayItems, pendingItemIds) {
                    if (displayItems.isEmpty) {
                      return const Center(
                        child: Text('No friends yet'),
                      );
                    }

                    return ListView.builder(
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final friend = displayItems[index];
                        final isPending = pendingItemIds.contains(friend.id);

                        return _buildFriendItem(friend, isPending);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Friend friend, bool isPending) {
    final controller = ref.read(friendsControllerProvider);
    
    return PendingActionShimmer(
      isPending: isPending,
      color: Colors.white,
      opacity: 0.2,
      child: Dismissible(
        key: Key(friend.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) async {
          try {
            await controller.removeFriend(friend.id);
            ref.invalidate(friendsProvider);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error removing friend: $e')),
              );
            }
          }
        },
        child: ListTile(
          leading: CircleAvatar(
            child: Text(friend.name[0]),
          ),
          title: Row(
            children: [
              Expanded(child: Text(friend.name)),
              if (isPending)
                const Icon(
                  Icons.sync,
                  size: 16,
                  color: Colors.orange,
                ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              friend.isFavorite ? Icons.star : Icons.star_border,
              color: friend.isFavorite ? Colors.amber : null,
            ),
            onPressed: () async {
              try {
                await controller.toggleFavorite(friend.id);
                ref.invalidate(friendsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error toggling favorite: $e')),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }
} 