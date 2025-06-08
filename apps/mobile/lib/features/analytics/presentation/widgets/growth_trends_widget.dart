import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/presentation/controllers/analytics_controller.dart';

/// Widget that displays growth trends data
class GrowthTrendsWidget extends ConsumerStatefulWidget {
  /// Number of days to analyze for trends
  final int days;

  /// Constructor
  const GrowthTrendsWidget({
    Key? key,
    this.days = 30,
  }) : super(key: key);

  @override
  ConsumerState<GrowthTrendsWidget> createState() => _GrowthTrendsWidgetState();
}

class _GrowthTrendsWidgetState extends ConsumerState<GrowthTrendsWidget> {
  @override
  void initState() {
    super.initState();
    // Load data when widget initializes
    Future.microtask(() => ref.read(analyticsControllerProvider.notifier).loadGrowthTrends(widget.days));
  }

  @override
  Widget build(BuildContext context) {
    final trendsState = ref.watch(analyticsControllerProvider);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Growth Trends (${widget.days} days)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(analyticsControllerProvider.notifier).loadGrowthTrends(widget.days),
                ),
              ],
            ),
            const Divider(),
            trendsState.when(
              data: (data) => _buildTrendsData(context, data),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error loading trends: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsData(BuildContext context, Map<String, dynamic> data) {
    // Extract data from the trends
    final userGrowth = (data['userGrowth'] as double).toStringAsFixed(2);
    final retentionTrend = (data['retentionTrend'] as double).toStringAsFixed(2);
    final acquisitionTrend = data['acquisitionTrend'] as Map<String, dynamic>;
    final engagementTrend = data['engagementTrend'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User growth metric
        ListTile(
          leading: const Icon(Icons.trending_up, color: Colors.green),
          title: const Text('User Growth'),
          subtitle: Text('$userGrowth%'),
        ),
        
        // Retention trend
        ListTile(
          leading: const Icon(Icons.people, color: Colors.blue),
          title: const Text('Retention Rate'),
          subtitle: Text('$retentionTrend%'),
        ),
        
        // Acquisition channels
        if (acquisitionTrend.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Acquisition Channels', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...acquisitionTrend.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
        
        // Engagement metrics
        if (engagementTrend.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('Engagement Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...engagementTrend.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key),
                Text(entry.value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ],
    );
  }
} 