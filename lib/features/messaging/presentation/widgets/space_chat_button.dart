import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/utils/messaging_initializer.dart';

class SpaceChatButton extends ConsumerWidget {
  final String spaceId;
  final String spaceName;

  const SpaceChatButton({
    Key? key,
    required this.spaceId,
    required this.spaceName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatUnlockedAsync = ref.watch(spaceChatAvailabilityProvider(spaceId));
    
    return chatUnlockedAsync.when(
      data: (isUnlocked) {
        if (isUnlocked) {
          return _buildUnlockedButton(context, ref);
        } else {
          return _buildLockedButton(context, ref);
        }
      },
      loading: () => _buildLoadingButton(),
      error: (error, stackTrace) => _buildErrorButton(error),
    );
  }

  Widget _buildUnlockedButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.chat),
      label: const Text('Chat'),
      onPressed: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // Get or create chat
          final chatAsync = await ref.read(
            spaceChatProvider(spaceId).future,
          );
          
          // Pop loading dialog
          if (context.mounted) {
            Navigator.pop(context);
          }
          
          // If chat is null, show error
          if (chatAsync == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to access chat'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          // Set current chat
          ref.read(currentChatIdProvider.notifier).state = chatAsync.id;
          
          // Navigate to chat using the new helper
          if (context.mounted) {
            navigateToChat(
              context, 
              chatAsync.id, 
              chatName: spaceName,
              isGroupChat: true
            );
          }
        } catch (e) {
          // Pop loading dialog
          if (context.mounted) {
            Navigator.pop(context);
            
            // Show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildLockedButton(BuildContext context, WidgetRef ref) {
    final membersNeededAsync = ref.watch(spaceChatMembersNeededProvider(spaceId));
    
    return membersNeededAsync.when(
      data: (membersNeeded) {
        return OutlinedButton.icon(
          icon: const Icon(Icons.lock),
          label: Text('Chat (need $membersNeeded more members)'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Chat will be unlocked when the space has 10 members. '
                  'Currently need $membersNeeded more members.',
                ),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        );
      },
      loading: () => _buildLoadingButton(),
      error: (error, stackTrace) => _buildErrorButton(error),
    );
  }

  Widget _buildLoadingButton() {
    return OutlinedButton.icon(
      icon: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: const Text('Loading...'),
      onPressed: null,
    );
  }

  Widget _buildErrorButton(Object error) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.error),
      label: const Text('Error'),
      onPressed: null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    );
  }
} 