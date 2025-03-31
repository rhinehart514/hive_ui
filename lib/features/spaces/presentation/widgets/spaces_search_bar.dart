import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';

class SpacesSearchBar extends ConsumerWidget {
  final VoidCallback onSearchClosed;
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const SpacesSearchBar({
    Key? key,
    required this.onSearchClosed,
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearching ? 60 : 0,
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: isSearching
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search all spaces by ID, name, or tags...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          // Update the search query in the provider
                          ref.read(spaceSearchQueryProvider.notifier).state = value;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gold),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      searchController.clear();
                      ref.read(spaceSearchQueryProvider.notifier).state = '';
                      onSearchClosed();
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
