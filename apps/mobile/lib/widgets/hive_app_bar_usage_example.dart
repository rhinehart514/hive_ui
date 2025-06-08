import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';

/// Example showing how to use the HiveAppBar in different scenarios
class HiveAppBarExamples extends ConsumerStatefulWidget {
  const HiveAppBarExamples({super.key});

  @override
  ConsumerState<HiveAppBarExamples> createState() => _HiveAppBarExamplesState();
}

class _HiveAppBarExamplesState extends ConsumerState<HiveAppBarExamples> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              const SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'HiveAppBar Examples',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
          body: ListView(
            children: [
              // Standard App Bar Example
              _buildExampleSection(
                title: 'Standard App Bar',
                example: HiveAppBar(
                  title: 'My Profile',
                  showBackButton: true,
                  actions: [
                    IconButton(
                      icon: const Icon(HugeIcons.settings, color: AppColors.white),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
              
              // App Bar with Subtitle
              _buildExampleSection(
                title: 'App Bar with Subtitle',
                example: HiveAppBar(
                  title: 'Spaces',
                  subtitle: 'Discover communities',
                  showBackButton: false,
                  actions: [
                    IconButton(
                      icon: const Icon(HugeIcons.message, color: AppColors.white),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
              
              // App Bar with Tabs
              _buildExampleSection(
                title: 'App Bar with Tabs',
                example: HiveAppBar(
                  title: 'Events',
                  style: HiveAppBarStyle.withTabs,
                  tabBar: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textTertiary,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                      Tab(text: 'My Events'),
                    ],
                  ),
                ),
              ),
              
              // App Bar with Search
              _buildExampleSection(
                title: 'App Bar with Search',
                example: HiveAppBar(
                  title: 'Discover',
                  style: HiveAppBarStyle.withSearch,
                  showSearchButton: true,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: (query) {
                    // Handle search query
                    print('Search query: $query');
                  },
                ),
              ),
              
              // App Bar with Tabs and Search
              _buildExampleSection(
                title: 'App Bar with Tabs and Search',
                example: HiveAppBar(
                  title: 'Explore',
                  style: HiveAppBarStyle.withTabsAndSearch,
                  showSearchButton: true,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchChanged: (query) {
                    // Handle search query
                    print('Search query: $query');
                  },
                  tabBar: const TabBar(
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textTertiary,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Trending'),
                      Tab(text: 'Following'),
                      Tab(text: 'Popular'),
                      Tab(text: 'New'),
                    ],
                  ),
                ),
              ),
              
              // Scrollable App Bar
              _buildExampleSection(
                title: 'Scrollable App Bar',
                example: HiveAppBar(
                  title: 'Feed',
                  scrollable: true,
                  scrollController: _scrollController,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
              
              // Transparent App Bar
              _buildExampleSection(
                title: 'Transparent App Bar',
                containerColor: AppColors.gold.withOpacity(0.2),
                example: const HiveAppBar(
                  title: 'Photo View',
                  style: HiveAppBarStyle.transparent,
                  showBottomBorder: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildExampleSection({
    required String title,
    required Widget example,
    Color containerColor = AppColors.cardBackground,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: example,
          ),
        ],
      ),
    );
  }
} 