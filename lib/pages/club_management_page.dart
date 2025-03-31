import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/theme/huge_icons.dart';

@RoutePage()
class ClubManagementPage extends ConsumerStatefulWidget {
  final Club club;

  const ClubManagementPage({
    super.key,
    required this.club,
  });

  @override
  ConsumerState<ClubManagementPage> createState() => _ClubManagementPageState();
}

class _ClubManagementPageState extends ConsumerState<ClubManagementPage> {
  int _selectedIndex = 0;

  final List<String> _tabs = [
    'Overview',
    'Events',
    'Members',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom app bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF212121),
                          AppColors.black,
                        ],
                      ),
                    ),
                  ),

                  // Gold overlay pattern for premium feel
                  Opacity(
                    opacity: 0.05,
                    child: Image.asset(
                      'assets/images/pattern.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildClubLogo(),
                        const SizedBox(height: 8),
                        Text(
                          widget.club.name,
                          style: AppTheme.displayMedium,
                        ),
                        Text(
                          'Management Dashboard',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                isScrollable: true,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                indicatorColor: AppColors.gold,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ),

          // Content based on selected tab
          SliverToBoxAdapter(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildClubLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getClubColor().withOpacity(0.2),
        border: Border.all(
          color: _getClubColor(),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          _getClubIcon(),
          color: _getClubColor(),
          size: 30,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildEventsTab();
      case 2:
        return _buildMembersTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildManagementCard(
            title: 'Upcoming Club Events',
            icon: HugeIcons.calendar,
            value: '3',
            label: 'events this week',
            color: AppColors.gold,
            onTap: () {
              setState(() => _selectedIndex = 1);
              HapticFeedback.mediumImpact();
            },
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            title: 'Member Requests',
            icon: HugeIcons.profile,
            value: '5',
            label: 'pending approvals',
            color: AppColors.gold.withOpacity(0.8),
            onTap: () {
              setState(() => _selectedIndex = 2);
              HapticFeedback.mediumImpact();
            },
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            title: 'Club Settings',
            icon: HugeIcons.settings,
            value: '',
            label: 'Update club information',
            color: AppColors.gold.withOpacity(0.6),
            onTap: () {
              setState(() => _selectedIndex = 3);
              HapticFeedback.mediumImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.white.withOpacity(0.05),
              blurRadius: 10,
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Club Stats',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Members', widget.club.memberCount.toString(),
                  HugeIcons.profile),
              _buildStatItem('Events', widget.club.eventCount.toString(),
                  HugeIcons.calendar),
              _buildStatItem('Engagement', '89%', Icons.favorite),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.gold,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.displaySmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? label : '$value $label',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder for Events tab
  Widget _buildEventsTab() {
    return Center(
        child: Text(
      'Events Management Coming Soon',
      style: AppTheme.bodyLarge,
    ));
  }

  // Placeholder for Members tab
  Widget _buildMembersTab() {
    return Center(
        child: Text(
      'Member Management Coming Soon',
      style: AppTheme.bodyLarge,
    ));
  }

  // Placeholder for Settings tab
  Widget _buildSettingsTab() {
    return Center(
        child: Text(
      'Club Settings Coming Soon',
      style: AppTheme.bodyLarge,
    ));
  }

  Color _getClubColor() {
    switch (widget.club.category.toLowerCase()) {
      case 'academic':
        return AppColors.gold.withOpacity(0.8);
      case 'sports':
        return AppColors.gold.withOpacity(0.7);
      case 'arts':
        return AppColors.gold.withOpacity(0.9);
      case 'social':
        return AppColors.gold.withOpacity(0.75);
      case 'greek life':
        return AppColors.gold.withOpacity(0.85);
      case 'professional':
        return AppColors.gold.withOpacity(0.65);
      case 'technology':
        return AppColors.gold.withOpacity(0.6);
      case 'advocacy':
        return AppColors.gold.withOpacity(0.7);
      case 'religious':
        return AppColors.gold.withOpacity(0.8);
      default:
        return AppColors.gold;
    }
  }

  IconData _getClubIcon() {
    switch (widget.club.category.toLowerCase()) {
      case 'academic':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'arts':
        return Icons.palette;
      case 'social':
        return Icons.people;
      case 'greek life':
        return Icons.diversity_3;
      case 'professional':
        return Icons.business;
      case 'technology':
        return Icons.computer;
      case 'advocacy':
        return Icons.campaign;
      case 'religious':
        return Icons.church;
      default:
        return Icons.group;
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.black,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
