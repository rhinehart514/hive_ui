import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_analytics.dart';
import 'package:hive_ui/common/widgets/glassmorphic_container.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

enum ExportFormat { csv, json, pdf }

class AnalyticsExportButton extends ConsumerWidget {
  final ProfileAnalytics analytics;
  final DateTimeRange dateRange;

  const AnalyticsExportButton({
    super.key,
    required this.analytics,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassmorphicContainer(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                'Export Data',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Download or share analytics',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showExportOptions(context),
            icon: const Icon(Icons.download, color: AppColors.gold),
            tooltip: 'Export Analytics Data',
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final formattedStartDate = "${dateRange.start.year}-${dateRange.start.month.toString().padLeft(2, '0')}-${dateRange.start.day.toString().padLeft(2, '0')}";
    final formattedEndDate = "${dateRange.end.year}-${dateRange.end.month.toString().padLeft(2, '0')}-${dateRange.end.day.toString().padLeft(2, '0')}";
    final fileName = "analytics_${formattedStartDate}_to_$formattedEndDate";

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.grey800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Analytics Data',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.gold),
              title: Text('CSV Format', style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Export as spreadsheet', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              onTap: () => _exportData(context, ExportFormat.csv, '$fileName.csv'),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.code, color: AppColors.gold),
              title: Text('JSON Format', style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Export as structured data', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              onTap: () => _exportData(context, ExportFormat.json, '$fileName.json'),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.gold),
              title: Text('PDF Report', style: GoogleFonts.poppins(color: Colors.white)),
              subtitle: Text('Export as formatted report', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              onTap: () => _exportData(context, ExportFormat.pdf, '$fileName.pdf'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, ExportFormat format, String fileName) async {
    try {
      // Close the bottom sheet
      Navigator.pop(context);
      
      // Show loading indicator
      _showLoadingDialog(context);
      
      // Create temporary directory to store the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Generate content based on the selected format
      String content = '';
      switch (format) {
        case ExportFormat.csv:
          content = _generateCsvContent();
          break;
        case ExportFormat.json:
          content = _generateJsonContent();
          break;
        case ExportFormat.pdf:
          // PDF generation would typically use a package like pdf or printing
          // For now, we'll just create a placeholder text file
          content = 'PDF export is not implemented yet';
          break;
      }
      
      // Write the content to the file
      await file.writeAsString(content);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Analytics Export',
        text: 'Hive Analytics Data (${dateRange.start.toString().substring(0, 10)} to ${dateRange.end.toString().substring(0, 10)})',
      );
    } catch (e) {
      // Handle errors
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.grey800,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(width: 20),
            Text(
              'Preparing export...',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _generateCsvContent() {
    final StringBuffer csv = StringBuffer();
    
    // Add headers
    csv.writeln('Metric,Value');
    csv.writeln('Date Range,${dateRange.start.toString().substring(0, 10)} to ${dateRange.end.toString().substring(0, 10)}');
    csv.writeln('Engagement Score,${analytics.engagementScore}');
    csv.writeln('Recent Profile Views,${analytics.recentProfileViews}');
    csv.writeln('Recent Search Appearances,${analytics.recentSearchAppearances}');
    csv.writeln('Event Attendance Rate,${(analytics.eventAttendanceRate * 100).round()}%');
    csv.writeln('Space Participation Rate,${(analytics.spaceParticipationRate * 100).round()}%');
    csv.writeln('Content Engagement Rate,${(analytics.contentEngagementRate * 100).round()}%');
    csv.writeln('Connection Growth Rate,${analytics.connectionGrowthRate.toStringAsFixed(1)}%');
    
    // Add top spaces
    csv.writeln('\nTop Active Spaces');
    for (var i = 0; i < analytics.topActiveSpaces.length; i++) {
      csv.writeln('${i + 1},${analytics.topActiveSpaces[i]}');
    }
    
    // Add top events
    csv.writeln('\nTop Event Types');
    for (var i = 0; i < analytics.topEventTypes.length; i++) {
      csv.writeln('${i + 1},${analytics.topEventTypes[i]}');
    }
    
    // Add monthly activity
    csv.writeln('\nMonthly Activity');
    csv.writeln('Month,Activity Count');
    final sortedMonths = analytics.monthlyActivity.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (var entry in sortedMonths) {
      csv.writeln('${entry.key},${entry.value}');
    }
    
    // Add peak hours
    csv.writeln('\nPeak Activity Hours');
    for (var hour in analytics.peakActivityHours) {
      csv.writeln('$hour:00,');
    }
    
    return csv.toString();
  }

  String _generateJsonContent() {
    final Map<String, dynamic> jsonData = {
      'dateRange': {
        'start': dateRange.start.toString(),
        'end': dateRange.end.toString(),
      },
      'engagementScore': analytics.engagementScore,
      'recentProfileViews': analytics.recentProfileViews,
      'recentSearchAppearances': analytics.recentSearchAppearances,
      'eventAttendanceRate': analytics.eventAttendanceRate,
      'spaceParticipationRate': analytics.spaceParticipationRate,
      'contentEngagementRate': analytics.contentEngagementRate,
      'connectionGrowthRate': analytics.connectionGrowthRate,
      'topActiveSpaces': analytics.topActiveSpaces,
      'topEventTypes': analytics.topEventTypes,
      'topConnections': analytics.topConnections,
      'peakActivityHours': analytics.peakActivityHours,
      'monthlyActivity': analytics.monthlyActivity,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }
} 