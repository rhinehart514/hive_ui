import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/theme/app_colors.dart'; // Use actual import
// import 'package:hive_ui/core/theme/spacing.dart'; // Placeholder
// import 'package:hive_ui/core/widgets/cached_network_image_wrapper.dart'; // Assume this exists
// import 'package:hive_ui/widgets/common/shimmer_widget.dart'; // Assume this exists
import '../../domain/entities/space_details.dart';
import '../../state/space_providers.dart';
import 'join_leave_button.dart';

// --- Placeholders removed ---

class SpaceSliverHeader extends ConsumerWidget {
  final String spaceId;

  const SpaceSliverHeader({required this.spaceId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(spaceDetailsProvider(spaceId));
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.secondaryBackground, // Use theme color #1E1E1E
      elevation: 2, // Subtle elevation for pinned state
      surfaceTintColor: Colors.transparent, // Prevent material 3 tint
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.white),
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 8.0, // TODO: Replace with Spacing.xs
      title: detailsAsync.when(
        data: (details) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional: Avatar - commented out due to placeholder issues
            // CircleAvatar(
            //   radius: 16,
            //   backgroundColor: AppColors.textSecondary.withOpacity(0.2),
            //   //backgroundImage: NetworkImage(details.avatarUrl ?? ''), // Simple NetworkImage for placeholder
            // ),
            // const SizedBox(width: 12.0 /* Spacing.sm */),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    details.name,
                    style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), // H2/H3 equivalent
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${details.memberCount} Members', // Use actual count
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), // Small
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => Row(
           mainAxisSize: MainAxisSize.min,
           children: [
              // ShimmerAvatar(radius: 16), // Corresponds to commented-out avatar
              // const SizedBox(width: 12.0 /* Spacing.sm */),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Use placeholder shimmer for now
                    _ShimmerWidget.text(width: 120, height: 16),
                    const SizedBox(height: 4.0 /* Spacing.xs / 2 */),
                    _ShimmerWidget.text(width: 80, height: 12),
                  ],
                ),
              )
           ]
        ),
        error: (error, stack) => Text(
          'Space', // Fallback title
          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ), // Graceful error handling for title
      ),
      actions: [
        detailsAsync.maybeWhen(
          data: (_) => Padding(
            padding: const EdgeInsets.only(right: 16.0 /* Spacing.md */),
            child: JoinLeaveButton(spaceId: spaceId),
          ),
          orElse: () => const SizedBox.shrink(), // Don't show button if details failed
        ),
      ],
      // Optional FlexibleSpaceBar for larger header / banner
      // flexibleSpace: FlexibleSpaceBar(...),
    );
  }
}

// --- Placeholder Shimmer Widget (Local copy) --- TODO: Replace with actual implementations
class _ShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shapeBorder;

  const _ShimmerWidget._({this.width, this.height, required this.shapeBorder, Key? key}) : super(key: key);

  const factory _ShimmerWidget.text({required double width, required double height, Key? key}) = _ShimmerText;
  const factory _ShimmerWidget.rectangular({double? width, double? height, Key? key}) = _ShimmerRect;
  const factory _ShimmerWidget.circular({required double diameter, Key? key}) = _ShimmerCircle;

  @override
  Widget build(BuildContext context) {
    // Basic grey box placeholder, replace with actual shimmer effect later
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: Colors.grey[700]!, // Darker grey for dark theme
        shape: shapeBorder,
      ),
    );
  }
}

class _ShimmerText extends _ShimmerWidget {
  const _ShimmerText({required double width, required double height, Key? key})
      : super._(width: width, height: height, shapeBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))), key: key);
}

class _ShimmerRect extends _ShimmerWidget {
  const _ShimmerRect({double? width, double? height, Key? key})
      : super._(width: width, height: height, shapeBorder: const RoundedRectangleBorder(), key: key);
}

class _ShimmerCircle extends _ShimmerWidget {
  const _ShimmerCircle({required double diameter, Key? key})
      : super._(width: diameter, height: diameter, shapeBorder: const CircleBorder(), key: key);
}
// --- End Placeholder Widgets --- 