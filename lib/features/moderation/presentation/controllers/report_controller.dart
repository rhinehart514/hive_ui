import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/content_report_entity.dart';
import '../../domain/usecases/report_content_usecase.dart';

/// Controller for managing content reports
class ReportController extends StateNotifier<AsyncValue<void>> {
  final ReportContentUseCase _reportContentUseCase;

  ReportController({
    required ReportContentUseCase reportContentUseCase,
  })  : _reportContentUseCase = reportContentUseCase,
        super(const AsyncValue.data(null));

  /// Reports content with the provided details
  Future<void> reportContent({
    required String contentId,
    required String contentType,
    required ReportReason reason,
    required String description,
    List<String>? evidenceLinks,
    String? reportedUserId,
  }) async {
    // Set state to loading
    state = const AsyncValue.loading();
    
    try {
      // Convert contentType string to enum
      final contentTypeEnum = _convertStringToContentType(contentType);
      
      // Create report
      await _reportContentUseCase.execute(
        userId: reportedUserId ?? 'anonymous', // Use reported user ID or anonymous
        contentType: contentTypeEnum,
        contentId: contentId,
        reason: reason,
        details: description,
      );
      
      // Set success state
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      // Set error state
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
  
  /// Helper method to convert string content type to enum
  ReportedContentType _convertStringToContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'post':
        return ReportedContentType.post;
      case 'comment':
        return ReportedContentType.comment;
      case 'message':
        return ReportedContentType.message;
      case 'space':
        return ReportedContentType.space;
      case 'event':
        return ReportedContentType.event;
      case 'profile':
        return ReportedContentType.profile;
      default:
        return ReportedContentType.post; // Default to post if type is unknown
    }
  }
}

/// Provider for the report controller
final reportControllerProvider = StateNotifierProvider<ReportController, AsyncValue<void>>((ref) {
  final reportContentUseCase = ref.watch(reportContentUseCaseProvider);
  return ReportController(reportContentUseCase: reportContentUseCase);
});

/// Provider for the report content use case
final reportContentUseCaseProvider = Provider<ReportContentUseCase>((ref) {
  // This should be provided by the DI system or another provider
  // For now, we'll need to add the proper provider from the domain/di directory
  throw UnimplementedError('Report Content Use Case provider not implemented yet');
}); 