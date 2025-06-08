import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_analytics.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_analytics_provider.dart';
import 'package:hive_ui/features/profile/presentation/widgets/date_range_selector.dart';
import 'package:hive_ui/features/profile/presentation/widgets/analytics_export_button.dart';
import 'package:hive_ui/common/widgets/glassmorphic_container.dart';

class ProfileAnalyticsPage extends ConsumerWidget {
  final String userId;

  const ProfileAnalyticsPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);
    final analytics = ref.watch(profileAnalyticsProvider((
      userId: userId,
      range: dateRange,
    )));

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile Analytics',
          style: GoogleFonts.poppins(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: analytics.when(
        data: (data) => _buildAnalyticsContent(context, data, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Text(
            'Error loading analytics',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, ProfileAnalytics data, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(ref),
          const SizedBox(height: 16),
          DateRangeSelector(
            onRangeSelected: (range) {
              ref.read(selectedDateRangeProvider.notifier).state = range;
            },
          ),
          const SizedBox(height: 16),
          AnalyticsExportButton(
            analytics: data,
            dateRange: dateRange,
          ),
          const SizedBox(height: 24),
          _buildEngagementScore(data),
          const SizedBox(height: 24),
          _buildRecentMetrics(data),
          const SizedBox(height: 24),
          _buildRatesSection(data),
          const SizedBox(height: 24),
          _buildActivityChart(data),
          const SizedBox(height: 24),
          _buildTopLists(data),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final isRealTimeEnabled = ref.watch(realTimeUpdatesEnabledProvider);
    
    return GlassmorphicContainer(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Analytics',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your engagement and activity',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Real-time',
                style: GoogleFonts.poppins(
                  color: isRealTimeEnabled ? AppColors.gold : Colors.white70,
                  fontSize: 12,
                  fontWeight: isRealTimeEnabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Switch(
                value: isRealTimeEnabled,
                onChanged: (value) {
                  ref.read(realTimeUpdatesEnabledProvider.notifier).state = value;
                },
                activeColor: AppColors.gold,
                activeTrackColor: AppColors.gold.withOpacity(0.3),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementScore(ProfileAnalytics data) {
    return GlassmorphicContainer(
      borderRadius: 15,
      padding: const EdgeInsets.all(24),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Column(
        children: [
          Text(
            'Engagement Score',
            style: GoogleFonts.poppins(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: data.engagementScore / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.grey600,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              Text(
                '${data.engagementScore}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMetrics(ProfileAnalytics data) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Profile Views',
            data.recentProfileViews.toString(),
            Icons.visibility,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Search Appearances',
            data.recentSearchAppearances.toString(),
            Icons.search,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return GlassmorphicContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesSection(ProfileAnalytics data) {
    return GlassmorphicContainer(
      borderRadius: 15,
      padding: const EdgeInsets.all(20),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Rates',
            style: GoogleFonts.poppins(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildRateIndicator(
            'Event Attendance',
            data.eventAttendanceRate,
            Icons.event,
          ),
          const SizedBox(height: 12),
          _buildRateIndicator(
            'Space Participation',
            data.spaceParticipationRate,
            Icons.groups,
          ),
          const SizedBox(height: 12),
          _buildRateIndicator(
            'Content Engagement',
            data.contentEngagementRate,
            Icons.article,
          ),
          const SizedBox(height: 12),
          _buildRateIndicator(
            'Connection Growth',
            data.connectionGrowthRate / 100,
            Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildRateIndicator(String label, double value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.grey600,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      ],
    );
  }

  Widget _buildActivityChart(ProfileAnalytics data) {
    final monthlyData = data.monthlyActivity.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return GlassmorphicContainer(
      borderRadius: 15,
      padding: const EdgeInsets.all(20),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Activity',
            style: GoogleFonts.poppins(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= monthlyData.length) return const Text('');
                        final month = monthlyData[value.toInt()].key.split('-')[1];
                        return Text(
                          month,
                          style: const TextStyle(color: Colors.white70),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.gold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.gold.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLists(ProfileAnalytics data) {
    return Row(
      children: [
        Expanded(
          child: _buildTopList(
            'Top Spaces',
            data.topActiveSpaces,
            Icons.groups,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTopList(
            'Top Events',
            data.topEventTypes,
            Icons.event,
          ),
        ),
      ],
    );
  }

  Widget _buildTopList(String title, List<String> items, IconData icon) {
    return GlassmorphicContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              item,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }
} 
