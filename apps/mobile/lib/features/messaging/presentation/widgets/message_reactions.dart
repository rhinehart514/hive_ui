import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget for displaying message reactions
class MessageReactions extends ConsumerWidget {
  final String chatId;
  final String messageId;
  final List<MessageReaction>? reactions;
  
  const MessageReactions({
    Key? key,
    required this.chatId,
    required this.messageId,
    this.reactions,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only build if there are reactions to display
    if (reactions == null || reactions!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Group reactions by emoji
    final reactionsByEmoji = _groupReactionsByEmoji();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionsByEmoji.entries.map((entry) => 
          _buildReactionBubble(entry.key, entry.value, ref)).toList(),
      ),
    );
  }
  
  /// Groups reactions by emoji
  Map<String, List<MessageReaction>> _groupReactionsByEmoji() {
    final groupedReactions = <String, List<MessageReaction>>{};
    
    for (final reaction in reactions!) {
      if (!groupedReactions.containsKey(reaction.emoji)) {
        groupedReactions[reaction.emoji] = [];
      }
      groupedReactions[reaction.emoji]!.add(reaction);
    }
    
    return groupedReactions;
  }
  
  /// Builds a reaction bubble with count
  Widget _buildReactionBubble(String emoji, List<MessageReaction> reactions, WidgetRef ref) {
    // Get current user ID
    final currentUserId = ref.watch(currentUserIdProvider);
    
    // Check if current user has already reacted with this emoji
    final hasReacted = currentUserId != null && 
                      reactions.any((r) => r.userId == currentUserId);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasReacted 
          ? AppColors.gold.withOpacity(0.2) 
          : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasReacted ? AppColors.gold : Colors.grey.shade700, 
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '${reactions.length}',
            style: TextStyle(
              fontSize: 12, 
              color: hasReacted ? AppColors.gold : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
} 
 
 