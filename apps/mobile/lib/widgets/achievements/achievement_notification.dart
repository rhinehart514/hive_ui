import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_achievement.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A controller for showing achievement notifications
class AchievementNotificationController {
  /// OverlayEntry for the notification
  OverlayEntry? _overlayEntry;

  /// Animation controller for notification animations
  final AnimationController animationController;

  /// Whether a notification is currently being shown
  bool get isShowingNotification => _overlayEntry != null;

  AchievementNotificationController({
    required this.animationController,
  });

  /// Show a notification for achievement progress update
  void showProgressUpdate(BuildContext context, UserAchievement achievement) {
    _removeCurrentOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => AchievementProgressNotification(
        achievement: achievement,
        animationController: animationController,
        onDismiss: _removeCurrentOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    animationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        _removeCurrentOverlay();
      });
    });
  }

  /// Show a notification for achievement completion
  void showCompletionNotification(
      BuildContext context, UserAchievement achievement) {
    _removeCurrentOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => AchievementCompletionNotification(
        achievement: achievement,
        animationController: animationController,
        onDismiss: _removeCurrentOverlay,
      ),
    );

    // Play haptic feedback for completed achievement
    HapticFeedback.heavyImpact();

    Overlay.of(context).insert(_overlayEntry!);
    animationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 5), () {
        _removeCurrentOverlay();
      });
    });
  }

  /// Remove any currently showing notification
  void _removeCurrentOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      animationController.reset();
    }
  }

  /// Dispose the controller
  void dispose() {
    _removeCurrentOverlay();
  }
}

/// Widget for displaying a progress update notification
class AchievementProgressNotification extends StatelessWidget {
  /// The achievement being updated
  final UserAchievement achievement;

  /// Animation controller for the notification animation
  final AnimationController animationController;

  /// Callback to dismiss the notification
  final VoidCallback onDismiss;

  const AchievementProgressNotification({
    super.key,
    required this.achievement,
    required this.animationController,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animationController,
            curve: Curves.elasticOut,
          )),
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: achievement.typeColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    achievement.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Progress Update',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${achievement.title}: ${achievement.progressCurrent}/${achievement.progressTotal}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying an achievement completion notification
class AchievementCompletionNotification extends StatelessWidget {
  /// The achievement that was completed
  final UserAchievement achievement;

  /// Animation controller for the notification animation
  final AnimationController animationController;

  /// Callback to dismiss the notification
  final VoidCallback onDismiss;

  const AchievementCompletionNotification({
    super.key,
    required this.achievement,
    required this.animationController,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animationController,
            curve: Curves.elasticOut,
          ),
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        achievement.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Achievement Unlocked!',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          achievement.description,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
