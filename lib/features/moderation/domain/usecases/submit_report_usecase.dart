import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for submitting reports
class SubmitReportUseCase {
  final ModerationRepository _repository;

  /// Constructor
  SubmitReportUseCase(this._repository);

  /// Submit a new content report
  Future<String> call({
    required String reporterUserId,
    required ReportedContentType contentType,
    required String contentId,
    required ReportReason reason,
    String? details,
  }) async {
    return _repository.submitReport(
      reporterUserId: reporterUserId,
      contentType: contentType,
      contentId: contentId,
      reason: reason,
      details: details,
    );
  }
} 