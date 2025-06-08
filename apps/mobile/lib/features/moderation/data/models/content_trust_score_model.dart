import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines the categories of trust indicators tracked for content and users
enum TrustCategory {
  /// Overall engagement quality
  engagement,
  
  /// Reports by other users
  userReports,
  
  /// Automated content analysis
  contentAnalysis,
  
  /// Administrative review
  adminReview,
  
  /// Time-based reputation
  accountHistory,
}

/// Defines the scope of the trust score
enum TrustScoreScope {
  /// Applied to individual content
  content,
  
  /// Applied to a user account
  user,
  
  /// Applied to a space/community
  space,
}

/// Model for tracking trust scores for content and users
class ContentTrustScoreModel {
  /// Unique identifier
  final String id;
  
  /// The entity this trust score applies to (content, user, or space ID)
  final String entityId;
  
  /// The type of entity this trust score applies to
  final TrustScoreScope scope;
  
  /// Overall trust score (0-100)
  final double overallScore;
  
  /// Detailed scores by category (0-100)
  final Map<TrustCategory, double> categoryScores;
  
  /// Last update timestamp
  final DateTime updatedAt;
  
  /// Creator user ID
  final String? creatorId;
  
  /// Space ID (if applicable)
  final String? spaceId;
  
  /// Count of flags raised
  final int flagCount;
  
  /// Whether auto-moderation has been applied
  final bool hasAutoModeration;
  
  /// Whether manual review has been performed
  final bool hasManualReview;
  
  /// Historical score records (timestamp -> score)
  final Map<String, double> scoreHistory;
  
  /// Custom attributes for extensibility
  final Map<String, dynamic> attributes;
  
  /// Constructor
  const ContentTrustScoreModel({
    required this.id,
    required this.entityId,
    required this.scope,
    required this.overallScore,
    required this.categoryScores,
    required this.updatedAt,
    this.creatorId,
    this.spaceId,
    this.flagCount = 0,
    this.hasAutoModeration = false,
    this.hasManualReview = false,
    this.scoreHistory = const {},
    this.attributes = const {},
  });
  
  /// Create a new instance with updated fields
  ContentTrustScoreModel copyWith({
    String? id,
    String? entityId,
    TrustScoreScope? scope,
    double? overallScore,
    Map<TrustCategory, double>? categoryScores,
    DateTime? updatedAt,
    String? creatorId,
    String? spaceId,
    int? flagCount,
    bool? hasAutoModeration,
    bool? hasManualReview,
    Map<String, double>? scoreHistory,
    Map<String, dynamic>? attributes,
  }) {
    return ContentTrustScoreModel(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      scope: scope ?? this.scope,
      overallScore: overallScore ?? this.overallScore,
      categoryScores: categoryScores ?? this.categoryScores,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorId: creatorId ?? this.creatorId,
      spaceId: spaceId ?? this.spaceId,
      flagCount: flagCount ?? this.flagCount,
      hasAutoModeration: hasAutoModeration ?? this.hasAutoModeration,
      hasManualReview: hasManualReview ?? this.hasManualReview,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      attributes: attributes ?? this.attributes,
    );
  }
  
  /// Create a trust score from Firestore data
  factory ContentTrustScoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse category scores
    final Map<TrustCategory, double> categoryScores = {};
    if (data['categoryScores'] != null) {
      (data['categoryScores'] as Map<String, dynamic>).forEach((key, value) {
        final category = TrustCategory.values.firstWhere(
          (c) => c.toString().split('.').last == key,
          orElse: () => TrustCategory.engagement,
        );
        categoryScores[category] = (value as num).toDouble();
      });
    }
    
    // Parse score history
    final Map<String, double> scoreHistory = {};
    if (data['scoreHistory'] != null) {
      (data['scoreHistory'] as Map<String, dynamic>).forEach((key, value) {
        scoreHistory[key] = (value as num).toDouble();
      });
    }
    
