/// Domain entity for moderation settings
class ModerationSettingsEntity {
  /// Unique identifier
  final String id;
  
  /// Whether auto-moderation is enabled for the platform or space
  final bool autoModerationEnabled;
  
  /// List of blocked keywords that trigger auto-moderation
  final List<String> blockedKeywords;
  
  /// List of flagged keywords that require review
  final List<String> flaggedKeywords;
  
  /// List of user IDs who are moderators
  final List<String> moderatorIds;
  
  /// Number of reports required to auto-flag content for review
  final int reportsThreshold;
  
  /// Whether to notify moderators of new reports
  final bool notifyModeratorsOnReport;
  
  /// Whether to hide reported content pending review 
  final bool hideReportedContent;
  
  /// Whether to show warning for flagged content
  final bool showContentWarnings;
  
  /// Additional custom settings
  final Map<String, dynamic> customSettings;
  
  /// Last updated timestamp
  final DateTime updatedAt;
  
  /// ID of the space this applies to (null for global settings)
  final String? spaceId;
  
  /// Constructor
  const ModerationSettingsEntity({
    required this.id,
    this.autoModerationEnabled = true,
    this.blockedKeywords = const [],
    this.flaggedKeywords = const [],
    this.moderatorIds = const [],
    this.reportsThreshold = 3,
    this.notifyModeratorsOnReport = true,
    this.hideReportedContent = false,
    this.showContentWarnings = true,
    this.customSettings = const {},
    required this.updatedAt,
    this.spaceId,
  });
  
  /// Create a copy with modified fields
  ModerationSettingsEntity copyWith({
    String? id,
    bool? autoModerationEnabled,
    List<String>? blockedKeywords,
    List<String>? flaggedKeywords,
    List<String>? moderatorIds,
    int? reportsThreshold,
    bool? notifyModeratorsOnReport,
    bool? hideReportedContent,
    bool? showContentWarnings,
    Map<String, dynamic>? customSettings,
    DateTime? updatedAt,
    String? spaceId,
  }) {
    return ModerationSettingsEntity(
      id: id ?? this.id,
      autoModerationEnabled: autoModerationEnabled ?? this.autoModerationEnabled,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      flaggedKeywords: flaggedKeywords ?? this.flaggedKeywords,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      reportsThreshold: reportsThreshold ?? this.reportsThreshold,
      notifyModeratorsOnReport: notifyModeratorsOnReport ?? this.notifyModeratorsOnReport,
      hideReportedContent: hideReportedContent ?? this.hideReportedContent,
      showContentWarnings: showContentWarnings ?? this.showContentWarnings,
      customSettings: customSettings ?? this.customSettings,
      updatedAt: updatedAt ?? this.updatedAt,
      spaceId: spaceId ?? this.spaceId,
    );
  }
  
  /// Check if a keyword is blocked
  bool isKeywordBlocked(String text) {
    if (!autoModerationEnabled) return false;
    
    final lowerText = text.toLowerCase();
    for (final keyword in blockedKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if content contains flagged keywords
  bool containsFlaggedKeywords(String text) {
    if (!autoModerationEnabled) return false;
    
    final lowerText = text.toLowerCase();
    for (final keyword in flaggedKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if a user is a moderator
  bool isUserModerator(String userId) {
    return moderatorIds.contains(userId);
  }
  
  /// Check if settings are for a specific space
  bool get isSpaceSpecific => spaceId != null;
  
  /// Get moderation strategy name
  String getModerationStrategyName() {
    if (!autoModerationEnabled) {
      return 'Manual Moderation';
    }
    
    if (hideReportedContent) {
      return 'Strict Moderation';
    }
    
    return 'Standard Moderation';
  }
  
  /// Get settings age in days
  int getSettingsAgeInDays() {
    final now = DateTime.now();
    return now.difference(updatedAt).inDays;
  }
} 