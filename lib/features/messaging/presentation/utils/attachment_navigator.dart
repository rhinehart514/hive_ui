import 'package:flutter/material.dart';
import 'package:hive_ui/features/messaging/domain/entities/message_attachment.dart';
import 'package:hive_ui/features/messaging/presentation/screens/attachment_viewer_screen.dart';

/// Utility class for navigating to attachment viewer
class AttachmentNavigator {
  /// Navigate to attachment viewer with a single attachment
  static Future<void> viewAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AttachmentViewerScreen(
          attachment: attachment,
        ),
      ),
    );
  }
  
  /// Navigate to attachment viewer with multiple attachments
  static Future<void> viewAttachments(
    BuildContext context,
    List<MessageAttachment> attachments,
    MessageAttachment selectedAttachment,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AttachmentViewerScreen(
          attachment: selectedAttachment,
          allAttachments: attachments,
        ),
      ),
    );
  }
  
  /// Open attachment in appropriate viewer based on type
  static Future<void> openAttachment(
    BuildContext context, {
    required MessageAttachment attachment,
    List<MessageAttachment>? allAttachments,
  }) async {
    if (allAttachments != null && allAttachments.isNotEmpty) {
      await viewAttachments(context, allAttachments, attachment);
    } else {
      await viewAttachment(context, attachment);
    }
  }
} 
 
 