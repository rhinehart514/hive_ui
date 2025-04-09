import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/labs/domain/hive_lab_action.dart';
import 'package:hive_ui/features/labs/domain/hive_lab_repository.dart';

/// Implementation of the HiveLab repository with mock data
class HiveLabRepositoryImpl implements HiveLabRepository {
  // Mock data for available actions
  final List<HiveLabAction> _mockActions = [
    const HiveLabAction(
      id: 'idea_submission',
      title: 'Share your idea',
      description: 'Help improve campus life with your creative ideas',
      type: HiveLabActionType.ideaSubmission,
      iconType: HiveLabActionIconType.idea,
      priority: 5,
      isPremium: false,
    ),
    const HiveLabAction(
      id: 'feature_feedback',
      title: 'HIVE app feedback',
      description: 'Tell us what you think about the new HIVE features',
      type: HiveLabActionType.feedback,
      iconType: HiveLabActionIconType.feedback,
      priority: 4,
      isPremium: false,
    ),
    const HiveLabAction(
      id: 'beta_testing',
      title: 'Join beta testers',
      description: 'Get early access to new features by joining our beta program',
      type: HiveLabActionType.betaTesting,
      iconType: HiveLabActionIconType.beta,
      priority: 3,
      isPremium: true,
    ),
    const HiveLabAction(
      id: 'signal_strip_survey',
      title: 'Signal Strip survey',
      description: 'Help us improve the Signal Strip with your feedback',
      type: HiveLabActionType.survey,
      iconType: HiveLabActionIconType.survey,
      priority: 2,
      isPremium: false,
    ),
    const HiveLabAction(
      id: 'chaos_lab',
      title: 'Chaos Lab experiment',
      description: 'Join our experimental program focusing on campus chaos theory',
      type: HiveLabActionType.experiment,
      iconType: HiveLabActionIconType.experiment,
      priority: 1,
      isPremium: true,
    ),
  ];
  
  @override
  Future<List<HiveLabAction>> getAvailableActions({
    int maxCount = 5,
    bool includeExperimental = false,
    bool includePremium = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Filter actions based on parameters
    final filteredActions = _mockActions
        .where((action) => 
            (includePremium || !action.isPremium) &&
            (includeExperimental || action.type != HiveLabActionType.experiment))
        .where((action) => action.isAvailable())
        .toList();
    
    // Sort by priority (highest first)
    filteredActions.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Take only the requested amount
    return filteredActions.take(maxCount).toList();
  }

  @override
  Future<HiveLabAction?> getActionDetails(String actionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      return _mockActions.firstWhere((action) => action.id == actionId);
    } catch (e) {
      debugPrint('Action not found: $actionId');
      return null;
    }
  }

  @override
  Future<bool> trackActionClick(String actionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // In a real implementation, this would send analytics data
    debugPrint('Tracked click on HiveLab action: $actionId');
    return true;
  }

  @override
  Future<bool> submitIdea({
    required String title,
    required String description,
    String? category,
    Map<String, dynamic>? extraData,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // In a real implementation, this would send the idea to the backend
    debugPrint('Submitted idea: $title - $description');
    return true;
  }

  @override
  Future<bool> submitFeedback({
    required String feedbackText,
    String? category,
    int? rating,
    Map<String, dynamic>? extraData,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // In a real implementation, this would send the feedback to the backend
    debugPrint('Submitted feedback: $feedbackText (rating: $rating)');
    return true;
  }

  @override
  Future<bool> joinExperiment(String experimentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    // In a real implementation, this would register the user for the experiment
    debugPrint('Joined experiment: $experimentId');
    return true;
  }

  @override
  Future<bool> completeSurvey({
    required String surveyId,
    required Map<String, dynamic> responses,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // In a real implementation, this would submit the survey responses
    debugPrint('Completed survey: $surveyId with responses: $responses');
    return true;
  }
} 