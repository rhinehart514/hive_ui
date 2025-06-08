/// Base abstract class for recommendation algorithms
abstract class RecommendationAlgorithmEntity {
  /// Unique identifier for the algorithm
  final String id;
  
  /// Name of the algorithm
  final String name;
  
  /// Description of how the algorithm works
  final String description;
  
  /// Version of the algorithm
  final String version;
  
  /// Whether the algorithm is currently active
  final bool isActive;
  
  /// The weight or importance of this algorithm in a combined strategy
  final double weight;
  
  /// Constructor
  const RecommendationAlgorithmEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.isActive,
    required this.weight,
  });
  
  /// Calculate the recommendation score for an item
  /// This method must be implemented by concrete algorithm classes
  double calculateScore(dynamic item, dynamic userContext);
  
  /// Check if this algorithm applies to a specific item
  /// This method must be implemented by concrete algorithm classes
  bool appliesToItem(dynamic item);
}

/// Content-based filtering algorithm that recommends items similar to what a user has liked before
class ContentBasedRecommendationEntity extends RecommendationAlgorithmEntity {
  /// The feature extraction strategy used by this algorithm
  final FeatureExtractionStrategy featureExtractionStrategy;
  
  /// The similarity measure used by this algorithm
  final SimilarityMeasure similarityMeasure;
  
  /// The minimum similarity threshold for recommendations
  final double minimumSimilarityThreshold;
  
  /// Constructor
  const ContentBasedRecommendationEntity({
    required super.id,
    required super.name,
    required super.description,
    required super.version,
    required super.isActive,
    required super.weight,
    required this.featureExtractionStrategy,
    required this.similarityMeasure,
    required this.minimumSimilarityThreshold,
  });
  
  @override
  double calculateScore(dynamic item, dynamic userContext) {
    // Implementation would extract features from items and compare to user preferences
    // This is a simplified placeholder implementation
    return 0.0;
  }
  
  @override
  bool appliesToItem(dynamic item) {
    // Check if this algorithm can be applied to the given item type
    // This is a simplified placeholder implementation
    return true;
  }
}

/// Collaborative filtering algorithm that recommends items based on similar users' preferences
class CollaborativeRecommendationEntity extends RecommendationAlgorithmEntity {
  /// The neighborhood size for user similarity calculations
  final int neighborhoodSize;
  
  /// The minimum number of interactions needed for recommendations
  final int minimumInteractions;
  
  /// Whether to use user-based (vs item-based) collaborative filtering
  final bool userBased;
  
  /// Constructor
  const CollaborativeRecommendationEntity({
    required super.id,
    required super.name,
    required super.description,
    required super.version,
    required super.isActive,
    required super.weight,
    required this.neighborhoodSize,
    required this.minimumInteractions,
    required this.userBased,
  });
  
  @override
  double calculateScore(dynamic item, dynamic userContext) {
    // Implementation would find similar users and calculate prediction scores
    // This is a simplified placeholder implementation
    return 0.0;
  }
  
  @override
  bool appliesToItem(dynamic item) {
    // Check if this algorithm can be applied to the given item type
    // This is a simplified placeholder implementation
    return true;
  }
}

/// Social graph-based recommendation algorithm that leverages social connections
class SocialGraphRecommendationEntity extends RecommendationAlgorithmEntity {
  /// The social distance weight factor
  final double socialDistanceWeight;
  
  /// The interaction similarity weight factor
  final double interactionSimilarityWeight;
  
  /// The maximum graph depth to explore
  final int maxGraphDepth;
  
  /// Constructor
  const SocialGraphRecommendationEntity({
    required super.id,
    required super.name,
    required super.description,
    required super.version,
    required super.isActive,
    required super.weight,
    required this.socialDistanceWeight,
    required this.interactionSimilarityWeight,
    required this.maxGraphDepth,
  });
  
  @override
  double calculateScore(dynamic item, dynamic userContext) {
    // Implementation would analyze social connections and calculate a recommendation score
    // This is a simplified placeholder implementation
    return 0.0;
  }
  
  @override
  bool appliesToItem(dynamic item) {
    // Check if this algorithm can be applied to the given item type
    // This is a simplified placeholder implementation
    return true;
  }
}

/// Contextual recommendation algorithm that considers user's current context
class ContextualRecommendationEntity extends RecommendationAlgorithmEntity {
  /// The location relevance weight factor
  final double locationRelevanceWeight;
  
  /// The time relevance weight factor
  final double timeRelevanceWeight;
  
  /// The activity relevance weight factor
  final double activityRelevanceWeight;
  
  /// Constructor
  const ContextualRecommendationEntity({
    required super.id,
    required super.name,
    required super.description,
    required super.version,
    required super.isActive,
    required super.weight,
    required this.locationRelevanceWeight,
    required this.timeRelevanceWeight,
    required this.activityRelevanceWeight,
  });
  
  @override
  double calculateScore(dynamic item, dynamic userContext) {
    // Implementation would analyze user's current context and item relevance
    // This is a simplified placeholder implementation
    return 0.0;
  }
  
  @override
  bool appliesToItem(dynamic item) {
    // Check if this algorithm can be applied to the given item type
    // This is a simplified placeholder implementation
    return true;
  }
}

/// Feature extraction strategies for content-based filtering
enum FeatureExtractionStrategy {
  /// TF-IDF text feature extraction
  tfIdf,
  
  /// Embedding-based feature extraction
  embeddings,
  
  /// Category-based feature extraction
  categories,
  
  /// Tag-based feature extraction
  tags,
}

/// Similarity measures for recommendation algorithms
enum SimilarityMeasure {
  /// Cosine similarity
  cosine,
  
  /// Pearson correlation
  pearson,
  
  /// Euclidean distance
  euclidean,
  
  /// Jaccard similarity
  jaccard,
} 