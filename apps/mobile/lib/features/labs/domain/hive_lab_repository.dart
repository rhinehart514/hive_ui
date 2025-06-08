import 'package:hive_ui/features/labs/domain/hive_lab_action.dart';

/// Repository interface for HiveLab actions
abstract class HiveLabRepository {
  /// Get available actions for the HiveLab FAB menu
  /// 
  /// [maxCount] maximum number of actions to return
  /// [includeExperimental] whether to include experimental actions
  /// [includePremium] whether to include premium actions
  Future<List<HiveLabAction>> getAvailableActions({
    int maxCount = 5,
    bool includeExperimental = false,
    bool includePremium = false,
  });
  
  /// Get details about a specific HiveLab action
  Future<HiveLabAction?> getActionDetails(String actionId);
  
  /// Track when a user clicks on a HiveLab action
  Future<bool> trackActionClick(String actionId);
  
  /// Submit a HiveLab idea
  Future<bool> submitIdea({
    required String title,
    required String description,
    String? category,
    Map<String, dynamic>? extraData,
  });
  
  /// Submit feedback through HiveLab
  Future<bool> submitFeedback({
    required String feedbackText,
    String? category,
    int? rating,
    Map<String, dynamic>? extraData,
  });
  
  /// Join a HiveLab experiment
  Future<bool> joinExperiment(String experimentId);
  
  /// Complete a HiveLab survey
  Future<bool> completeSurvey({
    required String surveyId,
    required Map<String, dynamic> responses,
  });
} 