import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/theme/app_colors.dart'; // Use actual import
// import 'package:hive_ui/core/theme/spacing.dart'; // Placeholder
// import 'package:hive_ui/widgets/common/shimmer_widget.dart'; // Placeholder
// import 'package:hive_ui/components/feed/event_card.dart'; // Assume exists
// import 'package:hive_ui/components/feed/post_card.dart'; // Assume exists
// import 'package:hive_ui/components/common/empty_state_widget.dart'; // Assume exists
// import 'package:hive_ui/components/common/error_state_widget.dart'; // Assume exists
import '../../state/space_providers.dart';

// --- Placeholders removed ---

// --- Placeholder Feed Item Card --- TODO: Replace with actual card imports
class _PlaceholderFeedCard extends StatelessWidget {
  final FeedItem item;
  const _PlaceholderFeedCard({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondaryBackground, // #1E1E1E
      margin: const EdgeInsets.only(bottom: 16.0 /* Spacing.md */),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0 /* Spacing.md */),
        child: Text(
          '${item.type.toUpperCase()}: ${item.title}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
// --- End Placeholder Card ---

// --- Placeholder State Widgets --- TODO: Replace with actual imports
class _EmptyStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onActionPressed;
  final String? actionText;
  const _EmptyStateWidget({
    required this.message,
    this.onActionPressed,
    this.actionText,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0 /* Spacing.lg */),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            if (onActionPressed != null && actionText != null)
              const SizedBox(height: 16.0 /* Spacing.md */),
            if (onActionPressed != null && actionText != null)
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold), // Use actual accent
                child: Text(actionText!),
              )
          ],
        ),
      ),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorStateWidget({required this.message, required this.onRetry, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0 /* Spacing.lg */),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48), // Use actual error color
            const SizedBox(height: 16.0 /* Spacing.md */),
            Text(message, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.error), textAlign: TextAlign.center),
            const SizedBox(height: 16.0 /* Spacing.md */),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}
// --- End Placeholder State Widgets ---

// --- Placeholder Shimmer Widget --- TODO: Replace with actual implementation
class _ShimmerWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shapeBorder;

  const _ShimmerWidget._({this.width, this.height, required this.shapeBorder, Key? key}) : super(key: key);

  const factory _ShimmerWidget.rectangular({double? width, double? height, Key? key}) = _ShimmerRect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 16.0 /* Spacing.md */),
      decoration: ShapeDecoration(
        color: AppColors.darkGray, // Use dark gray for shimmer base
        shape: shapeBorder,
      ),
      // TODO: Add actual shimmer effect animation
    );
  }
}
class _ShimmerRect extends _ShimmerWidget {
  const _ShimmerRect({double? width, double? height, Key? key})
      : super._(width: width, height: height, shapeBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))), key: key);
}
// --- End Placeholder Shimmer ---


class SpaceContentFeed extends ConsumerWidget {
  final String spaceId;

  const SpaceContentFeed({required this.spaceId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(spaceFeedProvider(spaceId));
    final canCreate = ref.watch(spaceMembershipProvider(spaceId).select((s) => s.canCreateEvents));

    // TODO: Replace hardcoded spacing values with theme constants once available
    const double horizontalPadding = 16.0; // Spacing.md
    const double verticalPadding = 16.0;   // Spacing.md

    return feedAsync.when(
      data: (items) {
        if (items.isEmpty) {
          // TODO: Pass actual create event navigation logic
          VoidCallback? createAction = canCreate ? () => print("Trigger create event") : null;
          return SliverFillRemaining(
            hasScrollBody: false, // Important for placing content in viewport
            child: _EmptyStateWidget(
              message: 'This Space is quiet...\nBe the first to create something!',
              actionText: canCreate ? 'Create Event' : null,
              onActionPressed: createAction,
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // TODO: Replace with actual Card Widgets based on item.type
              // if (item.type == 'event') return EventCard(event: item as EventModel);
              // if (item.type == 'post') return PostCard(post: item as PostModel);
              return _PlaceholderFeedCard(item: item);
            },
          ),
        );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => const _ShimmerWidget.rectangular(height: 150),
            childCount: 5, // Show 5 shimmer items
          ),
        ),
      ),
      error: (error, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorStateWidget(
          message: 'Failed to load Space feed: ${error.toString()}',
          onRetry: () => ref.refresh(spaceFeedProvider(spaceId)),
        ),
      ),
    );
  }
} 