import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';

/// A mobile-friendly menu for event actions
class EventActionMenu extends StatelessWidget {
  /// The event to display actions for
  final Event event;
  
  /// Callback when the edit option is selected
  final VoidCallback? onEditTap;
  
  /// Callback when the cancel option is selected
  final VoidCallback? onCancelTap;
  
  /// Callback when the share option is selected
  final VoidCallback? onShareTap;
  
  /// Callback when the report option is selected
  final VoidCallback? onReportTap;
  
  /// Whether the event is owned by the current user
  final bool isEventOwner;
  
  /// Whether the event is canceled
  final bool isCanceled;

  /// Constructor
  const EventActionMenu({
    Key? key,
    required this.event,
    this.onEditTap,
    this.onCancelTap,
    this.onShareTap,
    this.onReportTap,
    this.isEventOwner = false,
    this.isCanceled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Event Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            if (isEventOwner && !isCanceled) ...[
              _buildActionTile(
                icon: Icons.edit,
                title: 'Edit Event',
                onTap: onEditTap,
                isDestructive: false,
              ),
              _buildActionTile(
                icon: Icons.cancel,
                title: 'Cancel Event',
                onTap: onCancelTap,
                isDestructive: true,
              ),
              const Divider(color: AppColors.divider, height: 1),
            ],
            _buildActionTile(
              icon: Icons.share,
              title: 'Share Event',
              onTap: onShareTap,
              isDestructive: false,
            ),
            if (!isEventOwner) 
              _buildActionTile(
                icon: Icons.flag,
                title: 'Report',
                onTap: onReportTap,
                isDestructive: true,
              ),
            const SizedBox(height: 10),
            SafeArea(
              top: false,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    required bool isDestructive,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : Colors.white,
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
    );
  }
  
  /// Helper method to show this menu as a modal bottom sheet
  static void show({
    required BuildContext context,
    required Event event,
    VoidCallback? onEditTap,
    VoidCallback? onCancelTap,
    VoidCallback? onShareTap,
    VoidCallback? onReportTap,
    bool isEventOwner = false,
    bool isCanceled = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EventActionMenu(
        event: event,
        onEditTap: onEditTap != null
            ? () {
                Navigator.pop(context);
                onEditTap();
              }
            : null,
        onCancelTap: onCancelTap != null
            ? () {
                Navigator.pop(context);
                onCancelTap();
              }
            : null,
        onShareTap: onShareTap != null
            ? () {
                Navigator.pop(context);
                onShareTap();
              }
            : null,
        onReportTap: onReportTap != null
            ? () {
                Navigator.pop(context);
                onReportTap();
              }
            : null,
        isEventOwner: isEventOwner,
        isCanceled: isCanceled,
      ),
    );
  }
} 