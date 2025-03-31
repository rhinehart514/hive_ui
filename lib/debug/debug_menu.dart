import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/event_card/event_card_example.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// Debug menu for quick access to test components and screens
class DebugMenu extends StatelessWidget {
  const DebugMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('HIVE Debug Menu'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('UI Components'),
          _buildDebugTile(
            context,
            title: 'Event Card Example',
            subtitle: 'View the new premium HiveEventCard component',
            icon: Icons.calendar_today,
            onTap: () => _navigateToEventCardExample(context),
          ),
          
          const Divider(color: AppColors.divider, height: 32),
          
          _buildSectionTitle('Developer Tools'),
          _buildDebugTile(
            context,
            title: 'Return to App',
            subtitle: 'Go back to the main application',
            icon: Icons.exit_to_app,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildDebugTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.grey800,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
      ),
    );
  }
  
  void _navigateToEventCardExample(BuildContext context) {
    // We can either use GoRouter or direct navigation to our example page
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EventCardExamplePage()),
    );
  }
} 