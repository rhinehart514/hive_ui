import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/analytics/data/models/growth_metrics_model.dart';
import 'package:hive_ui/features/analytics/domain/entities/growth_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/failures/analytics_failures.dart';
import 'package:hive_ui/features/analytics/domain/repositories/growth_metrics_repository.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';

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
  Future<Either<AnalyticsFailure, GrowthMetricsEntity>> getMetricsForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final doc = await _metricsCollection.doc(dateString).get();
      
      if (doc.exists) {
        return Either.right(GrowthMetricsModel.fromFirestore(doc).toEntity());
      } else {
        // Return empty metrics for the date if none exists
        return Either.right(GrowthMetricsModel.empty(date).toEntity());
      }
    } catch (e) {
      debugPrint('Error getting metrics for date: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'getMetricsForDate',
        originalException: e,
        context: date.toString(),
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, List<GrowthMetricsEntity>>> getMetricsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final query = await _metricsCollection
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .get();

      final metrics = query.docs
          .map((doc) => GrowthMetricsModel.fromFirestore(doc).toEntity())
          .toList();
          
      return Either.right(metrics);
    } catch (e) {
      debugPrint('Error getting metrics for date range: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'getMetricsForDateRange',
        originalException: e,
        context: '$startDate to $endDate',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, GrowthMetricsEntity>> getLatestMetrics() async {
    try {
      final query = await _metricsCollection
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Either.right(GrowthMetricsModel.fromFirestore(query.docs.first).toEntity());
      } else {
        // Return empty metrics for today if none exists
        return Either.right(GrowthMetricsModel.empty(DateTime.now()).toEntity());
      }
    } catch (e) {
      debugPrint('Error getting latest metrics: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'getLatestMetrics',
        originalException: e,
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> saveMetrics(GrowthMetricsEntity metrics) async {
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
      
      return Either.right(true);
    } catch (e) {
      debugPrint('Error saving metrics: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'saveMetrics',
        originalException: e,
        context: metrics.date.toString(),
      ));
    }
  }

  @override
  Stream<Either<AnalyticsFailure, GrowthMetricsEntity>> watchLatestMetrics() {
    try {
      return _metricsCollection
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots()
          .map<Either<AnalyticsFailure, GrowthMetricsEntity>>((snapshot) {
            try {
              if (snapshot.docs.isNotEmpty) {
                return Either.right(GrowthMetricsModel.fromFirestore(snapshot.docs.first).toEntity());
              } else {
                return Either.right(GrowthMetricsModel.empty(DateTime.now()).toEntity());
              }
            } catch (e) {
              debugPrint('Error mapping metrics snapshot: $e');
              return Either.left(GrowthMetricsFailure(
                operation: 'watchLatestMetrics.map',
                originalException: e,
              ));
            }
          })
          .handleError((error, stackTrace) {
            debugPrint('Error in watchLatestMetrics stream: $error');
            return Either<AnalyticsFailure, GrowthMetricsEntity>.left(
              GrowthMetricsFailure(
                operation: 'watchLatestMetrics.stream',
                originalException: error,
              ),
            );
          });
    } catch (e) {
      debugPrint('Error setting up metrics stream: $e');
      return Stream.value(Either.left(GrowthMetricsFailure(
        operation: 'watchLatestMetrics.setup',
        originalException: e,
      )));
    }
  }

  @override
  Future<Either<AnalyticsFailure, Map<String, dynamic>>> getGrowthTrends(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final metricsResult = await getMetricsForDateRange(startDate, endDate);
      
      return metricsResult.fold(
        (failure) => Either.left(failure), // Pass the failure through
        (metrics) {
          try {
            if (metrics.isEmpty) {
              return Either.right({
                'userGrowth': 0.0,
                'retentionTrend': 0.0,
                'acquisitionTrend': {},
                'engagementTrend': {},
              });
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
            
            return Either.right({
              'userGrowth': userGrowth,
              'retentionTrend': avgRetention,
              'acquisitionTrend': acquisitionTrend,
              'engagementTrend': engagementTrend,
            });
          } catch (e) {
            debugPrint('Error calculating growth trends: $e');
            return Either.left(GrowthMetricsFailure(
              operation: 'getGrowthTrends.calculate',
              originalException: e,
              context: '$days days',
            ));
          }
        }
      );
    } catch (e) {
      debugPrint('Error getting growth trends: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'getGrowthTrends',
        originalException: e,
        context: '$days days',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> updateAcquisitionChannel(DateTime date, String channel, int count) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'acquisitionChannels.$channel': count,
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error updating acquisition channel: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'updateAcquisitionChannel',
        originalException: e,
        context: '$date, $channel, $count',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> incrementAcquisitionChannel(DateTime date, String channel) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'acquisitionChannels.$channel': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error incrementing acquisition channel: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'incrementAcquisitionChannel',
        originalException: e,
        context: '$date, $channel',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> updateUserSegment(DateTime date, String segment, int count) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'userSegments.$segment': count,
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error updating user segment: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'updateUserSegment',
        originalException: e,
        context: '$date, $segment, $count',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> incrementUserSegment(DateTime date, String segment) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'userSegments.$segment': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error incrementing user segment: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'incrementUserSegment',
        originalException: e,
        context: '$date, $segment',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> updateEngagementMetric(DateTime date, String metric, double value) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'engagementMetrics.$metric': value,
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error updating engagement metric: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'updateEngagementMetric',
        originalException: e,
        context: '$date, $metric, $value',
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> incrementDailyActiveUsers(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'dailyActiveUsers': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error incrementing daily active users: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'incrementDailyActiveUsers',
        originalException: e,
        context: date.toString(),
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> incrementNewUsers(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'newUsers': FieldValue.increment(1),
        'totalUsers': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error incrementing new users: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'incrementNewUsers',
        originalException: e,
        context: date.toString(),
      ));
    }
  }

  @override
  Future<Either<AnalyticsFailure, bool>> incrementReturningUsers(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _metricsCollection.doc(dateString).update({
        'returningUsers': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return Either.right(true);
    } catch (e) {
      debugPrint('Error incrementing returning users: $e');
      return Either.left(GrowthMetricsFailure(
        operation: 'incrementReturningUsers',
        originalException: e,
        context: date.toString(),
      ));
    }
  }
} 