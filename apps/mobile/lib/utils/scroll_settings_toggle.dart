import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/core/ui/scroll_settings.dart';
import 'package:flutter/services.dart';

/// A widget that displays a toggle for scroll behavior
class ScrollSettingsToggle extends ConsumerWidget {
  /// Constructor
  const ScrollSettingsToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollMode = ref.watch(scrollModeProvider);
    final isBounceModeActive = scrollMode == ScrollBounceMode.bounce;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(scrollModeProvider.notifier).state = isBounceModeActive
            ? ScrollBounceMode.noBounce
            : ScrollBounceMode.bounce;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBounceModeActive ? Icons.waves : Icons.waves_outlined,
              color: isBounceModeActive ? AppColors.gold : AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isBounceModeActive ? 'Bounce Enabled' : 'Bounce Disabled',
              style: TextStyle(
                color: isBounceModeActive ? AppColors.gold : AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
