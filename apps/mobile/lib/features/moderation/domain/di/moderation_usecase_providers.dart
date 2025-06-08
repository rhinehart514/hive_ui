import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/moderation/data/di/moderation_providers.dart';
import 'package:hive_ui/features/moderation/domain/usecases/get_moderation_stats_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/get_reports_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/manage_moderation_settings_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/moderate_content_usecase.dart';
import 'package:hive_ui/features/moderation/domain/usecases/report_content_usecase.dart';

/// Provider for the ReportContentUseCase
final reportContentUseCaseProvider = Provider<ReportContentUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ReportContentUseCase(repository);
});

/// Provider for the GetReportsUseCase
final getReportsUseCaseProvider = Provider<GetReportsUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return GetReportsUseCase(repository);
});

/// Provider for the ModerateContentUseCase
final moderateContentUseCaseProvider = Provider<ModerateContentUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ModerateContentUseCase(repository);
});

/// Provider for the ManageModerationSettingsUseCase
final manageModerationSettingsUseCaseProvider = Provider<ManageModerationSettingsUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return ManageModerationSettingsUseCase(repository);
});

/// Provider for the GetModerationStatsUseCase
final getModerationStatsUseCaseProvider = Provider<GetModerationStatsUseCase>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return GetModerationStatsUseCase(repository);
}); 