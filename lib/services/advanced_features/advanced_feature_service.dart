import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service providing advanced data capabilities including recommendations,
/// content analytics, and user behavior prediction
class AdvancedFeatureService {
  // Singleton instance
  static final AdvancedFeatureService _instance = AdvancedFeatureService._internal();

  // Factory constructor to return singleton instance
  factory AdvancedFeatureService() => _instance;

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Feature flags
  bool _recommendationsEnabled = true;
  bool _analyticsEnabled = true;
  bool _predictionEnabled = true;
  
  // Cached data
  final Map<String, dynamic> _userInteractionCache = {};
  final Map<String, List<String>> _recommendationCache = {};
  
  // Refresh timers
  Timer? _recommendationRefreshTimer;
  
  // Stream controllers
  final StreamController<List<String>> _personalizedContentController = 
      StreamController<List<String>>.broadcast();
  
  // User preferences
  late SharedPreferences _prefs;
  
  // ML model simple weights
  final Map<String, double> _contentTypeWeights = {
    'post': 1.0,
    'event': 1.5,
    'announcement': 1.2,
    'space': 2.0,
  };
  
  // Internal constructor
  AdvancedFeatureService._internal() {
    _initialize();
  }
  
  // Stream getters
  Stream<List<String>> get personalizedContentStream => _personalizedContentController.stream;
  
  /// Initialize the service
  Future<void> _initialize() async {
    try {
      // Load shared preferences
      _prefs = await SharedPreferences.getInstance();
      
      // Load feature flags
      _loadFeatureFlags();
      
      // Start refresh timers
      _startRefreshTimers();
      
      debugPrint('Advanced Feature Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Advanced Feature Service: $e');
    }
  }
  
  /// Load feature flags from preferences
  void _loadFeatureFlags() {
    _recommendationsEnabled = _prefs.getBool('advanced_recommendations_enabled') ?? true;
    _analyticsEnabled = _prefs.getBool('advanced_analytics_enabled') ?? true;
    _predictionEnabled = _prefs.getBool('advanced_prediction_enabled') ?? true;
  }
  
  /// Set feature flags
  Future<void> setFeatureFlags({
    bool? recommendationsEnabled,
    bool? analyticsEnabled,
    bool? predictionEnabled,
  }) async {
    if (recommendationsEnabled != null) {
      _recommendationsEnabled = recommendationsEnabled;
      await _prefs.setBool('advanced_recommendations_enabled', recommendationsEnabled);
    }
    
    if (analyticsEnabled != null) {
      _analyticsEnabled = analyticsEnabled;
      await _prefs.setBool('advanced_analytics_enabled', analyticsEnabled);
    }
    
    if (predictionEnabled != null) {
      _predictionEnabled = predictionEnabled;
      await _prefs.setBool('advanced_prediction_enabled', predictionEnabled);
    }
  }
  
