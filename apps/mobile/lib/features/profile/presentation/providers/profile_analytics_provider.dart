import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_analytics.dart';
import 'package:hive_ui/core/config/api_config.dart';

/// Provider for the selected date range
final selectedDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  // Default to last 30 days
  return DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
});

/// Provider to track if real-time updates are enabled
final realTimeUpdatesEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for fetching profile analytics within a date range
final profileAnalyticsProvider = FutureProvider.family<ProfileAnalytics, ({String userId, DateTimeRange range})>((ref, params) async {
  try {
    // Get analytics document from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(params.userId)
        .collection('analytics')
        .doc('profile')
        .get();

    if (!doc.exists) {
      return ProfileAnalytics.empty();
    }

    final data = doc.data() as Map<String, dynamic>;
    
    // Get activity logs for the date range
    final activityLogs = await FirebaseFirestore.instance
        .collection('users')
        .doc(params.userId)
        .collection('activity_logs')
        .where('timestamp', isGreaterThanOrEqualTo: params.range.start)
        .where('timestamp', isLessThanOrEqualTo: params.range.end)
        .orderBy('timestamp', descending: true)
        .get();

    // Calculate metrics for the selected date range
    final monthlyActivity = <String, int>{};
    final peakHours = <int, int>{};
    var totalEvents = 0;
    var totalSpaces = 0;
    var totalContent = 0;
    var totalConnections = 0;

    for (final log in activityLogs.docs) {
      final logData = log.data();
      final timestamp = (logData['timestamp'] as Timestamp).toDate();
      final month = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      final hour = timestamp.hour;

      monthlyActivity[month] = (monthlyActivity[month] ?? 0) + 1;
      peakHours[hour] = (peakHours[hour] ?? 0) + 1;

      switch (logData['type']) {
        case 'event_attendance':
          totalEvents++;
          break;
        case 'space_participation':
          totalSpaces++;
          break;
        case 'content_interaction':
          totalContent++;
          break;
        case 'connection':
          totalConnections++;
          break;
      }
    }

    // Calculate rates
    final daysDiff = params.range.duration.inDays;
    final eventRate = totalEvents / (daysDiff / 7); // Weekly rate
    final spaceRate = totalSpaces / (daysDiff / 7); // Weekly rate
    final contentRate = totalContent / (daysDiff / 7); // Weekly rate
    final connectionGrowth = (totalConnections / (data['totalConnections'] as int)) * 100;

    // Get top spaces and events for the period
    final topSpaces = await FirebaseFirestore.instance
        .collection('users')
        .doc(params.userId)
        .collection('space_interactions')
        .where('lastInteraction', isGreaterThanOrEqualTo: params.range.start)
        .orderBy('lastInteraction', descending: true)
        .orderBy('interactionCount', descending: true)
        .limit(3)
        .get();

    final topEvents = await FirebaseFirestore.instance
        .collection('users')
        .doc(params.userId)
        .collection('event_attendance')
        .where('timestamp', isGreaterThanOrEqualTo: params.range.start)
        .orderBy('timestamp', descending: true)
        .limit(3)
        .get();

    // Return analytics with date range specific data
    return ProfileAnalytics(
      engagementScore: ((eventRate + spaceRate + contentRate) / 3 * 100).round(),
      recentProfileViews: data['recentProfileViews'] as int? ?? 0,
      recentSearchAppearances: data['recentSearchAppearances'] as int? ?? 0,
      eventAttendanceRate: eventRate / 10, // Normalize to 0-1
      spaceParticipationRate: spaceRate / 10, // Normalize to 0-1
      connectionGrowthRate: connectionGrowth,
      contentEngagementRate: contentRate / 10, // Normalize to 0-1
      topActiveSpaces: topSpaces.docs.map((doc) => doc.data()['spaceName'] as String).toList(),
      topEventTypes: topEvents.docs.map((doc) => doc.data()['eventType'] as String).toList(),
      topConnections: (data['topConnections'] as List<dynamic>?)?.cast<String>() ?? [],
      peakActivityHours: () {
        final sortedEntries = peakHours.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return sortedEntries
          .take(5)
          .map((e) => e.key)
          .toList();
      }(),
      monthlyActivity: monthlyActivity,
    );
  } catch (e) {
    // Return empty analytics on error
    return ProfileAnalytics.empty();
  }
});

