import 'package:flutter/material.dart';
import 'package:hive_ui/features/messaging/domain/entities/message_attachment.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_attachment_preview.dart';

/// Widget to display multiple attachments in a message
class MessageAttachments extends StatelessWidget {
  final List<MessageAttachment> attachments;
  final Function(MessageAttachment) onAttachmentTap;
  
  const MessageAttachments({
    Key? key,
    required this.attachments,
    required this.onAttachmentTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Single attachment
    if (attachments.length == 1) {
      return _buildSingleAttachment(attachments.first);
    }
    
    // Multiple attachments
    return _buildMultipleAttachments();
  }
  
  Widget _buildSingleAttachment(MessageAttachment attachment) {
    return MessageAttachmentPreview(
      url: attachment.url,
      type: attachment.type,
      caption: attachment.caption,
      onTap: () => onAttachmentTap(attachment),
      maxWidth: 250,
      maxHeight: 200,
    );
  }
  
  Widget _buildMultipleAttachments() {
    // For multiple attachments, use a grid layout
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: attachments.map((attachment) {
            // Calculate width based on number of attachments
            double width = attachments.length >= 3 ? (maxWidth / 3) - 8 : (maxWidth / 2) - 8;
            width = width.clamp(80.0, 150.0);
            
            return MessageAttachmentPreview(
              url: attachment.url,
              type: attachment.type,
              caption: null, // Don't show captions in grid mode
              onTap: () => onAttachmentTap(attachment),
              maxWidth: width,
              maxHeight: width, // Make it square
            );
          }).toList(),
        );
      }
    );
  }
} 
 
 