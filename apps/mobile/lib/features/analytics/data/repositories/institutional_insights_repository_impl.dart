import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/analytics/data/models/institutional_insights_model.dart';
import 'package:hive_ui/features/analytics/data/repositories/institutional_insights_repository.dart';

/// Implementation of the institutional insights repository
class InstitutionalInsightsRepositoryImpl implements InstitutionalInsightsRepository {
  final FirebaseFirestore _firestore;
  
  /// Collection path for institutional insights
  static const String _collectionPath = 'institutional_insights';
  
  /// Constructor
  InstitutionalInsightsRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<InstitutionalInsightsModel> getInsightsForDate(DateTime date, String timeframe) async {
    // Format date for document ID
    final String formattedDate = date.toIso8601String().split('T')[0];
    final String docId = '${timeframe}_$formattedDate';
    
    // Get document
    final docSnapshot = await _firestore.collection(_collectionPath).doc(docId).get();
    
    if (docSnapshot.exists) {
      return InstitutionalInsightsModel.fromFirestore(docSnapshot);
    } else {
      // Return empty model if no data exists
      return InstitutionalInsightsModel.empty(date, timeframe);
    }
  }
  
  @override
  Future<List<InstitutionalInsightsModel>> getInsightsForDateRange(
    DateTime startDate, 
    DateTime endDate, 
    String timeframe
  ) async {
    // Query insights within the date range for the specific timeframe
    final querySnapshot = await _firestore.collection(_collectionPath)
        .where('timeframe', isEqualTo: timeframe)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();
    
    // Parse results
    final insights = querySnapshot.docs.map((doc) => 
      InstitutionalInsightsModel.fromFirestore(doc)
    ).toList();
    
    return insights;
  }
  
