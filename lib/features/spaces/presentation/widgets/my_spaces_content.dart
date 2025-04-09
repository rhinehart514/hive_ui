import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_card.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_empty_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_error_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_loading_state.dart';

/// Widget that displays the spaces a user has joined
class MySpacesContent extends ConsumerWidget {
  /// Constructor
  const MySpacesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedSpacesAsync = ref.watch(joinedSpacesProvider);

    return joinedSpacesAsync.when(
      loading: () => const SpacesLoadingState(),
      error: (err, stack) => SpacesErrorState(error: err.toString()),
      data: (spaces) {
        if (spaces.isEmpty) {
          return const SpacesEmptyState(
            message: 'You haven\'t joined any spaces yet',
            subMessage: 'Discover spaces to join and connect with other members',
            icon: Icons.group_outlined,
          );
        }

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Your Spaces',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final space = spaces[index];
                    return SpaceCard(
                      space: space,
                      onTap: () {
                        // Navigate to space details
                        Navigator.of(context).pushNamed(
                          '/spaces/${space.id}',
                          arguments: {'spaceId': space.id},
                        );
                      },
                    );
                  },
                  childCount: spaces.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
        );
      },
    );
  }
}
