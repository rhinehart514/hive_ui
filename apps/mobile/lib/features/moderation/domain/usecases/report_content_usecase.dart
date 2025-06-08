import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';

/// Use case for reporting content
class ReportContentUseCase {
  final ModerationRepository _repository;

  /// Constructor
  ReportContentUseCase(this._repository);

  /// Submit a content report
  Future<String> execute({
    required String userId,
    required ReportedContentType contentType,
    required String contentId,
    required ReportReason reason,
    String? details,
  }) async {
    return _repository.submitReport(
      reporterUserId: userId,
      contentType: contentType,
      contentId: contentId,
      reason: reason,
      details: details,
    );
  }
} 