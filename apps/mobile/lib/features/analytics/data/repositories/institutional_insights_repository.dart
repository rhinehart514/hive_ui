import 'package:hive_ui/features/analytics/data/models/institutional_insights_model.dart';

/// Repository for institutional insights data
abstract class InstitutionalInsightsRepository {
  /// Get insights for a specific date and timeframe
  /// 
  /// [date] - Date to get insights for
  /// [timeframe] - Timeframe of the insights (day, week, month, quarter, year)
  Future<InstitutionalInsightsModel> getInsightsForDate(DateTime date, String timeframe);
  
  /// Get insights for a date range
  /// 
  /// [startDate] - Start of the date range
  /// [endDate] - End of the date range
  /// [timeframe] - Timeframe of the insights (day, week, month, quarter, year)
  Future<List<InstitutionalInsightsModel>> getInsightsForDateRange(
    DateTime startDate, 
    DateTime endDate, 
    String timeframe
  );
  
  /// Get the most recent insights
  /// 
  /// [timeframe] - Timeframe of the insights (day, week, month, quarter, year)
  Future<InstitutionalInsightsModel> getMostRecentInsights(String timeframe);
  
  /// Get insights for specific metrics
  /// 
  /// [metrics] - List of metric keys to retrieve
  /// [timeframe] - Timeframe of the insights (day, week, month, quarter, year)
  /// [limit] - Maximum number of data points to return
  Future<Map<String, List<dynamic>>> getMetricsTimeSeries(
    List<String> metrics,
    String timeframe,
    int limit
  );
  
  /// Get comparative insights between two timeframes
  /// 
  /// [currentPeriodDate] - Reference date for the current period
  /// [previousPeriodDate] - Reference date for the previous period
  /// [timeframe] - Timeframe of the insights (day, week, month, quarter, year)
  Future<Map<String, dynamic>> getComparativeInsights(
    DateTime currentPeriodDate,
    DateTime previousPeriodDate,
    String timeframe
  );
  
  /// Generate a report with key insights
  /// 
  /// [startDate] - Start of the report period
  /// [endDate] - End of the report period
  /// [format] - Format of the report (json, pdf, csv)
  Future<String> generateReport(
    DateTime startDate,
    DateTime endDate,
    String format
  );
  
  /// Save custom insights data
  /// 
  /// [date] - Date for the insights
  /// [timeframe] - Timeframe of the insights (day, week, month, quarter, year)
  /// [data] - Custom insights data to save
  Future<void> saveCustomInsights(
    DateTime date,
    String timeframe,
    Map<String, dynamic> data
  );
} 