  @override
  Future<InstitutionalInsightsModel> getMostRecentInsights(String timeframe) async {
    // Query the most recent insights for the timeframe
    final querySnapshot = await _firestore.collection(_collectionPath)
        .where('timeframe', isEqualTo: timeframe)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return InstitutionalInsightsModel.fromFirestore(querySnapshot.docs.first);
    } else {
      // Return empty model if no data exists
      return InstitutionalInsightsModel.empty(DateTime.now(), timeframe);
    }
  }
  
  @override
  Future<Map<String, List<dynamic>>> getMetricsTimeSeries(
    List<String> metrics,
    String timeframe,
    int limit
  ) async {
    // Query the insights with the given timeframe
    final querySnapshot = await _firestore.collection(_collectionPath)
        .where('timeframe', isEqualTo: timeframe)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    
    // Extract metrics from each insights document
    final Map<String, List<dynamic>> result = {};
    
    // Initialize result map with empty lists for each metric
    for (final metric in metrics) {
      result[metric] = [];
    }
    
    // Process documents in reverse order (oldest to newest)
    for (final doc in querySnapshot.docs.reversed) {
      final data = doc.data();
      final dateTimestamp = data['date'] as Timestamp;
      final date = dateTimestamp.toDate();
      
      for (final metric in metrics) {
        // Split metric path by dots to access nested properties
        final pathParts = metric.split('.');
        
        // Start with the full data map
        dynamic value = data;
        
        // Navigate through the path parts
        for (final part in pathParts) {
          if (value is Map && value.containsKey(part)) {
            value = value[part];
          } else {
            value = null;
            break;
          }
        }
        
        // Add the data point with date and value
        if (value != null) {
          result[metric]!.add({
            'date': date,
            'value': value,
          });
        }
      }
    }
    
    return result;
  }
  
  @override
  Future<Map<String, dynamic>> getComparativeInsights(
    DateTime currentPeriodDate,
    DateTime previousPeriodDate,
    String timeframe
  ) async {
    // Get insights for both periods
    final currentInsights = await getInsightsForDate(currentPeriodDate, timeframe);
    final previousInsights = await getInsightsForDate(previousPeriodDate, timeframe);
    
    // Calculate percent changes and differences
    final Map<String, dynamic> comparison = {
      'periods': {
        'current': currentPeriodDate.toIso8601String(),
        'previous': previousPeriodDate.toIso8601String(),
      },
      'timeframe': timeframe,
      'metrics': <String, dynamic>{},
    };
    
    // Calculate user growth
    final currentUserCount = currentInsights.totalUserCount;
    final previousUserCount = previousInsights.totalUserCount;
    final userCountDiff = currentUserCount - previousUserCount;
    final userCountPercentChange = previousUserCount > 0 
        ? (userCountDiff / previousUserCount) * 100 
        : 0.0;
    
    comparison['metrics']['totalUserCount'] = {
      'current': currentUserCount,
      'previous': previousUserCount,
      'difference': userCountDiff,
      'percentChange': userCountPercentChange,
    };
    
    // Compare student engagement metrics
    comparison['metrics']['studentEngagement'] = _compareMetricMaps(
      currentInsights.studentEngagement,
      previousInsights.studentEngagement,
    );
    
    // Compare organization engagement metrics
    comparison['metrics']['organizationEngagement'] = _compareMetricMaps(
      currentInsights.organizationEngagement,
      previousInsights.organizationEngagement,
    );
    
    // Compare retention metrics
    comparison['metrics']['retentionMetrics'] = _compareMetricMaps(
      currentInsights.retentionMetrics,
      previousInsights.retentionMetrics,
    );
    
    // Compare content distribution
    comparison['metrics']['contentDistribution'] = _compareMetricMaps(
      currentInsights.contentDistribution.map((k, v) => MapEntry(k, v.toDouble())),
      previousInsights.contentDistribution.map((k, v) => MapEntry(k, v.toDouble())),
    );
    
    return comparison;
  }
  
  @override
  Future<String> generateReport(
    DateTime startDate,
    DateTime endDate,
    String format
  ) async {
    // Get insights for the period
    final weeklyInsights = await getInsightsForDateRange(
      startDate, 
      endDate, 
      'week'
    );
    
    // Generate a report URL or data based on format
    if (format == 'json') {
      // Convert insights to JSON format
      final jsonData = weeklyInsights.map((insight) => insight.toJson()).toList();
      return jsonData.toString();
    } else if (format == 'csv') {
      // Create CSV data (simplified)
      final rows = <String>[];
      rows.add('Date,TotalUsers,ActiveUsers,Events,Content');
      
      for (final insight in weeklyInsights) {
        final date = insight.date.toIso8601String().split('T')[0];
        final totalUsers = insight.totalUserCount;
        final activeUsers = insight.studentEngagement['activeUsers'] ?? 0;
        final events = insight.eventMetrics['total'] ?? 0;
        final content = insight.contentDistribution.values.fold<int>(0, (a, b) => a + b);
        
        rows.add('$date,$totalUsers,$activeUsers,$events,$content');
      }
      
      return rows.join('\n');
    } else {
      // For PDF, we'd normally generate a PDF file and return a download URL
      // Here, we'll just return a placeholder URL
      return 'https://hive.edu/reports/insights_${startDate.toIso8601String().split('T')[0]}_to_${endDate.toIso8601String().split('T')[0]}.pdf';
    }
  }
  
  @override
  Future<void> saveCustomInsights(
    DateTime date,
    String timeframe,
    Map<String, dynamic> data
  ) async {
    // Format date for document ID
    final String formattedDate = date.toIso8601String().split('T')[0];
    final String docId = '${timeframe}_$formattedDate';
    
    // Get existing insights to merge with custom data
    final existingInsights = await getInsightsForDate(date, timeframe);
    final Map<String, dynamic> existingData = existingInsights.toJson();
    
    // Merge existing data with custom data
    existingData['customMetrics'] = {
      ...existingData['customMetrics'] as Map<String, dynamic>? ?? {},
      ...data,
    };
    
    // Save to Firestore
    await _firestore.collection(_collectionPath).doc(docId).set(
      existingData,
      SetOptions(merge: true),
    );
  }
  
  // Helper method to compare two metric maps
  Map<String, dynamic> _compareMetricMaps(
    Map<String, double> current,
    Map<String, double> previous,
  ) {
    final result = <String, dynamic>{};
    
    // Get all unique keys
    final allKeys = <String>{...current.keys, ...previous.keys};
    
    for (final key in allKeys) {
      final currentValue = current[key] ?? 0.0;
      final previousValue = previous[key] ?? 0.0;
      final difference = currentValue - previousValue;
      final percentChange = previousValue != 0 
          ? (difference / previousValue) * 100 
          : 0.0;
      
      result[key] = {
        'current': currentValue,
        'previous': previousValue,
        'difference': difference,
        'percentChange': percentChange,
      };
    }
    
    return result;
  }
} 