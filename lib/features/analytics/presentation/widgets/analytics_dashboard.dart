import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/domain/usecases/get_user_insights_usecase.dart';
import 'package:hive_ui/features/analytics/presentation/controllers/user_insights_controller.dart';

/// A dashboard widget to display user analytics
class AnalyticsDashboard extends ConsumerStatefulWidget {
  final String userId;
  
  const AnalyticsDashboard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard> {
  @override
  void initState() {
    super.initState();
    // Track analytics view
    Future.microtask(() {
      ref.read(userInsightsControllerProvider).trackAnalyticsView(widget.userId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(userInsightsControllerProvider);
    final insightsAsync = controller.getUserInsights(widget.userId);
    
    return RefreshIndicator(
      onRefresh: () => controller.refreshInsights(widget.userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: insightsAsync.when(
          data: (insights) => _buildInsightsDashboard(context, insights),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'Error loading analytics: $error',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInsightsDashboard(BuildContext context, UserInsights insights) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Insights Dashboard',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        
        // Engagement Score Card
        _buildMetricCard(
          context: context,
          title: 'Engagement Score',
          value: '${insights.engagementScore}',
          icon: Icons.trending_up,
          color: _getScoreColor(insights.engagementScore),
        ),
        const SizedBox(height: 16),
        
        // Key Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMetricCard(
              context: context,
              title: 'Profile Views',
              value: '${insights.metrics.profileViews}',
              icon: Icons.visibility,
            ),
            _buildMetricCard(
              context: context,
              title: 'Content Created',
              value: '${insights.metrics.contentCreated}',
              icon: Icons.create,
            ),
            _buildMetricCard(
              context: context,
              title: 'Spaces Joined',
              value: '${insights.metrics.spacesJoined}',
              icon: Icons.group,
            ),
            _buildMetricCard(
              context: context,
              title: 'Events Attended',
              value: '${insights.metrics.eventsAttended}',
              icon: Icons.event,
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Activity Insights
        Text('Activity Insights', style: textTheme.titleLarge),
        const SizedBox(height: 16),
        
        _buildInfoRow(
          context: context,
          title: 'Peak Activity Hour',
          value: insights.peakActivityHour != null 
            ? '${insights.peakActivityHour}:00' 
            : 'No data',
          icon: Icons.access_time,
        ),
        const SizedBox(height: 8),
        
        _buildInfoRow(
          context: context,
          title: 'Most Active Day',
          value: insights.mostActiveDay ?? 'No data',
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        
        _buildInfoRow(
          context: context,
          title: 'User Status',
          value: insights.isActive ? 'Active' : 'Inactive',
          icon: Icons.circle,
          color: insights.isActive ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 24),
        
        // Category Breakdown
        Text('Activity Breakdown', style: textTheme.titleLarge),
        const SizedBox(height: 16),
        
        ...insights.categoryBreakdown.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCategoryBar(
              context: context,
              category: _getCategoryName(entry.key),
              count: entry.value,
              total: insights.metrics.getTotalActivityCount(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Recent Events
        Text('Recent Activity', style: textTheme.titleLarge),
        const SizedBox(height: 16),
        
        ...insights.recentEvents.take(5).map((event) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildEventItem(context, event),
          ),
        ),
        const SizedBox(height: 24),
        
        // Export button
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _exportAnalytics(context),
            icon: const Icon(Icons.download),
            label: const Text('Export Analytics Data'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          '$title:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryBar({
    required BuildContext context,
    required String category,
    required int count,
    required int total,
  }) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category, style: Theme.of(context).textTheme.bodyLarge),
            Text('$count (${(percentage * 100).toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildEventItem(BuildContext context, event) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.history, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.getEventDescription(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _exportAnalytics(BuildContext context) async {
    final controller = ref.read(userInsightsControllerProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await controller.exportAnalytics(widget.userId);
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Analytics data exported successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to export analytics: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Color _getScoreColor(int score) {
    if (score < 100) return Colors.red;
    if (score < 500) return Colors.orange;
    if (score < 1000) return Colors.blue;
    return Colors.green;
  }
  
  String _getCategoryName(String key) {
    switch (key) {
      case 'profile': return 'Profile Activity';
      case 'social': return 'Social Interactions';
      case 'spaces': return 'Spaces Activity';
      case 'events': return 'Events Activity';
      case 'content': return 'Content Engagement';
      default: return key;
    }
  }
} 