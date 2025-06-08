import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';

/// Repository interface for the Signal Strip content
abstract class SignalRepository {
  /// Get a list of signal content for the Signal Strip
  /// 
  /// [maxItems] The maximum number of items to return
  /// [types] Optional list of signal types to filter by
  Future<List<SignalContent>> getSignalContent({
    int maxItems = 5,
    List<SignalType>? types,
  });
  
  /// Get a specific signal content by ID
  Future<SignalContent?> getSignalContentById(String id);
  
  /// Log that a user viewed a signal content
  Future<bool> logSignalContentView(String contentId);
  
  /// Log that a user tapped on a signal content
  Future<bool> logSignalContentTap(String contentId);
} 