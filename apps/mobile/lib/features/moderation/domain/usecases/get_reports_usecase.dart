import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/reported_content_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for getting reports
class GetReportsUseCase {
  final ModerationRepository _repository;

  /// Constructor
  GetReportsUseCase(this._repository);

  /// Get all reports
  Future<List<ContentReportEntity>> getAllReports() async {
    return _repository.getAllReports();
  }

  /// Get pending reports
  Future<List<ContentReportEntity>> getPendingReports() async {
    return _repository.getReportsByStatus(ReportStatus.pending);
  }

  /// Get reports in review
  Future<List<ContentReportEntity>> getReportsInReview() async {
    return _repository.getReportsByStatus(ReportStatus.underReview);
  }

  /// Get resolved reports
  Future<List<ContentReportEntity>> getResolvedReports() async {
    return _repository.getReportsByStatus(ReportStatus.resolved);
  }

  /// Get dismissed reports
  Future<List<ContentReportEntity>> getDismissedReports() async {
    return _repository.getReportsByStatus(ReportStatus.dismissed);
  }

  /// Get reports by status
  Future<List<ContentReportEntity>> getReportsByStatus(ReportStatus status) async {
    return _repository.getReportsByStatus(status);
  }

  /// Get reports for a specific piece of content
  Future<List<ContentReportEntity>> getReportsForContent(String contentId, ReportedContentType contentType) async {
    return _repository.getReportsForContent(contentId, contentType);
  }

  /// Get a specific report by ID
  Future<ContentReportEntity?> getReportById(String reportId) async {
    return _repository.getReportById(reportId);
  }

  /// Get detailed information about reported content
  Future<ReportedContentEntity?> getReportedContentDetails(ContentReportEntity report) async {
    return _repository.getReportedContentDetails(report);
  }
} 