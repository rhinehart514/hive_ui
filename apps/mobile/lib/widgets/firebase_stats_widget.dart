import 'package:flutter/material.dart';
import 'package:hive_ui/services/firebase_monitor.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays Firebase usage statistics
class FirebaseStatsWidget extends StatefulWidget {
  const FirebaseStatsWidget({super.key});

  @override
  State<FirebaseStatsWidget> createState() => _FirebaseStatsWidgetState();
}

class _FirebaseStatsWidgetState extends State<FirebaseStatsWidget> {
  Map<String, dynamic> _stats = {};
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _updateStats();
  }

  void _updateStats() {
    setState(() {
      _stats = FirebaseMonitor.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Firebase Usage',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: AppColors.gold.withOpacity(0.7),
                          size: 18,
                        ),
                        onPressed: _updateStats,
                        tooltip: 'Refresh stats',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.gold.withOpacity(0.7),
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _expanded = !_expanded;
                          });
                        },
                        tooltip: _expanded ? 'Show less' : 'Show more',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildBasicStats(),
              if (_expanded) ...[
                const Divider(color: AppColors.gold, thickness: 0.3),
                _buildDetailedStats(),
                const SizedBox(height: 8),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicStats() {
    final readOps = _stats['readOperations'] ?? 0;
    final cachedOps = _stats['cachedOperations'] ?? 0;
    final cacheSavings = _stats['cacheSavingsPercent'] ?? '0.0';

    return Row(
      children: [
        Expanded(
          child: _statItem(
            'Reads',
            '$readOps',
            Icons.cloud_download_outlined,
          ),
        ),
        Expanded(
          child: _statItem(
            'Cached',
            '$cachedOps',
            Icons.cached_outlined,
          ),
        ),
        Expanded(
          child: _statItem(
            'Savings',
            '$cacheSavings%',
            Icons.savings_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    final readsPerMinute = _stats['readsPerMinute'] ?? '0.0';
    final estimatedCost = _stats['estimatedCost'] ?? '\$0.00';
    final sessionDuration = _stats['sessionDuration'] ?? '0 minutes';
    final intercepted = _stats['requestsIntercepted'] ?? 0;
    final total = _stats['totalRequests'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Detailed Statistics',
          style: TextStyle(
            color: AppColors.gold.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statItem(
                'Reads/min',
                readsPerMinute,
                Icons.speed_outlined,
                showIcon: false,
              ),
            ),
            Expanded(
              child: _statItem(
                'Est. Cost',
                estimatedCost,
                Icons.attach_money_outlined,
                showIcon: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _statItem(
                'Session',
                sessionDuration,
                Icons.timer_outlined,
                showIcon: false,
              ),
            ),
            Expanded(
              child: _statItem(
                'Intercepted',
                '$intercepted/$total',
                Icons.security_outlined,
                showIcon: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () async {
            await FirebaseMonitor.resetStats();
            _updateStats();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold.withOpacity(0.8),
            textStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('RESET STATS'),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon,
      {bool showIcon = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (showIcon) ...[
                Icon(
                  icon,
                  color: AppColors.gold.withOpacity(0.5),
                  size: 14,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
