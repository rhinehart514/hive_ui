import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/content_report_entity.dart';
import '../widgets/report_filter_chip.dart';
import '../widgets/report_list_item.dart';
import '../widgets/moderation_stats_card.dart';
import '../../../../theme/app_colors.dart';
import 'package:hive_ui/features/moderation/presentation/providers/moderation_providers.dart';

class ModeratorDashboardScreen extends ConsumerStatefulWidget {
  const ModeratorDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ModeratorDashboardScreen> createState() => _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends ConsumerState<ModeratorDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportStatus _selectedStatusFilter = ReportStatus.pending;
  ReportedContentType? _selectedTypeFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Load initial reports
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilteredReports();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatusFilter = ReportStatus.pending;
            break;
          case 1:
            _selectedStatusFilter = ReportStatus.underReview;
            break;
          case 2:
            _selectedStatusFilter = ReportStatus.resolved;
            break;
        }
      });
      
      // Reload reports for the new tab
      _loadFilteredReports();
    }
  }

  void _loadFilteredReports() {
    // Check if we're filtering by status
    if (_selectedTypeFilter != null || _searchQuery.isNotEmpty) {
      // For complex filtering, we'll load all reports by status and filter them client-side
      ref.read(moderationControllerProvider.notifier).loadReportsByStatus(_selectedStatusFilter);
      // Note: Actual filtering happens in the UI since we haven't implemented server-side filtering
    } else {
      // Simple status filtering
      ref.read(moderationControllerProvider.notifier).loadReportsByStatus(_selectedStatusFilter);
    }
  }

  void _applyTypeFilter(ReportedContentType? type) {
    setState(() {
      _selectedTypeFilter = type;
    });
    
    _loadFilteredReports();
  }

  void _applySearchFilter(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    _loadFilteredReports();
  }

  @override
  Widget build(BuildContext context) {
    final moderationState = ref.watch(moderationControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Under Review'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: ModerateStatsCard(),
          ),
          
          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search reports...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: _applySearchFilter,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white70),
                  onPressed: () => _showFilterDialog(),
                ),
              ],
            ),
          ),
          
          // Type Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'All Types',
                  isSelected: _selectedTypeFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Posts',
                  isSelected: _selectedTypeFilter == ReportedContentType.post,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(ReportedContentType.post);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Comments',
                  isSelected: _selectedTypeFilter == ReportedContentType.comment,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(ReportedContentType.comment);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Messages',
                  isSelected: _selectedTypeFilter == ReportedContentType.message,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(ReportedContentType.message);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Spaces',
                  isSelected: _selectedTypeFilter == ReportedContentType.space,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(ReportedContentType.space);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Events',
                  isSelected: _selectedTypeFilter == ReportedContentType.event,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(ReportedContentType.event);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ReportFilterChip(
                  label: 'Profiles',
                  isSelected: _selectedTypeFilter == ReportedContentType.profile,
                  onSelected: (selected) {
                    if (selected) {
                      _applyTypeFilter(ReportedContentType.profile);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: moderationState.when(
              data: (reports) {
                // Apply client-side filtering
                List<ContentReportEntity> filteredReports = reports;
                
                // Filter by content type
                if (_selectedTypeFilter != null) {
                  filteredReports = filteredReports.where((report) => 
                    report.contentType == _selectedTypeFilter
                  ).toList();
                }
                
                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredReports = filteredReports.where((report) => 
                    report.id.toLowerCase().contains(query) || 
                    (report.details?.toLowerCase().contains(query) ?? false)
                  ).toList();
                }
                
                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return ReportListItem(
                      report: report,
                      onTap: () => _navigateToReportDetails(report),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading reports',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _loadFilteredReports(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showModerationSettings(),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.settings, color: Colors.black),
      ),
    );
  }

  void _showFilterDialog() {
    // Show a dialog with additional filtering options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: const Text('Additional filter options will go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToReportDetails(ContentReportEntity report) {
    // Navigate to report details page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ReportDetailsScreen(report: report),
    //   ),
    // );
  }

  void _showModerationSettings() {
    // Navigate to moderation settings
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ModerationSettingsScreen(),
    //   ),
    // );
  }
} 