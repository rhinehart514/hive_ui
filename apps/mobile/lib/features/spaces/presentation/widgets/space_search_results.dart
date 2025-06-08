import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';

class SpaceSearchResults extends ConsumerWidget {
  const SpaceSearchResults({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchActive = ref.watch(spaceSearchActiveProvider);
    final searchQuery = ref.watch(spaceSearchQueryProvider);
    
    if (!searchActive || searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final searchResultsAsync = ref.watch(searchedSpacesProvider);
    
    return Container(
      color: AppColors.black.withOpacity(0.95),
      child: searchResultsAsync.when(
        data: (spaces) => _buildResultsList(context, spaces),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error searching spaces: $error',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultsList(BuildContext context, List<Space> spaces) {
    if (spaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                color: AppColors.gold,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No spaces found',
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: spaces.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final space = spaces[index];
        return _buildSpaceListItem(context, space);
      },
    );
  }
  
  Widget _buildSpaceListItem(BuildContext context, Space space) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        
        // Navigate to the space
        GoRouter.of(context).push(
          AppRoutes.getSpaceViewPath(space.id),
          extra: {'space': space},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Space image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: space.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: space.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.group,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: AppColors.gold,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.black.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.group,
                          color: AppColors.gold,
                          size: 24,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Space details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    space.description,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${space.metrics.memberCount} members',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 