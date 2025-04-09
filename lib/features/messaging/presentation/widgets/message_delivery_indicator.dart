import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/data/services/realtime_messaging_service.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays the delivery status of a message (sent, delivered, read)
class MessageDeliveryIndicator extends ConsumerWidget {
  final String messageId;
  final String recipientId;
  final bool showLabel;
  final double? size;
  final Color? color;

  const MessageDeliveryIndicator({
    Key? key,
    required this.messageId,
    required this.recipientId,
    this.showLabel = false,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the delivery status
    final deliveryStatusAsync = ref.watch(messageDeliveryStatusProvider(messageId));
    
    return deliveryStatusAsync.when(
      data: (statusMap) {
        // Get status for this recipient
        final status = statusMap[recipientId] ?? MessageDeliveryStatus.sent;
        return _buildIndicator(context, status);
      },
      loading: () => const SizedBox(
        width: 12,
        height: 12,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildIndicator(BuildContext context, MessageDeliveryStatus status) {
    final iconSize = size ?? 14.0;
    final iconColor = color ?? AppColors.gold;
    
    // Define icon based on status
    IconData icon;
    String label;
    Color statusColor;
    
    switch (status) {
      case MessageDeliveryStatus.sent:
        icon = Icons.check;
        label = 'Sent';
        statusColor = Colors.grey;
        break;
      case MessageDeliveryStatus.delivered:
        icon = Icons.done_all;
        label = 'Delivered';
        statusColor = Colors.grey;
        break;
      case MessageDeliveryStatus.seen:
        icon = Icons.done_all;
        label = 'Read';
        statusColor = iconColor;
        break;
    }
    
    if (!showLabel) {
      return Icon(
        icon,
        size: iconSize,
        color: statusColor,
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
          ),
        ),
      ],
    );
  }
} 