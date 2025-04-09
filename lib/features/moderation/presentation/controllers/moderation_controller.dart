import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/moderation_action_entity.dart';
import 'package:hive_ui/features/moderation/domain/usecases/get_reports_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/moderate_content_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/restrict_user_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/submit_report_usecase.dart';

/// State for the moderation controller
class ModerationState {
  final List<ContentReportEntity> reports;
  final bool isLoading;
  final String? error;

  const ModerationState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  /// Create a copy with updated fields
  ModerationState copyWith({
    List<ContentReportEntity>? reports,
    bool? isLoading,
    String? error,
  }) {
    return ModerationState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for moderating content
class ModerationController extends StateNotifier<AsyncValue<List<ContentReportEntity>>> {
  final GetReportsUseCase _getReportsUseCase;
  final SubmitReportUseCase _submitReportUseCase;
  final ModerateContentUseCase _moderateContentUseCase;
  final RestrictUserUseCase _restrictUserUseCase;

  /// Constructor
  ModerationController(
    this._getReportsUseCase,
    this._submitReportUseCase,
    this._moderateContentUseCase,
    this._restrictUserUseCase,
  ) : super(const AsyncValue.loading()) {
    loadPendingReports();
  }

  /// Load pending reports
  Future<void> loadPendingReports() async {
    try {
      state = const AsyncValue.loading();
      final reports = await _getReportsUseCase.getPendingReports();
      state = AsyncValue.data(reports);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
  
  /// Load all reports
  Future<void> loadAllReports() async {
    try {
      state = const AsyncValue.loading();
      final reports = await _getReportsUseCase.getAllReports();
      state = AsyncValue.data(reports);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
  
  /// Load reports by status
  Future<void> loadReportsByStatus(ReportStatus status) async {
    try {
      state = const AsyncValue.loading();
      final reports = await _getReportsUseCase.getReportsByStatus(status);
      state = AsyncValue.data(reports);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
  
  /// Submit a new report
  Future<String> submitReport({
    required String reporterUserId,
    required ReportedContentType contentType,
    required String contentId,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      return await _submitReportUseCase(
        reporterUserId: reporterUserId,
        contentType: contentType,
        contentId: contentId,
        reason: reason,
        details: details,
      );
    } catch (error) {
      rethrow;
    }
  }
  
  /// Take moderation action on a report
  Future<void> moderateContent({
    required String reportId,
    required ModerationActionType actionType,
    String? note,
  }) async {
    try {
      // Fetch the report first to get the content ID
      final report = await _getReportsUseCase.getReportById(reportId);
      if (report == null) {
        throw Exception('Report not found');
      }
      
      // Take action on the content
      await _moderateContentUseCase.takeActionOnContent(
        moderatorId: 'current-user-id', // TODO: Get from auth service
        contentId: report.contentId,
        actionType: actionType,
        severity: ModerationSeverity.medium, // Default to medium severity
        relatedReportIds: [reportId],
        notes: note ?? 'No notes provided',
      );
      
      // Refresh reports after moderation
      final currentState = state;
      if (currentState is AsyncData<List<ContentReportEntity>>) {
        // Update the report status in the local state
        final updatedReports = currentState.value.map((r) {
          if (r.id == reportId) {
            // Create a copy with updated status
            return r.copyWith(
              status: _getStatusForAction(actionType),
              moderatorNotes: note,
              actionTaken: actionType.toString(),
            );
          }
          return r;
        }).toList();
        
        state = AsyncValue.data(updatedReports);
      }
    } catch (error) {
      // We don't update state here, just throw the error for the UI to handle
      rethrow;
    }
  }
  
  /// Restrict or un-restrict a user
  Future<void> restrictUser({
    required String userId,
    required bool isRestricted,
    String? reason,
    DateTime? endDate,
    required String restrictedBy,
  }) async {
    try {
      await _restrictUserUseCase(
        userId,
        isRestricted: isRestricted,
        reason: reason,
        endDate: endDate,
        restrictedBy: restrictedBy,
      );
    } catch (error) {
      rethrow;
    }
  }
  
  /// Helper method to convert action type to report status
  ReportStatus _getStatusForAction(ModerationActionType actionType) {
    switch (actionType) {
      case ModerationActionType.escalateToAdmin:
        return ReportStatus.underReview;
      case ModerationActionType.markSafe:
        return ReportStatus.dismissed;
      default:
        return ReportStatus.resolved;
    }
  }
} 