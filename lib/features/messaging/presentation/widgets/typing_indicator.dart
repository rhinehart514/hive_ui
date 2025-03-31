import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays typing indicators for a chat
class TypingIndicator extends ConsumerWidget {
  final String chatId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String currentUserId;
  final TextStyle? textStyle;

  const TypingIndicator({
    Key? key,
    required this.chatId,
    required this.participantIds,
    required this.participantNames,
    required this.currentUserId,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch typing indicators stream
    final typingAsync = ref.watch(typingIndicatorsProvider(chatId));
    
    return typingAsync.when(
      data: (typingUsers) {
        // Filter out current user and get only users who are typing
        final typingUserIds = typingUsers.keys
            .where((id) => id != currentUserId)
            .toList();
        
        if (typingUserIds.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Get names of typing users
        final typingNames = <String>[];
        for (final userId in typingUserIds) {
          final name = participantNames[userId] ?? 'Someone';
          typingNames.add(name);
        }
        
        return _buildTypingIndicator(context, typingNames);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTypingIndicator(BuildContext context, List<String> typingNames) {
    final baseStyle = textStyle ?? 
        const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic);
    
    String text;
    if (typingNames.length == 1) {
      text = '${typingNames.first} is typing...';
    } else if (typingNames.length == 2) {
      text = '${typingNames.join(' and ')} are typing...';
    } else {
      text = 'Several people are typing...';
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedDots(),
        const SizedBox(width: 8),
        Text(
          text,
          style: baseStyle,
        ),
      ],
    );
  }

  Widget _buildAnimatedDots() {
    return SizedBox(
      width: 24,
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AnimatedDot(delay: 0),
          _AnimatedDot(delay: 0.2),
          _AnimatedDot(delay: 0.4),
        ],
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