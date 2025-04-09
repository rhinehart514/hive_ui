import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for moderation settings in the data layer
class ModerationSettingsModel {
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
  ModerationSettingsModel({
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
  ModerationSettingsModel copyWith({
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
    return ModerationSettingsModel(
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
  
  /// Create from Firestore document
  factory ModerationSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ModerationSettingsModel(
      id: doc.id,
      autoModerationEnabled: data['autoModerationEnabled'] as bool? ?? true,
      blockedKeywords: List<String>.from(data['blockedKeywords'] ?? []),
      flaggedKeywords: List<String>.from(data['flaggedKeywords'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      reportsThreshold: data['reportsThreshold'] as int? ?? 3,
      notifyModeratorsOnReport: data['notifyModeratorsOnReport'] as bool? ?? true,
      hideReportedContent: data['hideReportedContent'] as bool? ?? false,
      showContentWarnings: data['showContentWarnings'] as bool? ?? true,
      customSettings: data['customSettings'] as Map<String, dynamic>? ?? {},
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      spaceId: data['spaceId'] as String?,
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'autoModerationEnabled': autoModerationEnabled,
      'blockedKeywords': blockedKeywords,
      'flaggedKeywords': flaggedKeywords,
      'moderatorIds': moderatorIds,
      'reportsThreshold': reportsThreshold,
      'notifyModeratorsOnReport': notifyModeratorsOnReport,
      'hideReportedContent': hideReportedContent,
      'showContentWarnings': showContentWarnings,
      'customSettings': customSettings,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'spaceId': spaceId,
    };
  }
  
  /// Get default global settings
  factory ModerationSettingsModel.defaultGlobal() {
    return ModerationSettingsModel(
      id: 'global',
      autoModerationEnabled: true,
      blockedKeywords: [],
      flaggedKeywords: [],
      moderatorIds: [],
      reportsThreshold: 3,
      notifyModeratorsOnReport: true,
      hideReportedContent: false,
      showContentWarnings: true,
      customSettings: {},
      updatedAt: DateTime.now(),
      spaceId: null,
    );
  }
  
  /// Get default space settings
  factory ModerationSettingsModel.defaultForSpace(String spaceId) {
    return ModerationSettingsModel(
      id: 'space_$spaceId',
      autoModerationEnabled: true,
      blockedKeywords: [],
      flaggedKeywords: [],
      moderatorIds: [],
      reportsThreshold: 3,
      notifyModeratorsOnReport: true,
      hideReportedContent: false,
      showContentWarnings: true,
      customSettings: {},
      updatedAt: DateTime.now(),
      spaceId: spaceId,
    );
  }
} 