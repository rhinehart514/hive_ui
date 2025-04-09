import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/analytics/presentation/screens/profile_analytics_screen.dart';

/// A button to navigate to the profile analytics screen
class ProfileAnalyticsButton extends ConsumerWidget {
  final String userId;
  
  const ProfileAnalyticsButton({
    Key? key,
    required this.userId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.analytics_outlined),
      title: const Text('View Analytics'),
      subtitle: const Text('Track your engagement and activity'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToAnalytics(context),
    );
  }
  
  void _navigateToAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileAnalyticsScreen(userId: userId),
      ),
    );
  }
} 