import 'package:hive_ui/features/feed/domain/models/feed_intelligence_params.dart';
import 'package:hive_ui/features/feed/domain/models/user_trail.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/reposted_event.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';
import 'package:hive_ui/features/feed/domain/failures/feed_failures.dart';

/// Service for feed intelligence operations including scoring and personalization
abstract class FeedIntelligenceService {
  /// Calculate base score for a content item based on recency, relevance, engagement, etc.
  /// 
  /// [content] The content item to score
  /// [params] Configuration parameters for scoring algorithm
  double calculateBaseScore(Map<String, dynamic> content, FeedIntelligenceParams params);
  
  /// Apply personalization to a base score based on user trail
  /// 
  /// [baseScore] Initial base score
  /// [content] The content item
  /// [trail] User's activity history
  /// [params] Configuration parameters
  double applyPersonalization(double baseScore, Map<String, dynamic> content, UserTrail trail, FeedIntelligenceParams params);
  
  /// Apply time-sensitivity adjustments to a score
  /// 
  /// [score] Current score
  /// [content] The content item
  /// [params] Configuration parameters
  double applyTimeSensitivity(double score, Map<String, dynamic> content, FeedIntelligenceParams params);
  
  /// Determine user's archetype based on trail data
  /// 
  /// [trail] User's activity history
  UserArchetype determineUserArchetype(UserTrail trail);
  
  /// Get recommended configuration based on user archetype
  /// 
  /// [archetype] The user's behavior archetype
  FeedIntelligenceParams getConfigForArchetype(UserArchetype archetype);
  
  /// Score and sort a list of feed items
  /// 
  /// [items] Content items to score and sort
  /// [trail] User's activity history
  /// [params] Configuration parameters
  /// Returns sorted list of scored items
  Future<Either<FeedFailure, List<Map<String, dynamic>>>> scoreAndSortFeedItems(
    List<Map<String, dynamic>> items,
    UserTrail trail,
    FeedIntelligenceParams params,
  );
  
  /// Apply diversity injection to ensure feed has content outside user's direct network
  /// 
  /// [items] Scored and sorted items
  /// [trail] User's activity history
  /// [params] Configuration parameters
  /// Returns list with diversity items injected
  Future<Either<FeedFailure, List<Map<String, dynamic>>>> applyDiversityInjection(
    List<Map<String, dynamic>> items,
    UserTrail trail,
    FeedIntelligenceParams params,
  );
  
  /// Get intelligence parameters for the current user
  /// 
  /// [userId] The user ID
  /// [trail] User's activity history if available
  Future<Either<FeedFailure, FeedIntelligenceParams>> getIntelligenceParams(
    String userId, 
    UserTrail? trail,
  );
  
  /// Get or create user trail
  /// 
  /// [userId] The user ID
  Future<Either<FeedFailure, UserTrail>> getUserTrail(String userId);
  
  /// Apply feed intelligence to a list of mixed content
  /// 
  /// [feedItems] List of content items (events, reposts, spaces, etc.)
  /// [userId] Current user ID
  Future<Either<FeedFailure, List<Map<String, dynamic>>>> applyFeedIntelligence(
    List<Map<String, dynamic>> feedItems,
    String userId,
  );
} 