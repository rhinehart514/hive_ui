/// Entity representing aggregated user metrics for the domain layer
class UserMetricsEntity {
  final String userId;
  final int profileViews;
  final int contentCreated;
  final int contentEngagement;
  final int spacesJoined;
  final int eventsAttended;
  final Map<String, int> activityByHour;
  final Map<String, int> activityByDay;
  final DateTime lastUpdated;
  
  const UserMetricsEntity({
    required this.userId,
    required this.profileViews,
    required this.contentCreated,
    required this.contentEngagement,
    required this.spacesJoined,
    required this.eventsAttended,
    required this.activityByHour,
    required this.activityByDay,
    required this.lastUpdated,
  });
  
  /// Create a copy with updated values
  UserMetricsEntity copyWith({
    int? profileViews,
    int? contentCreated,
    int? contentEngagement,
    int? spacesJoined,
    int? eventsAttended,
    Map<String, int>? activityByHour,
    Map<String, int>? activityByDay,
    DateTime? lastUpdated,
  }) {
    return UserMetricsEntity(
      userId: userId,
      profileViews: profileViews ?? this.profileViews,
      contentCreated: contentCreated ?? this.contentCreated,
      contentEngagement: contentEngagement ?? this.contentEngagement,
      spacesJoined: spacesJoined ?? this.spacesJoined,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      activityByHour: activityByHour ?? this.activityByHour,
      activityByDay: activityByDay ?? this.activityByDay,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Calculate an engagement score based on metrics
  int calculateEngagementScore() {
    // Simple algorithm: weighted sum of all metrics
    return (profileViews * 1) +
           (contentCreated * 10) +
           (contentEngagement * 5) +
           (spacesJoined * 15) +
           (eventsAttended * 20);
  }
  
  /// Get peak activity hour (0-23)
  int? getPeakActivityHour() {
    if (activityByHour.isEmpty) return null;
    
    int maxHour = 0;
    int maxCount = 0;
    
    activityByHour.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        maxHour = int.parse(hour);
      }
    });
    
    return maxHour;
  }
  
  /// Get most active day in format YYYY-MM-DD
  String? getMostActiveDay() {
    if (activityByDay.isEmpty) return null;
    
    String mostActiveDay = '';
    int maxCount = 0;
    
    activityByDay.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        mostActiveDay = day;
      }
    });
    
    return mostActiveDay;
  }
  
  /// Get total activity count across all days
  int getTotalActivityCount() {
    int total = 0;
    activityByDay.forEach((_, count) => total += count);
    return total;
  }
  
  /// Check if user is considered active (had activity in the last 7 days)
  bool isActiveUser() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    for (final day in activityByDay.keys) {
      try {
        final parts = day.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          
          if (date.isAfter(sevenDaysAgo)) {
            return true;
          }
        }
      } catch (e) {
        // Skip invalid date format
        continue;
      }
    }
    
    return false;
  }
} 