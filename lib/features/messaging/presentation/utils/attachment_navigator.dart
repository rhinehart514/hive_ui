import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/async_navigation_service.dart';
import 'package:hive_ui/features/messaging/domain/entities/message_attachment.dart';
import 'package:hive_ui/features/messaging/presentation/screens/attachment_viewer_screen.dart';

/// Utility class for navigating to attachment viewer
/// Updated to use AsyncNavigationService for safe navigation across async gaps
class AttachmentNavigator {
  /// Navigate to attachment viewer with a single attachment using BuildContext
  /// Use this method when BuildContext is readily available
  static Future<void> viewAttachmentWithContext(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    context.asyncNavigation.push(
      '/messaging/attachment_viewer',
      extra: {
        'attachment': attachment,
      },
    );
  }
  
  /// Navigate to attachment viewer with a single attachment using WidgetRef
  /// Safe to call across async gaps
  static void viewAttachment(
    WidgetRef ref,
    MessageAttachment attachment,
  ) {
    ref.read(asyncNavigationServiceProvider).push(
      '/messaging/attachment_viewer',
      extra: {
        'attachment': attachment,
      },
    );
  }
  
  /// Navigate to attachment viewer with multiple attachments using BuildContext
  /// Use this method when BuildContext is readily available
  static Future<void> viewAttachmentsWithContext(
    BuildContext context,
    List<MessageAttachment> attachments,
    MessageAttachment selectedAttachment,
  ) async {
    context.asyncNavigation.push(
      '/messaging/attachment_viewer',
      extra: {
        'attachment': selectedAttachment,
        'allAttachments': attachments,
      },
    );
  }
  
  /// Navigate to attachment viewer with multiple attachments using WidgetRef
  /// Safe to call across async gaps
  static void viewAttachments(
    WidgetRef ref,
    List<MessageAttachment> attachments,
    MessageAttachment selectedAttachment,
  ) {
    ref.read(asyncNavigationServiceProvider).push(
      '/messaging/attachment_viewer',
      extra: {
        'attachment': selectedAttachment,
        'allAttachments': attachments,
      },
    );
  }
  
  /// Open attachment in appropriate viewer based on type using BuildContext
  /// Use this method when BuildContext is readily available
  static Future<void> openAttachmentWithContext(
    BuildContext context, {
    required MessageAttachment attachment,
    List<MessageAttachment>? allAttachments,
  }) async {
    if (allAttachments != null && allAttachments.isNotEmpty) {
      viewAttachmentsWithContext(context, allAttachments, attachment);
    } else {
      viewAttachmentWithContext(context, attachment);
    }
  }
  
  /// Open attachment in appropriate viewer based on type using WidgetRef
  /// Safe to call across async gaps
  static void openAttachment(
    WidgetRef ref, {
    required MessageAttachment attachment,
    List<MessageAttachment>? allAttachments,
  }) {
    if (allAttachments != null && allAttachments.isNotEmpty) {
      viewAttachments(ref, allAttachments, attachment);
    } else {
      viewAttachment(ref, attachment);
    }
  }
} 
 
 