  /// Start refresh timers for cache maintenance
  void _startRefreshTimers() {
    // Refresh recommendations every 30 minutes
    _recommendationRefreshTimer?.cancel();
    _recommendationRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _refreshRecommendations();
    });
  }
  
  /// Refresh recommendations
  Future<void> _refreshRecommendations() async {
    if (!_recommendationsEnabled) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      // Clear existing cache
      _recommendationCache[userId] = [];
      
      // Get new recommendations
      final recommendations = await getContentRecommendations(limit: 20);
      
      // Update cache
      _recommendationCache[userId] = recommendations;
      
      // Emit new recommendations
      _personalizedContentController.add(recommendations);
    } catch (e) {
      debugPrint('Error refreshing recommendations: $e');
    }
  }
  
  /// Record a user interaction with content
  Future<void> recordInteraction({
    required String contentId,
    required String contentType,
    required String interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_analyticsEnabled) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final timestamp = DateTime.now();
      
      // Add to interaction cache
      final key = '$userId:$contentId:$interactionType';
      _userInteractionCache[key] = {
        'timestamp': timestamp,
        'contentId': contentId,
        'contentType': contentType,
        'interactionType': interactionType,
        'metadata': metadata ?? {},
      };
      
      // Record to Firestore
      await _firestore.collection('user_interactions').add({
        'userId': userId,
        'contentId': contentId,
        'contentType': contentType,
        'interactionType': interactionType,
        'timestamp': timestamp,
        'metadata': metadata ?? {},
      });
      
      // Optional: Invalidate recommendation cache to force refresh
      if (['like', 'save', 'share'].contains(interactionType)) {
        _recommendationCache.remove(userId);
      }
    } catch (e) {
      debugPrint('Error recording interaction: $e');
    }
  }
  
  /// Get personalized content recommendations
  Future<List<String>> getContentRecommendations({
    int limit = 10,
    List<String>? contentTypes,
    Map<String, dynamic>? filters,
  }) async {
    if (!_recommendationsEnabled) return [];
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    
    // Check cache first
    if (_recommendationCache.containsKey(userId) && 
        _recommendationCache[userId]!.isNotEmpty) {
      final cached = _recommendationCache[userId]!;
      return cached.take(limit).toList();
    }
    
    try {
      // In a real implementation, this would use a more sophisticated recommendation algorithm
      // Here we're using a simple approach based on recent user interactions and preferences
      
      // Get user interactions
      final interactionsSnap = await _firestore
          .collection('user_interactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      // Extract content IDs and types
      final interactedContentIds = <String>{};
      final interactionsByType = <String, int>{};
      
      for (final doc in interactionsSnap.docs) {
        final data = doc.data();
        final contentId = data['contentId'] as String;
        final contentType = data['contentType'] as String;
        
        interactedContentIds.add(contentId);
        interactionsByType[contentType] = (interactionsByType[contentType] ?? 0) + 1;
      }
      
      // Determine content type weights based on user's past interactions
      final weights = Map<String, double>.from(_contentTypeWeights);
      int totalInteractions = 0;
      
      interactionsByType.forEach((type, count) {
        totalInteractions += count;
      });
      
      if (totalInteractions > 0) {
        interactionsByType.forEach((type, count) {
          final ratio = count / totalInteractions;
          weights[type] = (weights[type] ?? 1.0) * (1 + ratio);
        });
      }
      
      // Query for content based on weighted selection
      final List<String> recommendedIds = [];
      
      // Filter content types if specified
      final typesToQuery = contentTypes ?? weights.keys.toList();
      
      for (final contentType in typesToQuery) {
        final weight = weights[contentType] ?? 1.0;
        final typeLimit = (limit * weight).round().clamp(1, limit);
        
        // Skip if the weight results in 0 items
        if (typeLimit <= 0) continue;
        
        // Build query
        Query<Map<String, dynamic>> query = _firestore.collection(contentType);
        
        // Add filters if provided
        if (filters != null) {
          filters.forEach((key, value) {
            query = query.where(key, isEqualTo: value);
          });
        }
        
        // Exclude already interacted content
        if (interactedContentIds.isNotEmpty) {
          query = query.where(FieldPath.documentId, 
            whereNotIn: interactedContentIds.take(10).toList());
        }
        
        final snap = await query.limit(typeLimit).get();
        
        for (final doc in snap.docs) {
          recommendedIds.add(doc.id);
        }
      }
      
      // If we didn't get enough recommendations, add some popular content
      if (recommendedIds.length < limit) {
        final popularSnap = await _firestore
            .collection('trending_content')
            .orderBy('score', descending: true)
            .limit(limit - recommendedIds.length)
            .get();
        
        for (final doc in popularSnap.docs) {
          final contentId = doc.data()['contentId'] as String;
          if (!recommendedIds.contains(contentId)) {
            recommendedIds.add(contentId);
          }
        }
      }
      
      // Cache results
      _recommendationCache[userId] = recommendedIds;
      
      return recommendedIds.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting content recommendations: $e');
      return [];
    }
  }
  
  /// Predict user engagement with a specific content item
  Future<double> predictEngagement(String contentId, String contentType) async {
    if (!_predictionEnabled) return 0.5; // Neutral score if disabled
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0.5;
    
    try {
      // In a real implementation, this would use machine learning models
      // Here we're using a simple heuristic based on past interactions
      
      // Get user's past interactions with similar content
      final interactionsSnap = await _firestore
          .collection('user_interactions')
          .where('userId', isEqualTo: userId)
          .where('contentType', isEqualTo: contentType)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      if (interactionsSnap.docs.isEmpty) {
        return 0.5; // Neutral score if no history
      }
      
      // Count positive interactions
      int positiveInteractions = 0;
      int totalInteractions = interactionsSnap.docs.length;
      
      for (final doc in interactionsSnap.docs) {
        final interactionType = doc.data()['interactionType'] as String;
        
        // Consider these interaction types as positive signals
        if (['like', 'save', 'share', 'comment', 'rsvp'].contains(interactionType)) {
          positiveInteractions++;
        }
      }
      
      // Calculate engagement score
      final baseScore = positiveInteractions / totalInteractions;
      
      // Add some randomness to prevent echo chambers
      final randomFactor = 0.1 * (Random().nextDouble() - 0.5);
      
      return (baseScore + randomFactor).clamp(0.1, 0.9);
    } catch (e) {
      debugPrint('Error predicting engagement: $e');
      return 0.5;
    }
  }
  
  /// Get analytics for content performance
  Future<Map<String, dynamic>> getContentAnalytics(String contentId) async {
    if (!_analyticsEnabled) return {};
    
    try {
      // Get interaction data for this content
      final interactionsSnap = await _firestore
          .collection('user_interactions')
          .where('contentId', isEqualTo: contentId)
          .get();
      
      // Analyze interactions
      int views = 0;
      int likes = 0;
      int comments = 0;
      int shares = 0;
      int bookmarks = 0;
      final interactionsByHour = <int, int>{};
      
      for (final doc in interactionsSnap.docs) {
        final data = doc.data();
        final interactionType = data['interactionType'] as String;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final hour = timestamp.hour;
        
        // Count by interaction type
        switch (interactionType) {
          case 'view':
            views++;
            break;
          case 'like':
            likes++;
            break;
          case 'comment':
            comments++;
            break;
          case 'share':
            shares++;
            break;
          case 'save':
            bookmarks++;
            break;
        }
        
        // Add to hourly distribution
        interactionsByHour[hour] = (interactionsByHour[hour] ?? 0) + 1;
      }
      
      // Calculate engagement rate
      final totalInteractions = views + likes + comments + shares + bookmarks;
      final engagementRate = views > 0 ? (likes + comments + shares) / views : 0.0;
      
      // Compile analytics result
      return {
        'totalInteractions': totalInteractions,
        'views': views,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'bookmarks': bookmarks,
        'engagementRate': engagementRate,
        'interactionsByHour': interactionsByHour,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error getting content analytics: $e');
      return {};
    }
  }
  
  /// Get user interests based on interaction history
  Future<Map<String, double>> getUserInterests() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};
    
    try {
      // Get user's interactions
      final interactionsSnap = await _firestore
          .collection('user_interactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      if (interactionsSnap.docs.isEmpty) {
        return {};
      }
      
      // Analyze interaction data to extract interests
      final Map<String, int> interactionsByTag = {};
      final Map<String, int> interactionsByCategory = {};
      
      for (final doc in interactionsSnap.docs) {
        final data = doc.data();
        final contentId = data['contentId'] as String;
        final interactionType = data['interactionType'] as String;
        
        // Skip view interactions which are less meaningful
        if (interactionType == 'view') continue;
        
        // Get content details
        final contentType = data['contentType'] as String;
        final contentSnap = await _firestore.collection(contentType).doc(contentId).get();
        
        if (!contentSnap.exists) continue;
        
        // Extract tags and categories
        final contentData = contentSnap.data() ?? {};
        final tags = contentData['tags'] as List<dynamic>? ?? [];
        final category = contentData['category'] as String? ?? 'uncategorized';
        
        // Update counts
        for (final tag in tags) {
          if (tag is String) {
            interactionsByTag[tag] = (interactionsByTag[tag] ?? 0) + 1;
          }
        }
        
        interactionsByCategory[category] = (interactionsByCategory[category] ?? 0) + 1;
      }
      
      // Convert to interest scores
      final Map<String, double> interests = {};
      int totalTagInteractions = 0;
      int totalCategoryInteractions = 0;
      
      interactionsByTag.forEach((_, count) => totalTagInteractions += count);
      interactionsByCategory.forEach((_, count) => totalCategoryInteractions += count);
      
      // Normalize tag scores
      if (totalTagInteractions > 0) {
        interactionsByTag.forEach((tag, count) {
          interests['tag:$tag'] = count / totalTagInteractions;
        });
      }
      
      // Normalize category scores
      if (totalCategoryInteractions > 0) {
        interactionsByCategory.forEach((category, count) {
          interests['category:$category'] = count / totalCategoryInteractions;
        });
      }
      
      return interests;
    } catch (e) {
      debugPrint('Error getting user interests: $e');
      return {};
    }
  }
  
  /// Clear all caches
  void clearCaches() {
    _userInteractionCache.clear();
    _recommendationCache.clear();
  }
  
  /// Dispose resources
  void dispose() {
    _recommendationRefreshTimer?.cancel();
    _personalizedContentController.close();
  }
} 