import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for storing aggregated metrics for a user's profile and activities
class UserMetricsModel {
  final String userId;
  final int profileViews;
  final int contentCreated;
  final int contentEngagement; // likes, comments, shares
  final int spacesJoined;
  final int eventsAttended;
  final Map<String, int> activityByHour; // hour -> count
  final Map<String, int> activityByDay; // day -> count
  final DateTime lastUpdated;
  
  UserMetricsModel({
    required this.userId,
    this.profileViews = 0,
    this.contentCreated = 0,
    this.contentEngagement = 0,
    this.spacesJoined = 0,
    this.eventsAttended = 0,
    Map<String, int>? activityByHour,
    Map<String, int>? activityByDay,
    DateTime? lastUpdated,
  }) : 
    activityByHour = activityByHour ?? {},
    activityByDay = activityByDay ?? {},
    lastUpdated = lastUpdated ?? DateTime.now();
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'profileViews': profileViews,
      'contentCreated': contentCreated,
      'contentEngagement': contentEngagement,
      'spacesJoined': spacesJoined,
      'eventsAttended': eventsAttended,
      'activityByHour': activityByHour,
      'activityByDay': activityByDay,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
  
  /// Create from Firestore document
  factory UserMetricsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserMetricsModel(
      userId: data['userId'] as String,
      profileViews: data['profileViews'] as int? ?? 0,
      contentCreated: data['contentCreated'] as int? ?? 0,
      contentEngagement: data['contentEngagement'] as int? ?? 0,
      spacesJoined: data['spacesJoined'] as int? ?? 0,
      eventsAttended: data['eventsAttended'] as int? ?? 0,
      activityByHour: data['activityByHour'] != null 
        ? Map<String, int>.from(data['activityByHour'] as Map)
        : {},
      activityByDay: data['activityByDay'] != null 
        ? Map<String, int>.from(data['activityByDay'] as Map)
        : {},
      lastUpdated: data['lastUpdated'] != null 
        ? (data['lastUpdated'] as Timestamp).toDate()
        : DateTime.now(),
    );
  }
  
  /// Create an updated copy of this model
  UserMetricsModel copyWith({
    int? profileViews,
    int? contentCreated,
    int? contentEngagement,
    int? spacesJoined,
    int? eventsAttended,
    Map<String, int>? activityByHour,
    Map<String, int>? activityByDay,
  }) {
    return UserMetricsModel(
      userId: userId,
      profileViews: profileViews ?? this.profileViews,
      contentCreated: contentCreated ?? this.contentCreated,
      contentEngagement: contentEngagement ?? this.contentEngagement,
      spacesJoined: spacesJoined ?? this.spacesJoined,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      activityByHour: activityByHour ?? this.activityByHour,
      activityByDay: activityByDay ?? this.activityByDay,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Increment a specific metric
  UserMetricsModel incrementMetric(String metricName, {int amount = 1}) {
    switch (metricName) {
      case 'profileViews':
        return copyWith(profileViews: profileViews + amount);
      case 'contentCreated':
        return copyWith(contentCreated: contentCreated + amount);
      case 'contentEngagement':
        return copyWith(contentEngagement: contentEngagement + amount);
      case 'spacesJoined':
        return copyWith(spacesJoined: spacesJoined + amount);
      case 'eventsAttended':
        return copyWith(eventsAttended: eventsAttended + amount);
      default:
        return this;
    }
  }
  
  /// Track activity for the current hour
  UserMetricsModel trackHourlyActivity({int amount = 1}) {
    final now = DateTime.now();
    final hourKey = '${now.hour}';
    
    final updatedHourlyActivity = Map<String, int>.from(activityByHour);
    updatedHourlyActivity[hourKey] = (updatedHourlyActivity[hourKey] ?? 0) + amount;
    
    return copyWith(activityByHour: updatedHourlyActivity);
  }
  
  /// Track activity for the current day
  UserMetricsModel trackDailyActivity({int amount = 1}) {
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    
    final updatedDailyActivity = Map<String, int>.from(activityByDay);
    updatedDailyActivity[dayKey] = (updatedDailyActivity[dayKey] ?? 0) + amount;
    
    return copyWith(activityByDay: updatedDailyActivity);
  }
} 