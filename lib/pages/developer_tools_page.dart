import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/services/firebase_monitor.dart';
import 'package:hive_ui/services/optimized_data_service.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:hive_ui/services/space_event_manager.dart';
import 'package:hive_ui/services/request_interceptor.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/firebase_stats_widget.dart';
import 'package:hive_ui/widgets/glassmorphism.dart';

/// Developer tools page for monitoring and debugging app performance
class DeveloperToolsPage extends ConsumerStatefulWidget {
  const DeveloperToolsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DeveloperToolsPage> createState() => _DeveloperToolsPageState();
}

class _DeveloperToolsPageState extends ConsumerState<DeveloperToolsPage> {
  bool _isLoading = false;
  bool _isForcingRefresh = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerformanceSection(),
                  const SizedBox(height: 24),
                  _buildCacheControlSection(),
                  const SizedBox(height: 24),
                  _buildFirebaseSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Performance Monitoring', Icons.speed),
        const SizedBox(height: 16),
        const FirebaseStatsWidget(),
      ],
    );
  }

  Widget _buildCacheControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cache Control', Icons.storage),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Clear All Caches',
                'Clears all in-memory and persistent caches',
                Icons.delete_sweep,
                onTap: _clearAllCaches,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Force Data Refresh',
                'Forces a refresh of all cached data',
                Icons.refresh,
                onTap: _forceDataRefresh,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirebaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Firebase Tools', Icons.data_usage),
        const SizedBox(height: 16),
        _buildActionCard(
          'Reset Firebase Stats',
          'Reset all Firebase usage counters',
          Icons.restore,
          onTap: _resetFirebaseStats,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.gold,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassmorphicContainer(
          blur: 20,
          opacity: 0.1,
          borderRadius: 12,
          border: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllCaches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear all caches
      await OptimizedDataService.clearCache();
      await OptimizedClubAdapter.clearCache();
      SpaceEventManager.clearCache();
      RequestInterceptor.clearCache();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All caches have been cleared'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing caches: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceDataRefresh() async {
    setState(() {
      _isLoading = true;
      _isForcingRefresh = true;
    });

    try {
      // Force refresh all data
      await OptimizedDataService.getAllSpaces(forceRefresh: true);
      await OptimizedClubAdapter.getAllClubs(forceRefresh: true);
      await SpaceEventManager.getAllEvents();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isForcingRefresh = false;
      });
    }
  }

  Future<void> _resetFirebaseStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseMonitor.resetStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase statistics have been reset'),
          backgroundColor: Colors.green,
        ),
      );

      // Force UI update
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting statistics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
