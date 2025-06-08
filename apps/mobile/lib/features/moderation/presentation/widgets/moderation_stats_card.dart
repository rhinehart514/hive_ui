import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common/glass_container.dart';

class ModerateStatsCard extends ConsumerWidget {
  const ModerateStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real implementation, we would use the GetModerationStatsUseCase
    // For now, we'll show placeholder stats
    return GlassContainer(
      withShadow: true,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moderation Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildStatItem(
                  context,
                  'Pending',
                  '12',
                  Icons.pending_actions,
                  Colors.orangeAccent,
                ),
                _buildStatItem(
                  context,
                  'In Review',
                  '8',
                  Icons.rate_review,
                  Colors.blueAccent,
                ),
                _buildStatItem(
                  context,
                  'Resolved',
                  '48',
                  Icons.check_circle,
                  Colors.greenAccent,
                ),
                _buildStatItem(
                  context,
                  'Dismissed',
                  '15',
                  Icons.cancel,
                  Colors.grey,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('View Detailed Analytics'),
                  onPressed: () {
                    // Navigate to detailed analytics
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 