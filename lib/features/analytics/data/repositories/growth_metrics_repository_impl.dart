import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/analytics/data/models/growth_metrics_model.dart';
import 'package:hive_ui/features/analytics/domain/entities/growth_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/repositories/growth_metrics_repository.dart';

/// Implementation of the GrowthMetricsRepository
class GrowthMetricsRepositoryImpl implements GrowthMetricsRepository {
  final FirebaseFirestore _firestore;

  GrowthMetricsRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for growth metrics
  CollectionReference<Map<String, dynamic>> get _metricsCollection =>
      _firestore.collection('growth_metrics');

  @override
  Future<GrowthMetricsEntity> getMetricsForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final doc = await _metricsCollection.doc(dateString).get();
      
      if (doc.exists) {
        return GrowthMetricsModel.fromFirestore(doc).toEntity();
      } else {
        // Return empty metrics for the date if none exists
        return GrowthMetricsModel.empty(date).toEntity();
      }
    } catch (e) {
      throw Exception('Failed to get metrics for date: $e');
    }
  }

  @override
  Future<List<GrowthMetricsEntity>> getMetricsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final query = await _metricsCollection
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .get();

      return query.docs
          .map((doc) => GrowthMetricsModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get metrics for date range: $e');
    }
  }

  @override
  Future<GrowthMetricsEntity> getLatestMetrics() async {
    try {
      final query = await _metricsCollection
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return GrowthMetricsModel.fromFirestore(query.docs.first).toEntity();
      } else {
        // Return empty metrics for today if none exists
        return GrowthMetricsModel.empty(DateTime.now()).toEntity();
      }
    } catch (e) {
      throw Exception('Failed to get latest metrics: $e');
    }
  }

  @override
  Future<void> saveMetrics(GrowthMetricsEntity metrics) async {
    try {
      // Convert entity to model
      final model = GrowthMetricsModel(
        id: metrics.id,
        date: metrics.date,
        dailyActiveUsers: metrics.dailyActiveUsers,
        weeklyActiveUsers: metrics.weeklyActiveUsers,
        monthlyActiveUsers: metrics.monthlyActiveUsers,
        totalUsers: metrics.totalUsers,
        newUsers: metrics.newUsers,
        returningUsers: metrics.returningUsers,
        retentionRate: metrics.retentionRate,
        acquisitionChannels: metrics.acquisitionChannels,
        userSegments: metrics.userSegments,
        engagementMetrics: metrics.engagementMetrics,
        additionalMetrics: metrics.additionalMetrics,
      );
      
      // Use date string as document ID for consistency
      final dateString = metrics.date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).set(model.toJson());
    } catch (e) {
      throw Exception('Failed to save metrics: $e');
    }
  }

  @override
  Stream<GrowthMetricsEntity> watchLatestMetrics() {
    try {
      return _metricsCollection
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return GrowthMetricsModel.fromFirestore(snapshot.docs.first).toEntity();
            } else {
              return GrowthMetricsModel.empty(DateTime.now()).toEntity();
            }
          });
    } catch (e) {
      throw Exception('Failed to watch latest metrics: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getGrowthTrends(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final metrics = await getMetricsForDateRange(startDate, endDate);
      
      if (metrics.isEmpty) {
        return {
          'userGrowth': 0.0,
          'retentionTrend': 0.0,
          'acquisitionTrend': {},
          'engagementTrend': {},
        };
      }
      
      // Calculate user growth trend
      final oldestMetrics = metrics.first;
      final newestMetrics = metrics.last;
      final userGrowth = oldestMetrics.totalUsers > 0 
          ? (newestMetrics.totalUsers - oldestMetrics.totalUsers) / oldestMetrics.totalUsers
          : 0.0;
      
      // Calculate retention trend
      final retentionValues = metrics.map((m) => m.retentionRate).toList();
      final avgRetention = retentionValues.isNotEmpty 
          ? retentionValues.reduce((a, b) => a + b) / retentionValues.length
          : 0.0;
      
      // Aggregate acquisition channels
      final acquisitionTrend = <String, int>{};
      for (final metric in metrics) {
        for (final entry in metric.acquisitionChannels.entries) {
          acquisitionTrend[entry.key] = (acquisitionTrend[entry.key] ?? 0) + entry.value;
        }
      }
      
      // Aggregate engagement metrics
      final engagementTrend = <String, double>{};
      for (final metric in metrics) {
        for (final entry in metric.engagementMetrics.entries) {
          engagementTrend[entry.key] = (engagementTrend[entry.key] ?? 0.0) + entry.value;
        }
      }
      // Average the engagement metrics
      for (final key in engagementTrend.keys) {
        engagementTrend[key] = engagementTrend[key]! / metrics.length;
      }
      
      return {
        'userGrowth': userGrowth,
        'retentionTrend': avgRetention,
        'acquisitionTrend': acquisitionTrend,
        'engagementTrend': engagementTrend,
      };
    } catch (e) {
      throw Exception('Failed to get growth trends: $e');
    }
  }

  @override
  Future<void> updateAcquisitionChannel(DateTime date, String channel, int count) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'acquisitionChannels.$channel': count,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update acquisition channel: $e');
    }
  }

  @override
  Future<void> incrementAcquisitionChannel(DateTime date, String channel) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'acquisitionChannels.$channel': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment acquisition channel: $e');
    }
  }

  @override
  Future<void> updateUserSegment(DateTime date, String segment, int count) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'userSegments.$segment': count,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update user segment: $e');
    }
  }

  @override
  Future<void> incrementUserSegment(DateTime date, String segment) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'userSegments.$segment': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment user segment: $e');
    }
  }

  @override
  Future<void> updateEngagementMetric(DateTime date, String metric, double value) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'engagementMetrics.$metric': value,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update engagement metric: $e');
    }
  }

  @override
  Future<void> incrementDailyActiveUsers(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'dailyActiveUsers': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment daily active users: $e');
    }
  }

  @override
  Future<void> incrementNewUsers(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'newUsers': FieldValue.increment(1),
        'totalUsers': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment new users: $e');
    }
  }

  @override
  Future<void> incrementReturningUsers(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'returningUsers': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment returning users: $e');
    }
  }
} 