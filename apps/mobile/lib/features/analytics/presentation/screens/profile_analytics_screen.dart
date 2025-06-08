import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/presentation/widgets/analytics_dashboard.dart';

/// Screen to display analytics for a user profile
class ProfileAnalyticsScreen extends ConsumerWidget {
  final String userId;
  
  const ProfileAnalyticsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAnalyticsInfo(context),
          ),
        ],
      ),
      body: SafeArea(
        child: AnalyticsDashboard(userId: userId),
      ),
    );
  }
  
  void _showAnalyticsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Analytics'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Analytics Dashboard provides insights into your activity and engagement on the HIVE platform.',
              ),
              SizedBox(height: 16),
              Text(
                'The Engagement Score is calculated based on:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Profile views: 1 point each'),
              Text('• Content created: 10 points each'),
              Text('• Content engagement: 5 points each'),
              Text('• Spaces joined: 15 points each'),
              Text('• Events attended: 20 points each'),
              SizedBox(height: 16),
              Text(
                'Data is refreshed every 15 minutes. Pull down to refresh manually.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 