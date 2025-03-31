import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider to track notification settings for events
final eventNotificationsProvider =
    StateNotifierProvider<EventNotificationsNotifier, Map<String, bool>>((ref) {
  return EventNotificationsNotifier();
});

/// Notifier for managing event notification preferences
class EventNotificationsNotifier extends StateNotifier<Map<String, bool>> {
  EventNotificationsNotifier() : super({});

  /// Toggle notification for an event
  void toggleNotification(String eventId) {
    state = {
      ...state,
      eventId: !(state[eventId] ?? false),
    };

    // TODO: Implement actual notification setup with backend
  }

  /// Check if notifications are enabled for an event
  bool isNotificationEnabled(String eventId) {
    return state[eventId] ?? false;
  }
}

/// A widget for toggling event notifications
class NotificationBellToggle extends ConsumerWidget {
  /// The ID of the event
  final String eventId;

  /// Optional tooltip text
  final String? tooltipText;

  /// Creates a notification bell toggle
  const NotificationBellToggle({
    super.key,
    required this.eventId,
    this.tooltipText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(eventNotificationsProvider);
    final isEnabled = notificationsState[eventId] ?? false;

    return Tooltip(
      message:
          tooltipText ?? (isEnabled ? 'Notifications on' : 'Notifications off'),
      textStyle: GoogleFonts.inter(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: () {
            // Apply appropriate haptic feedback
            if (isEnabled) {
              HapticFeedback.lightImpact();
            } else {
              HapticFeedback.mediumImpact();
            }
            ref
                .read(eventNotificationsProvider.notifier)
                .toggleNotification(eventId);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.gold.withOpacity(0.1) : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isEnabled ? AppColors.gold : Colors.white.withOpacity(0.3),
                width: isEnabled ? 1.5 : 1.0,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                key: ValueKey<bool>(isEnabled),
                color:
                    isEnabled ? AppColors.gold : Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
