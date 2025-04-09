import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/moderation/data/mappers/moderation_mappers.dart';
import 'package:hive_ui/features/moderation/data/mappers/user_restriction_mapper.dart';
import 'package:hive_ui/features/moderation/data/models/content_report_model.dart';
import 'package:hive_ui/features/moderation/data/models/moderation_action_model.dart';
import 'package:hive_ui/features/moderation/data/models/moderation_settings_model.dart';
import 'package:hive_ui/features/moderation/data/models/user_restriction_model.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/moderation_action_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/moderation_settings_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/reported_content_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart' as entities;
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:uuid/uuid.dart';

/// Firestore implementation of the moderation repository
class FirestoreModerationRepository implements ModerationRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  
  // Collection paths
  static const String _reportsCollection = 'content_reports';
  static const String _actionsCollection = 'moderation_actions';
  static const String _settingsCollection = 'moderation_settings';
  static const String _postsCollection = 'posts';
  static const String _commentsCollection = 'comments';
  static const String _messagesCollection = 'messages';
  static const String _spacesCollection = 'spaces';
  static const String _eventsCollection = 'events';
  static const String _usersCollection = 'users';
  static const String _restrictionsCollection = 'user_restrictions';
  
  /// Constructor
  FirestoreModerationRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<List<entities.ContentReportEntity>> getAllReports() async {
    final snapshot = await _firestore.collection(_reportsCollection)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ContentReportModel.fromFirestore(doc))
        .map((model) => ContentReportMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<List<entities.ContentReportEntity>> getReportsByStatus(entities.ReportStatus status) async {
    final statusStr = status.toString().split('.').last;
    
    final snapshot = await _firestore.collection(_reportsCollection)
        .where('status', isEqualTo: statusStr)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ContentReportModel.fromFirestore(doc))
        .map((model) => ContentReportMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<List<entities.ContentReportEntity>> getReportsForContent(
      String contentId, entities.ReportedContentType contentType) async {
    final contentTypeStr = contentType.toString().split('.').last;
    
    final snapshot = await _firestore.collection(_reportsCollection)
        .where('contentId', isEqualTo: contentId)
        .where('contentType', isEqualTo: contentTypeStr)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ContentReportModel.fromFirestore(doc))
        .map((model) => ContentReportMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<entities.ContentReportEntity?> getReportById(String reportId) async {
    final doc = await _firestore.collection(_reportsCollection).doc(reportId).get();
    
    if (!doc.exists) return null;
    
    final model = ContentReportModel.fromFirestore(doc);
    return ContentReportMapper.fromModel(model);
  }
  
  @override
  Future<String> submitReport({
    required String reporterUserId,
    required entities.ReportedContentType contentType,
    required String contentId,
    required entities.ReportReason reason,
    String? details,
  }) async {
    final now = DateTime.now();
    final reportId = _uuid.v4();
    
    // Convert enums to strings for Firestore
    final contentTypeStr = contentType.toString().split('.').last;
    final reasonStr = reason.toString().split('.').last;
    
    await _firestore.collection(_reportsCollection).doc(reportId).set({
      'reporterUserId': reporterUserId,
      'contentType': contentTypeStr,
      'contentId': contentId,
      'reason': reasonStr,
      'details': details,
      'status': 'pending', // Initial status is always pending
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'resolvedByUserId': null,
      'moderatorNotes': null,
      'actionTaken': null,
    });
    
    return reportId;
  }
  
  @override
  Future<void> updateReportStatus({
    required String reportId,
    required entities.ReportStatus newStatus,
    String? moderatorId,
    String? moderatorNotes,
    String? actionTaken,
  }) async {
    final statusStr = newStatus.toString().split('.').last;
    final now = Timestamp.fromDate(DateTime.now());
    
    await _firestore.collection(_reportsCollection).doc(reportId).update({
      'status': statusStr,
      'updatedAt': now,
      if (moderatorId != null) 'resolvedByUserId': moderatorId,
      if (moderatorNotes != null) 'moderatorNotes': moderatorNotes,
      if (actionTaken != null) 'actionTaken': actionTaken,
    });
  }
  
  @override
  Future<entities.ReportedContentEntity?> getReportedContentDetails(entities.ContentReportEntity report) async {
    try {
      // Determine the collection based on content type
      final String collection = _getCollectionForContentType(report.contentType);
      
      // Fetch content data
      final contentDoc = await _firestore.collection(collection).doc(report.contentId).get();
      if (!contentDoc.exists) return null;
      
      final contentData = contentDoc.data() as Map<String, dynamic>;
      
      // Extract content details based on type
      String? contentTitle;
      String? contentText;
      String? creatorId;
      DateTime? contentCreatedAt;
      
      switch (report.contentType) {
        case entities.ReportedContentType.post:
          contentTitle = contentData['title'] as String?;
          contentText = contentData['text'] as String?;
          creatorId = contentData['userId'] as String?;
          contentCreatedAt = (contentData['createdAt'] as Timestamp?)?.toDate();
          break;
        case entities.ReportedContentType.comment:
          contentText = contentData['text'] as String?;
          creatorId = contentData['userId'] as String?;
          contentCreatedAt = (contentData['createdAt'] as Timestamp?)?.toDate();
          break;
        case entities.ReportedContentType.message:
          contentText = contentData['text'] as String?;
          creatorId = contentData['senderId'] as String?;
          contentCreatedAt = (contentData['timestamp'] as Timestamp?)?.toDate();
          break;
        case entities.ReportedContentType.space:
          contentTitle = contentData['name'] as String?;
          contentText = contentData['description'] as String?;
          creatorId = contentData['creatorId'] as String?;
          contentCreatedAt = (contentData['createdAt'] as Timestamp?)?.toDate();
          break;
        case entities.ReportedContentType.event:
          contentTitle = contentData['title'] as String?;
          contentText = contentData['description'] as String?;
          creatorId = contentData['organizerId'] as String?;
          contentCreatedAt = (contentData['createdAt'] as Timestamp?)?.toDate();
          break;
        case entities.ReportedContentType.profile:
          creatorId = report.contentId; // For profiles, contentId is the userId
          contentTitle = contentData['displayName'] as String?;
          contentText = contentData['bio'] as String?;
          contentCreatedAt = (contentData['createdAt'] as Timestamp?)?.toDate();
          break;
      }
      
      // Fetch creator data if we have a creatorId
      String? creatorName;
      String? creatorImageUrl;
      
      if (creatorId != null) {
        final userDoc = await _firestore.collection(_usersCollection).doc(creatorId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          creatorName = userData['displayName'] as String?;
          creatorImageUrl = userData['profileImageUrl'] as String?;
        }
      }
      
      // Create and return the entity
      return ReportedContentFactory.createFromReport(
        report: report,
        contentTitle: contentTitle,
        contentText: contentText,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorImageUrl: creatorImageUrl,
        contentCreatedAt: contentCreatedAt,
        contentMetadata: contentData,
      );
    } catch (e) {
      print('Error fetching reported content details: $e');
      return null;
    }
  }
  
  @override
  Future<List<entities.ModerationActionEntity>> getAllModerationActions() async {
    final snapshot = await _firestore.collection(_actionsCollection)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ModerationActionModel.fromFirestore(doc))
        .map((model) => ModerationActionMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<List<entities.ModerationActionEntity>> getActionsForTarget(
      String targetId, {bool isUserTarget = false}) async {
    final snapshot = await _firestore.collection(_actionsCollection)
        .where('targetId', isEqualTo: targetId)
        .where('isUserTarget', isEqualTo: isUserTarget)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ModerationActionModel.fromFirestore(doc))
        .map((model) => ModerationActionMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<entities.ModerationActionEntity?> getActionById(String actionId) async {
    final doc = await _firestore.collection(_actionsCollection).doc(actionId).get();
    
    if (!doc.exists) return null;
    
    final model = ModerationActionModel.fromFirestore(doc);
    return ModerationActionMapper.fromModel(model);
  }
  
  @override
  Future<String> createModerationAction({
    required entities.ModerationActionType actionType,
    required String moderatorId,
    required String targetId,
    required bool isUserTarget,
    required entities.ModerationSeverity severity,
    List<String> relatedReportIds = const [],
    required String notes,
    DateTime? expiresAt,
  }) async {
    final actionId = _uuid.v4();
    final now = DateTime.now();
    
    // Convert enums to strings
    final actionTypeStr = actionType.toString().split('.').last;
    final severityStr = severity.toString().split('.').last;
    
    await _firestore.collection(_actionsCollection).doc(actionId).set({
      'actionType': actionTypeStr,
      'moderatorId': moderatorId,
      'targetId': targetId,
      'isUserTarget': isUserTarget,
      'severity': severityStr,
      'relatedReportIds': relatedReportIds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'isActive': true,
    });
    
    // If this action is related to reports, update those reports
    if (relatedReportIds.isNotEmpty) {
      final batch = _firestore.batch();
      
      for (final reportId in relatedReportIds) {
        final reportRef = _firestore.collection(_reportsCollection).doc(reportId);
        batch.update(reportRef, {
          'status': 'resolved',
          'resolvedByUserId': moderatorId,
          'actionTaken': actionTypeStr,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
      
      await batch.commit();
    }
    
    return actionId;
  }
  
  @override
  Future<void> updateModerationAction({
    required String actionId,
    entities.ModerationActionType? actionType,
    entities.ModerationSeverity? severity,
    String? notes,
    DateTime? expiresAt,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    
    if (actionType != null) {
      updates['actionType'] = actionType.toString().split('.').last;
    }
    
    if (severity != null) {
      updates['severity'] = severity.toString().split('.').last;
    }
    
    if (notes != null) {
      updates['notes'] = notes;
    }
    
    if (expiresAt != null) {
      updates['expiresAt'] = Timestamp.fromDate(expiresAt);
    }
    
    if (isActive != null) {
      updates['isActive'] = isActive;
    }
    
    if (updates.isNotEmpty) {
      await _firestore.collection(_actionsCollection).doc(actionId).update(updates);
    }
  }
  
  @override
  Future<entities.ModerationSettingsEntity> getGlobalModerationSettings() async {
    try {
      final doc = await _firestore.collection(_settingsCollection).doc('global').get();
      
      if (doc.exists) {
        final model = ModerationSettingsModel.fromFirestore(doc);
        return ModerationSettingsMapper.fromModel(model);
      } else {
        // Create default settings if they don't exist
        final defaultSettings = ModerationSettingsModel.defaultGlobal();
        await _firestore.collection(_settingsCollection).doc('global').set(defaultSettings.toFirestore());
        return ModerationSettingsMapper.fromModel(defaultSettings);
      }
    } catch (e) {
      print('Error getting global moderation settings: $e');
      // Return default settings if there's an error
      return ModerationSettingsMapper.fromModel(ModerationSettingsModel.defaultGlobal());
    }
  }
  
  @override
  Future<entities.ModerationSettingsEntity> getSpaceModerationSettings(String spaceId) async {
    try {
      final settingsId = 'space_$spaceId';
      final doc = await _firestore.collection(_settingsCollection).doc(settingsId).get();
      
      if (doc.exists) {
        final model = ModerationSettingsModel.fromFirestore(doc);
        return ModerationSettingsMapper.fromModel(model);
      } else {
        // Create default space settings if they don't exist
        final defaultSettings = ModerationSettingsModel.defaultForSpace(spaceId);
        await _firestore.collection(_settingsCollection).doc(settingsId).set(defaultSettings.toFirestore());
        return ModerationSettingsMapper.fromModel(defaultSettings);
      }
    } catch (e) {
      print('Error getting space moderation settings: $e');
      // Return default settings if there's an error
      return ModerationSettingsMapper.fromModel(ModerationSettingsModel.defaultForSpace(spaceId));
    }
  }
  
  @override
  Future<void> updateModerationSettings({
    required String settingsId,
    bool? autoModerationEnabled,
    List<String>? blockedKeywords,
    List<String>? flaggedKeywords,
    List<String>? moderatorIds,
    int? reportsThreshold,
    bool? notifyModeratorsOnReport,
    bool? hideReportedContent,
    bool? showContentWarnings,
    Map<String, dynamic>? customSettings,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    
    if (autoModerationEnabled != null) {
      updates['autoModerationEnabled'] = autoModerationEnabled;
    }
    
    if (blockedKeywords != null) {
      updates['blockedKeywords'] = blockedKeywords;
    }
    
    if (flaggedKeywords != null) {
      updates['flaggedKeywords'] = flaggedKeywords;
    }
    
    if (moderatorIds != null) {
      updates['moderatorIds'] = moderatorIds;
    }
    
    if (reportsThreshold != null) {
      updates['reportsThreshold'] = reportsThreshold;
    }
    
    if (notifyModeratorsOnReport != null) {
      updates['notifyModeratorsOnReport'] = notifyModeratorsOnReport;
    }
    
    if (hideReportedContent != null) {
      updates['hideReportedContent'] = hideReportedContent;
    }
    
    if (showContentWarnings != null) {
      updates['showContentWarnings'] = showContentWarnings;
    }
    
    if (customSettings != null) {
      updates['customSettings'] = customSettings;
    }
    
    await _firestore.collection(_settingsCollection).doc(settingsId).update(updates);
  }
  
  @override
  Future<bool> scanContent({
    required String content,
    required String spaceId,
  }) async {
    try {
      // Get settings for the space
      final settings = await getSpaceModerationSettings(spaceId);
      
      // Check if auto moderation is enabled
      if (!settings.autoModerationEnabled) return false;
      
      // Check against blocked keywords
      final contentLower = content.toLowerCase();
      for (final keyword in settings.blockedKeywords) {
        if (contentLower.contains(keyword.toLowerCase())) {
          return true; // Content contains blocked keyword
        }
      }
      
      // In a real implementation, we might integrate with a third-party
      // content moderation API here for more sophisticated scanning
      
      return false; // Content passed all checks
    } catch (e) {
      print('Error scanning content: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getModerationStats({
    DateTime? startDate,
    DateTime? endDate,
    String? spaceId,
  }) async {
    // Default to last 30 days if no dates provided
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));
    
    final startTimestamp = Timestamp.fromDate(start);
    final endTimestamp = Timestamp.fromDate(end);
    
    try {
      // Query for reports in the date range
      Query reportsQuery = _firestore.collection(_reportsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp);
      
      // Filter by space if provided
      if (spaceId != null) {
        // This assumes reports have spaceId field or we can determine space from contentId
        // In a real implementation, you might need more complex logic here
        reportsQuery = reportsQuery.where('spaceId', isEqualTo: spaceId);
      }
      
      final reportsSnapshot = await reportsQuery.get();
      final reports = reportsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      // Query for actions in the date range
      Query actionsQuery = _firestore.collection(_actionsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp);
      
      if (spaceId != null) {
        // Similar limitation/assumption as above
        actionsQuery = actionsQuery.where('spaceId', isEqualTo: spaceId);
      }
      
      final actionsSnapshot = await actionsQuery.get();
      final actions = actionsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      // Calculate statistics
      final stats = <String, dynamic>{
        'totalReports': reports.length,
        'totalActions': actions.length,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
      
      // Count reports by status
      final reportsByStatus = <String, int>{};
      for (final report in reports) {
        final status = report['status'] as String;
        reportsByStatus[status] = (reportsByStatus[status] ?? 0) + 1;
      }
      stats['reportsByStatus'] = reportsByStatus;
      
      // Count reports by type
      final reportsByType = <String, int>{};
      for (final report in reports) {
        final type = report['contentType'] as String;
        reportsByType[type] = (reportsByType[type] ?? 0) + 1;
      }
      stats['reportsByType'] = reportsByType;
      
      // Count actions by type
      final actionsByType = <String, int>{};
      for (final action in actions) {
        final type = action['actionType'] as String;
        actionsByType[type] = (actionsByType[type] ?? 0) + 1;
      }
      stats['actionsByType'] = actionsByType;
      
      return stats;
    } catch (e) {
      print('Error getting moderation stats: $e');
      return {
        'error': 'Failed to retrieve statistics',
        'totalReports': 0,
        'totalActions': 0,
      };
    }
  }
  
  @override
  Future<List<entities.UserRestrictionEntity>> getAllUserRestrictions() async {
    final snapshot = await _firestore.collection(_restrictionsCollection)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => UserRestrictionModel.fromFirestore(doc))
        .map((model) => UserRestrictionMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<List<entities.UserRestrictionEntity>> getActiveUserRestrictions() async {
    final snapshot = await _firestore.collection(_restrictionsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => UserRestrictionModel.fromFirestore(doc))
        .map((model) => UserRestrictionMapper.fromModel(model))
        .toList();
  }
  
  @override
  Future<entities.UserRestrictionEntity?> getUserRestrictionById(String restrictionId) async {
    final doc = await _firestore.collection(_restrictionsCollection).doc(restrictionId).get();
    
    if (!doc.exists) return null;
    
    final model = UserRestrictionModel.fromFirestore(doc);
    return UserRestrictionMapper.fromModel(model);
  }
  
  @override
  Future<entities.UserRestrictionEntity?> getUserRestrictionByUserId(String userId) async {
    final snapshot = await _firestore.collection(_restrictionsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final model = UserRestrictionModel.fromFirestore(snapshot.docs.first);
    return UserRestrictionMapper.fromModel(model);
  }
  
  @override
  Future<String> createUserRestriction({
    required String userId,
    required String reason,
    required String restrictedBy,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final restrictionId = _uuid.v4();
    final now = DateTime.now();
    
    // Check if there's an existing active restriction for this user
    final existingRestrictions = await _firestore.collection(_restrictionsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();
    
    // If there's an existing restriction, deactivate it and store in history
    List<Map<String, dynamic>> restrictionHistory = [];
    if (existingRestrictions.docs.isNotEmpty) {
      final batch = _firestore.batch();
      
      for (final doc in existingRestrictions.docs) {
        final existingData = doc.data();
        
        // Create a history record of the previous restriction
        final historyEntry = {
          'createdAt': existingData['createdAt'],
          'endedAt': Timestamp.fromDate(now),
          'reason': existingData['reason'],
          'restrictedBy': existingData['restrictedBy'],
          'removedBy': restrictedBy,
          'removalReason': 'Replaced by new restriction',
        };
        
        restrictionHistory.add(historyEntry);
        
        // Deactivate the existing restriction
        batch.update(doc.reference, {'isActive': false});
      }
      
      await batch.commit();
    }
    
    // Create the new restriction
    await _firestore.collection(_restrictionsCollection).doc(restrictionId).set({
      'userId': userId,
      'isActive': true,
      'reason': reason,
      'restrictedBy': restrictedBy,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'notes': notes,
      'restrictionHistory': restrictionHistory,
    });
    
    // Also update the user record to show they are restricted
    await _firestore.collection(_usersCollection).doc(userId).update({
      'isRestricted': true,
      'restrictionReason': reason,
      'restrictionEndDate': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'restrictedBy': restrictedBy,
    });
    
    return restrictionId;
  }
  
  @override
  Future<void> updateUserRestriction({
    required String restrictionId,
    bool? isActive,
    String? reason,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    
    if (isActive != null) {
      updates['isActive'] = isActive;
    }
    
    if (reason != null) {
      updates['reason'] = reason;
    }
    
    if (expiresAt != null) {
      updates['expiresAt'] = Timestamp.fromDate(expiresAt);
    }
    
    if (notes != null) {
      updates['notes'] = notes;
    }
    
    if (updates.isNotEmpty) {
      // Update the restriction record
      await _firestore.collection(_restrictionsCollection).doc(restrictionId).update(updates);
      
      // Get the updated restriction to sync with user record
      final updatedDoc = await _firestore.collection(_restrictionsCollection).doc(restrictionId).get();
      if (updatedDoc.exists) {
        final data = updatedDoc.data() as Map<String, dynamic>;
        
        // Update the user record
        await _firestore.collection(_usersCollection).doc(data['userId']).update({
          'isRestricted': data['isActive'],
          'restrictionReason': data['reason'],
          'restrictionEndDate': data['expiresAt'],
          'restrictedBy': data['restrictedBy'],
        });
      }
    }
  }
  
  @override
  Future<void> removeUserRestriction({
    required String restrictionId,
    required String removedBy,
    String? removalReason,
  }) async {
    // Get the current restriction
    final doc = await _firestore.collection(_restrictionsCollection).doc(restrictionId).get();
    if (!doc.exists) return;
    
    final restrictionData = doc.data() as Map<String, dynamic>;
    final userId = restrictionData['userId'] as String;
    final now = DateTime.now();
    
    // Get existing history or create empty array if none
    List<dynamic> existingHistory = restrictionData['restrictionHistory'] ?? [];
    
    // Create a history entry for this restriction
    final historyEntry = {
      'createdAt': restrictionData['createdAt'],
      'endedAt': Timestamp.fromDate(now),
      'reason': restrictionData['reason'],
      'restrictedBy': restrictionData['restrictedBy'],
      'removedBy': removedBy,
      'removalReason': removalReason ?? 'Restriction removed',
    };
    
    // Add the current restriction to history
    existingHistory.add(historyEntry);
    
    // Update the restriction record
    await _firestore.collection(_restrictionsCollection).doc(restrictionId).update({
      'isActive': false,
      'restrictionHistory': existingHistory,
    });
    
    // Update the user record
    await _firestore.collection(_usersCollection).doc(userId).update({
      'isRestricted': false,
      'restrictionReason': FieldValue.delete(),
      'restrictionEndDate': FieldValue.delete(),
      'restrictedBy': FieldValue.delete(),
    });
  }
  
  @override
  Future<bool> isUserRestricted(String userId) async {
    try {
      // First check if there's an active restriction
      final restrictionSnapshot = await _firestore.collection(_restrictionsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (restrictionSnapshot.docs.isEmpty) return false;
      
      // Check if the restriction has expired
      for (final doc in restrictionSnapshot.docs) {
        final data = doc.data();
        final expiresAt = data['expiresAt'];
        
        // If no expiration, it's permanent
        if (expiresAt == null) return true;
        
        // If not expired, user is restricted
        final expirationDate = (expiresAt as Timestamp).toDate();
        if (DateTime.now().isBefore(expirationDate)) {
          return true;
        } else {
          // Automatically deactivate expired restrictions
          await _firestore.collection(_restrictionsCollection).doc(doc.id).update({
            'isActive': false,
          });
          
          // Also update the user record
          await _firestore.collection(_usersCollection).doc(userId).update({
            'isRestricted': false,
            'restrictionReason': FieldValue.delete(),
            'restrictionEndDate': FieldValue.delete(),
            'restrictedBy': FieldValue.delete(),
          });
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if user is restricted: $e');
      return false;
    }
  }
  
  // Helper method to get the appropriate collection for a content type
  String _getCollectionForContentType(entities.ReportedContentType contentType) {
    switch (contentType) {
      case entities.ReportedContentType.post:
        return _postsCollection;
      case entities.ReportedContentType.comment:
        return _commentsCollection;
      case entities.ReportedContentType.message:
        return _messagesCollection;
      case entities.ReportedContentType.space:
        return _spacesCollection;
      case entities.ReportedContentType.event:
        return _eventsCollection;
      case entities.ReportedContentType.profile:
        return _usersCollection;
    }
  }
} 