    return ContentTrustScoreModel(
      id: doc.id,
      entityId: data['entityId'] ?? '',
      scope: TrustScoreScope.values.firstWhere(
        (s) => s.toString().split('.').last == (data['scope'] ?? 'content'),
        orElse: () => TrustScoreScope.content,
      ),
      overallScore: (data['overallScore'] as num?)?.toDouble() ?? 70.0,
      categoryScores: categoryScores,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorId: data['creatorId'],
      spaceId: data['spaceId'],
      flagCount: (data['flagCount'] as num?)?.toInt() ?? 0,
      hasAutoModeration: data['hasAutoModeration'] ?? false,
      hasManualReview: data['hasManualReview'] ?? false,
      scoreHistory: scoreHistory,
      attributes: data['attributes'] as Map<String, dynamic>? ?? {},
    );
  }
  
  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    // Convert enum maps to string keys
    final Map<String, dynamic> categoryScoresMap = {};
    categoryScores.forEach((key, value) {
      categoryScoresMap[key.toString().split('.').last] = value;
    });
    
    return {
      'entityId': entityId,
      'scope': scope.toString().split('.').last,
      'overallScore': overallScore,
      'categoryScores': categoryScoresMap,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'creatorId': creatorId,
      'spaceId': spaceId,
      'flagCount': flagCount,
      'hasAutoModeration': hasAutoModeration,
      'hasManualReview': hasManualReview,
      'scoreHistory': scoreHistory,
      'attributes': attributes,
    };
  }
  
  /// Create a new trust score for content
  factory ContentTrustScoreModel.newContentScore({
    required String contentId,
    required String creatorId,
    String? spaceId,
  }) {
    final now = DateTime.now();
    final id = 'trust_$contentId';
    
    return ContentTrustScoreModel(
      id: id,
      entityId: contentId,
      scope: TrustScoreScope.content,
      overallScore: 70.0, // Default neutral score
      categoryScores: {
        TrustCategory.engagement: 70.0,
        TrustCategory.userReports: 100.0, // No reports yet
        TrustCategory.contentAnalysis: 70.0,
        TrustCategory.adminReview: 70.0,
        TrustCategory.accountHistory: 70.0,
      },
      updatedAt: now,
      creatorId: creatorId,
      spaceId: spaceId,
      flagCount: 0,
      hasAutoModeration: false,
      hasManualReview: false,
      scoreHistory: {
        now.toIso8601String(): 70.0,
      },
    );
  }
  
  /// Create a new trust score for a user
  factory ContentTrustScoreModel.newUserScore({
    required String userId,
  }) {
    final now = DateTime.now();
    final id = 'trust_user_$userId';
    
    return ContentTrustScoreModel(
      id: id,
      entityId: userId,
      scope: TrustScoreScope.user,
      overallScore: 70.0, // Default neutral score
      categoryScores: {
        TrustCategory.engagement: 70.0,
        TrustCategory.userReports: 100.0, // No reports yet
        TrustCategory.contentAnalysis: 70.0,
        TrustCategory.adminReview: 70.0,
        TrustCategory.accountHistory: 50.0, // New account starts lower
      },
      updatedAt: now,
      creatorId: userId,
      flagCount: 0,
      hasAutoModeration: false,
      hasManualReview: false,
      scoreHistory: {
        now.toIso8601String(): 70.0,
      },
    );
  }
  
  /// Determines if content requires moderation based on trust score
  bool requiresModeration() {
    // Content with overall score below 50 requires moderation
    if (overallScore < 50) return true;
    
    // Content with user reports category below 60 requires moderation
    final userReportsScore = categoryScores[TrustCategory.userReports] ?? 100;
    if (userReportsScore < 60) return true;
    
    // Content with more than 2 flags requires moderation
    if (flagCount > 2) return true;
    
    return false;
  }
  
  /// Determines if content should be automatically hidden
  bool shouldAutoHide() {
    // Content with overall score below 30 should be auto-hidden
    if (overallScore < 30) return true;
    
    // Content with user reports category below 40 should be auto-hidden
    final userReportsScore = categoryScores[TrustCategory.userReports] ?? 100;
    if (userReportsScore < 40) return true;
    
    // Content with more than 5 flags should be auto-hidden
    if (flagCount > 5) return true;
    
    return false;
  }
} 