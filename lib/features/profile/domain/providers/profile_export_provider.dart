import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/services/profile_export_service.dart';
import 'package:hive_ui/services/profile_sync_service_new.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// Provider for ProfileExportService
final profileExportServiceProvider = Provider<ProfileExportService>((ref) {
  // Get dependencies from other providers
  final profileSyncService = ref.watch(profileSyncServiceProvider);
  final eventBus = AppEventBus();
  
  return ProfileExportService(
    profileSyncService: profileSyncService,
    eventBus: eventBus,
  );
}); 