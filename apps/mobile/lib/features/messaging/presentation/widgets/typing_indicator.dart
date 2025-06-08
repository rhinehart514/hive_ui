import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays typing indicators in a chat
class TypingIndicator extends ConsumerWidget {
  final String chatId;

  const TypingIndicator({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the typing status stream for this chat
    final typingStreamAsync = ref.watch(typingIndicatorsProvider(chatId));
    
    // Watch the participants in this chat
    final participantsAsync = ref.watch(chatParticipantsProvider(chatId));
    
    // Extract current user ID to exclude it from typing indicators
    final currentUserId = ref.watch(currentUserIdProvider);
    
    return typingStreamAsync.when(
      data: (typingUsers) {
        // Filter out the current user and users who are not typing
        final typingUserIds = typingUsers.entries
            .where((entry) => 
                entry.key != currentUserId && 
                DateTime.now().difference(entry.value).inSeconds < 6) // Only show recent typing
            .map((e) => e.key)
            .toList();
        
        if (typingUserIds.isEmpty) {
          return const SizedBox.shrink(); // No one is typing
        }
        
        return participantsAsync.when(
          data: (participants) {
            // Get the names of users who are typing
            final typingNames = _getTypingUserNames(participants, typingUserIds);
        return _buildTypingIndicator(context, typingNames);
          },
          loading: () => _buildLoadingIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => _buildLoadingIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Creates a typing message based on which users are typing
  String _getTypingUserNames(List<ChatUser> participants, List<String> typingUserIds) {
    // Get participant map by ID for quick lookup
    final participantMap = {for (var p in participants) p.id: p};
    
    // Get names of typing users
    final typingNames = typingUserIds
        .where((id) => participantMap.containsKey(id))
        .map((id) => participantMap[id]!.name.split(' ').first) // Use first names only
        .toList();
    
    if (typingNames.isEmpty) {
      return '';
    } else if (typingNames.length == 1) {
      return '${typingNames[0]} is typing...';
    } else if (typingNames.length == 2) {
      return '${typingNames[0]} and ${typingNames[1]} are typing...';
    } else {
      return '${typingNames.length} people are typing...';
    }
  }
  
  /// Builds the typing indicator widget with animation
  Widget _buildTypingIndicator(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedDots(),
        const SizedBox(width: 8),
        Text(
          text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
        ),
      ],
      ),
    );
  }

  /// Builds the animated dots for the typing indicator
  Widget _buildAnimatedDots() {
    return SizedBox(
      width: 24,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAnimatedDot(0),
          _buildAnimatedDot(1),
          _buildAnimatedDot(2),
        ],
      ),
    );
  }
  
  /// Builds a single animated dot with a delay based on index
  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // Apply a delay based on the index
        final delayedValue = (value + (index * 0.3)) % 1.0;
        
        // Calculate size and opacity for animation
        final size = 3.0 + (delayedValue * 1.5);
        final opacity = 0.3 + (delayedValue * 0.7);
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
  
  /// Builds a loading indicator
  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 12,
      child: Center(
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final double delay;

  const _AnimatedDot({required this.delay});

  @override
  _AnimatedDotState createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay, widget.delay + 0.6, curve: Curves.easeOut),
      ),
    )..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.5 + _animation.value * 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
} 