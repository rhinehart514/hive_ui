import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:hive_ui/features/moderation/data/repositories/firestore_moderation_repository.dart';
import 'package:hive_ui/features/moderation/domain/usecases/report_content_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/moderate_content_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/get_reports_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/restrict_user_usecase.dart';
import 'package:hive_ui/features/moderation/presentation/controllers/report_controller.dart';
import 'package:hive_ui/features/moderation/presentation/controllers/moderation_controller.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/reported_content_entity.dart';
import 'package:hive_ui/features/moderation/domain/entities/user_restriction_entity.dart';
import 'package:hive_ui/features/moderation/domain/usecases/check_user_restriction_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/manage_user_restriction_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/submit_report_usecase.dart';
import 'package:hive_ui/features/moderation/presentation/controllers/user_restriction_controller.dart';
import 'package:hive_ui/features/moderation/domain/usecases/apply_moderation_policy_usecase.dart';

/// Provider for the moderation repository
final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return FirestoreModerationRepository();
});

/// Provider for the report content use case
final reportContentUseCaseProvider = Provider<ReportContentUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ReportContentUseCase(repository);
});

/// Provider for the get reports use case
final getReportsUseCaseProvider = Provider<GetReportsUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return GetReportsUseCase(repository);
});

/// Provider for the submit report use case
final submitReportUseCaseProvider = Provider<SubmitReportUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return SubmitReportUseCase(repository);
});

/// Provider for the moderate content use case
final moderateContentUseCaseProvider = Provider<ModerateContentUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ModerateContentUseCase(repository);
});

/// Provider for the restrict user use case
final restrictUserUseCaseProvider = Provider<RestrictUserUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return RestrictUserUseCase(repository);
});

/// Provider for the report controller
final reportControllerProvider = StateNotifierProvider<ReportController, AsyncValue<void>>((ref) {
  final reportContentUseCase = ref.watch(reportContentUseCaseProvider);
  return ReportController(reportContentUseCase: reportContentUseCase);
});

/// Provider for the check user restriction use case
final checkUserRestrictionUseCaseProvider = Provider<CheckUserRestrictionUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return CheckUserRestrictionUseCase(repository);
});

/// Provider for the manage user restriction use case
final manageUserRestrictionUseCaseProvider = Provider<ManageUserRestrictionUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ManageUserRestrictionUseCase(repository);
});

/// Provider for the apply moderation policy use case
final applyModerationPolicyUseCaseProvider = Provider<ApplyModerationPolicyUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ApplyModerationPolicyUseCase(repository);
});

/// Provider for the moderation controller
final moderationControllerProvider = StateNotifierProvider<ModerationController, AsyncValue<List<ContentReportEntity>>>((ref) {
  final getReportsUseCase = ref.watch(getReportsUseCaseProvider);
  final submitReportUseCase = ref.watch(submitReportUseCaseProvider);
  final moderateContentUseCase = ref.watch(moderateContentUseCaseProvider);
  final restrictUserUseCase = ref.watch(restrictUserUseCaseProvider);
  
  return ModerationController(
    getReportsUseCase,
    submitReportUseCase,
    moderateContentUseCase,
    restrictUserUseCase,
  );
});

/// Provider for the user restriction controller
final userRestrictionControllerProvider = StateNotifierProvider<UserRestrictionController, AsyncValue<List<UserRestrictionEntity>>>((ref) {
  final checkUserRestrictionUseCase = ref.watch(checkUserRestrictionUseCaseProvider);
  final manageUserRestrictionUseCase = ref.watch(manageUserRestrictionUseCaseProvider);
  
  return UserRestrictionController(
    checkUserRestrictionUseCase,
    manageUserRestrictionUseCase,
  );
});

/// Provider for the reported content
final reportedContentProvider = FutureProvider.family<ReportedContentEntity?, ContentReportEntity>((ref, report) async {
  final getReportsUseCase = ref.watch(getReportsUseCaseProvider);
  return getReportsUseCase.getReportedContentDetails(report);
});

/// Provider for the is user restricted
final isUserRestrictedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final checkUserRestrictionUseCase = ref.watch(checkUserRestrictionUseCaseProvider);
  return checkUserRestrictionUseCase.isRestricted(userId);
});

/// Provider for the user restriction details
final userRestrictionDetailsProvider = FutureProvider.family<UserRestrictionEntity?, String>((ref, userId) async {
  final checkUserRestrictionUseCase = ref.watch(checkUserRestrictionUseCaseProvider);
  return checkUserRestrictionUseCase.getRestrictionDetails(userId);
});

/// Provider for content moderation policy check
final contentModerationCheckProvider = FutureProvider.family<ModerationResult, ContentModerationParams>((ref, params) async {
  final applyModerationPolicyUseCase = ref.watch(applyModerationPolicyUseCaseProvider);
  return applyModerationPolicyUseCase(
    content: params.content,
    spaceId: params.spaceId,
    eventId: params.eventId,
    userId: params.userId,
  );
});

/// Parameters for content moderation check
class ContentModerationParams {
  final String content;
  final String? spaceId;
  final String? eventId;
  final String? userId;
  
  ContentModerationParams({
    required this.content,
    this.spaceId,
    this.eventId,
    this.userId,
  });
} 