import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/moderation/data/models/content_trust_score_model.dart';

/// Repository for managing content trust scores
class ContentTrustRepository {
  final FirebaseFirestore _firestore;
  
  /// Collection path for trust scores
  static const String _collectionPath = 'trust_scores';
  
  /// Constructor
  ContentTrustRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Get content trust score by id
  Future<ContentTrustScoreModel?> getTrustScore(String id) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(id).get();
      
      if (!doc.exists) return null;
      
      return ContentTrustScoreModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting trust score: $e');
      return null;
    }
  }
  
  /// Get trust score for content
  Future<ContentTrustScoreModel> getContentTrustScore(String contentId) async {
    final id = 'trust_$contentId';
    final existing = await getTrustScore(id);
    
    if (existing != null) return existing;
    
    // If no trust score exists, create a default one
    // In a real implementation, we would need to fetch the content details first
    // This is a simplified version
    return ContentTrustScoreModel(
      id: id,
      entityId: contentId,
      scope: TrustScoreScope.content,
      overallScore: 70.0,
      categoryScores: {
        TrustCategory.engagement: 70.0,
        TrustCategory.userReports: 100.0,
        TrustCategory.contentAnalysis: 70.0,
        TrustCategory.adminReview: 70.0,
        TrustCategory.accountHistory: 70.0,
      },
      updatedAt: DateTime.now(),
      flagCount: 0,
    );
  }
  
  /// Get trust score for a user
  Future<ContentTrustScoreModel> getUserTrustScore(String userId) async {
    final id = 'trust_user_$userId';
    final existing = await getTrustScore(id);
    
    if (existing != null) return existing;
    
    // If no trust score exists, create a default one
    return ContentTrustScoreModel.newUserScore(
      userId: userId,
    );
  }
  
  /// Save a trust score
  Future<void> saveTrustScore(ContentTrustScoreModel score) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(score.id)
          .set(score.toFirestore());
    } catch (e) {
      debugPrint('Error saving trust score: $e');
      rethrow;
    }
  }
  
  /// Update a trust score category
  Future<ContentTrustScoreModel> updateScoreCategory({
    required String entityId,
    required TrustScoreScope scope,
    required TrustCategory category,
    required double newScore,
    String? creatorId,
    String? spaceId,
  }) async {
    // Calculate ID based on scope and entity ID
    final id = scope == TrustScoreScope.user 
        ? 'trust_user_$entityId'
        : scope == TrustScoreScope.space
            ? 'trust_space_$entityId'
            : 'trust_$entityId';
    
    // Get existing or create new
    ContentTrustScoreModel score;
    final existing = await getTrustScore(id);
    
    if (existing != null) {
      score = existing;
    } else {
      // Create appropriate new score based on scope
      if (scope == TrustScoreScope.user) {
        score = ContentTrustScoreModel.newUserScore(userId: entityId);
      } else if (scope == TrustScoreScope.content) {
        score = ContentTrustScoreModel.newContentScore(
          contentId: entityId,
          creatorId: creatorId ?? 'unknown',
          spaceId: spaceId,
        );
      } else {
        // Default space score
        score = ContentTrustScoreModel(
          id: id,
          entityId: entityId,
          scope: scope,
          overallScore: 70.0,
          categoryScores: {
            TrustCategory.engagement: 70.0,
            TrustCategory.userReports: 100.0,
            TrustCategory.contentAnalysis: 70.0,
            TrustCategory.adminReview: 70.0,
            TrustCategory.accountHistory: 70.0,
          },
          updatedAt: DateTime.now(),
          flagCount: 0,
        );
      }
    }
    
    // Update the category score
    final updatedCategoryScores = Map<TrustCategory, double>.from(score.categoryScores);
    updatedCategoryScores[category] = newScore;
    
    // Calculate new overall score as average of all category scores
    final totalScore = updatedCategoryScores.values.fold<double>(
      0, (sum, score) => sum + score
    );
    final newOverallScore = totalScore / updatedCategoryScores.length;
    
    // Update score history
    final now = DateTime.now();
    final updatedScoreHistory = Map<String, double>.from(score.scoreHistory);
    updatedScoreHistory[now.toIso8601String()] = newOverallScore;
    
    // Create updated model
    final updatedScore = score.copyWith(
      categoryScores: updatedCategoryScores,
      overallScore: newOverallScore,
      updatedAt: now,
      scoreHistory: updatedScoreHistory,
    );
    
    // Save to Firestore
    await saveTrustScore(updatedScore);
    
    return updatedScore;
  }
  
  /// Report content (decreases user reports score)
  Future<ContentTrustScoreModel> reportContent({
    required String contentId,
    required String reporterId,
    String? reason,
    String? creatorId,
    String? spaceId,
  }) async {
    final scoreId = 'trust_$contentId';
    final existing = await getTrustScore(scoreId);
    
    ContentTrustScoreModel score;
    if (existing != null) {
      score = existing;
    } else {
      // Create new score if none exists
      score = ContentTrustScoreModel.newContentScore(
        contentId: contentId,
        creatorId: creatorId ?? 'unknown',
        spaceId: spaceId,
      );
    }
    
    // Calculate impact of the report
    // More flags = larger impact on score
    final currentReportsScore = score.categoryScores[TrustCategory.userReports] ?? 100.0;
    final newFlagCount = score.flagCount + 1;
    
    // Exponential decay for reports score based on number of flags
    // First flag reduces by 10, second by 15, third by 20, etc.
    final reductionAmount = 5 + (newFlagCount * 5);
    final newReportsScore = (currentReportsScore - reductionAmount).clamp(0.0, 100.0);
    
    // Update category scores
    final updatedCategoryScores = Map<TrustCategory, double>.from(score.categoryScores);
    updatedCategoryScores[TrustCategory.userReports] = newReportsScore;
    
    // Calculate new overall score
    final totalScore = updatedCategoryScores.values.fold<double>(
      0, (sum, score) => sum + score
    );
    final newOverallScore = totalScore / updatedCategoryScores.length;
    
    // Update score history
    final now = DateTime.now();
    final updatedScoreHistory = Map<String, double>.from(score.scoreHistory);
    updatedScoreHistory[now.toIso8601String()] = newOverallScore;
    
    // Store custom attributes about the report
    final updatedAttributes = Map<String, dynamic>.from(score.attributes);
    final reports = updatedAttributes['reports'] as List<dynamic>? ?? [];
    reports.add({
      'reporterId': reporterId,
      'timestamp': now.toIso8601String(),
      'reason': reason,
    });
    updatedAttributes['reports'] = reports;
    
    // Create updated model
    final updatedScore = score.copyWith(
      categoryScores: updatedCategoryScores,
      overallScore: newOverallScore,
      updatedAt: now,
      flagCount: newFlagCount,
      scoreHistory: updatedScoreHistory,
      attributes: updatedAttributes,
    );
    
    // Save to Firestore
    await saveTrustScore(updatedScore);
    
    return updatedScore;
  }
  
  /// Apply admin moderation action to content
  Future<ContentTrustScoreModel> applyAdminModeration({
    required String contentId,
    required String moderatorId,
    required double adminScore, // 0-100 score from admin
    String? note,
  }) async {
    final score = await getContentTrustScore(contentId);
    
    // Update category scores
    final updatedCategoryScores = Map<TrustCategory, double>.from(score.categoryScores);
    updatedCategoryScores[TrustCategory.adminReview] = adminScore;
    
    // Admin review has higher weight in overall score calculation
    // Weight distribution: admin 40%, user reports 25%, content analysis 20%, engagement 10%, account history 5%
    final weightedScore = 
        (updatedCategoryScores[TrustCategory.adminReview] ?? 70.0) * 0.4 +
        (updatedCategoryScores[TrustCategory.userReports] ?? 100.0) * 0.25 +
        (updatedCategoryScores[TrustCategory.contentAnalysis] ?? 70.0) * 0.2 +
        (updatedCategoryScores[TrustCategory.engagement] ?? 70.0) * 0.1 +
        (updatedCategoryScores[TrustCategory.accountHistory] ?? 70.0) * 0.05;
    
    // Update score history
    final now = DateTime.now();
    final updatedScoreHistory = Map<String, double>.from(score.scoreHistory);
    updatedScoreHistory[now.toIso8601String()] = weightedScore;
    
    // Store moderation history
    final updatedAttributes = Map<String, dynamic>.from(score.attributes);
    final moderationHistory = updatedAttributes['moderationHistory'] as List<dynamic>? ?? [];
    moderationHistory.add({
      'moderatorId': moderatorId,
      'timestamp': now.toIso8601String(),
      'score': adminScore,
      'note': note,
    });
    updatedAttributes['moderationHistory'] = moderationHistory;
    
    // Create updated model
    final updatedScore = score.copyWith(
      categoryScores: updatedCategoryScores,
      overallScore: weightedScore,
      updatedAt: now,
      scoreHistory: updatedScoreHistory,
      attributes: updatedAttributes,
      hasManualReview: true,
    );
    
    // Save to Firestore
    await saveTrustScore(updatedScore);
    
    return updatedScore;
  }
  
  /// Get all content requiring moderation
  Future<List<ContentTrustScoreModel>> getContentRequiringModeration({
    int limit = 20,
  }) async {
    try {
      // Get content with low user report scores
      final reportedQuery = await _firestore
          .collection(_collectionPath)
          .where('scope', isEqualTo: TrustScoreScope.content.toString().split('.').last)
          .where('categoryScores.userReports', isLessThan: 60)
          .orderBy('categoryScores.userReports', descending: false)
          .limit(limit)
          .get();
      
      // Get content with high flag counts
      final flaggedQuery = await _firestore
          .collection(_collectionPath)
          .where('scope', isEqualTo: TrustScoreScope.content.toString().split('.').last)
          .where('flagCount', isGreaterThan: 2)
          .orderBy('flagCount', descending: true)
          .limit(limit)
          .get();
      
      // Combine results, removing duplicates
      final uniqueResults = <String, ContentTrustScoreModel>{};
      
      for (final doc in reportedQuery.docs) {
        final score = ContentTrustScoreModel.fromFirestore(doc);
        uniqueResults[score.id] = score;
      }
      
      for (final doc in flaggedQuery.docs) {
        final score = ContentTrustScoreModel.fromFirestore(doc);
        uniqueResults[score.id] = score;
      }
      
      // Return as sorted list (higher flag count first)
      final results = uniqueResults.values.toList()
        ..sort((a, b) => b.flagCount.compareTo(a.flagCount));
      
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting content requiring moderation: $e');
      return [];
    }
  }
} 