/// WebSocket channel for real-time updates
final _websocketChannelProvider = Provider.family<WebSocketChannel, String>((ref, userId) {
  final uri = Uri.parse('${ApiConfig.webSocketBaseUrl}/analytics/$userId');
  return WebSocketChannel.connect(uri);
});

/// Provider for real-time profile analytics updates
final profileAnalyticsStreamProvider = StreamProvider.family<ProfileAnalytics, ({String userId, DateTimeRange range})>((ref, params) {
  final isRealTimeEnabled = ref.watch(realTimeUpdatesEnabledProvider);
  
  if (isRealTimeEnabled) {
    // Connect to WebSocket for real-time updates
    final channel = ref.watch(_websocketChannelProvider(params.userId));
    
    // Send initial request with date range
    channel.sink.add({
      'type': 'subscribe',
      'userId': params.userId,
      'dateRange': {
        'start': params.range.start.millisecondsSinceEpoch,
        'end': params.range.end.millisecondsSinceEpoch,
      }
    });

    // Transform WebSocket messages to ProfileAnalytics objects
    return channel.stream.asyncMap<ProfileAnalytics>((data) {
      if (data is Map<String, dynamic>) {
        // Handle incoming analytics data
        return ProfileAnalytics(
          engagementScore: data['engagementScore'] as int? ?? 0,
          recentProfileViews: data['recentProfileViews'] as int? ?? 0,
          recentSearchAppearances: data['recentSearchAppearances'] as int? ?? 0,
          eventAttendanceRate: (data['eventAttendanceRate'] as num?)?.toDouble() ?? 0.0,
          spaceParticipationRate: (data['spaceParticipationRate'] as num?)?.toDouble() ?? 0.0,
          connectionGrowthRate: (data['connectionGrowthRate'] as num?)?.toDouble() ?? 0.0,
          contentEngagementRate: (data['contentEngagementRate'] as num?)?.toDouble() ?? 0.0,
          topActiveSpaces: (data['topActiveSpaces'] as List<dynamic>?)?.cast<String>() ?? [],
          topEventTypes: (data['topEventTypes'] as List<dynamic>?)?.cast<String>() ?? [],
          topConnections: (data['topConnections'] as List<dynamic>?)?.cast<String>() ?? [],
          peakActivityHours: (data['peakActivityHours'] as List<dynamic>?)?.map((h) => (h as num).toInt()).toList() ?? [],
          monthlyActivity: (data['monthlyActivity'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt())
          ) ?? {},
        );
      }
      
      // Return empty analytics for invalid data
      return ProfileAnalytics.empty();
    });
  } else {
    // Fall back to Firestore for non-real-time updates
    return FirebaseFirestore.instance
      .collection('users')
      .doc(params.userId)
      .collection('analytics')
      .doc('profile')
      .snapshots()
      .asyncMap((doc) async {
        if (!doc.exists) {
          return ProfileAnalytics.empty();
        }

        // Re-fetch analytics with the current date range
        return ref.read(profileAnalyticsProvider(params).future);
      });
  }
});

/// Provider for mock analytics data (for development)
final mockProfileAnalyticsProvider = Provider.family<ProfileAnalytics, String>((ref, userId) {
  final range = ref.watch(selectedDateRangeProvider);
  final now = DateTime.now();
  
  // Generate mock monthly activity data for the selected range
  final monthlyActivity = <String, int>{};
  var current = range.start;
  while (current.isBefore(range.end)) {
    final month = '${current.year}-${current.month.toString().padLeft(2, '0')}';
    monthlyActivity[month] = 45 + (current.month * 5); // Mock increasing trend
    current = DateTime(current.year, current.month + 1);
  }

  // Return mock data
  return ProfileAnalytics(
    engagementScore: 85,
    recentProfileViews: 127,
    recentSearchAppearances: 45,
    eventAttendanceRate: 0.75,
    spaceParticipationRate: 0.65,
    connectionGrowthRate: 12.5,
    contentEngagementRate: 0.82,
    topActiveSpaces: const [
      'Computer Science Club',
      'AI Research Group',
      'Mobile Dev Society',
    ],
    topEventTypes: const [
      'Tech Workshops',
      'Hackathons',
      'Study Groups',
    ],
    topConnections: const [
      'John Doe',
      'Jane Smith',
      'Alex Johnson',
      'Sarah Wilson',
      'Mike Brown',
    ],
    peakActivityHours: const [14, 15, 16, 20, 21], // 2-4 PM and 8-9 PM
    monthlyActivity: monthlyActivity,
  );
}); 