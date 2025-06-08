import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/apple_platform_service.dart';
import 'package:hive_ui/core/utils/mac_catalyst_helper.dart';
import 'package:hive_ui/core/services/ios_notification_service.dart';
import 'package:hive_ui/core/utils/apple_hardware_detector.dart';

/// Provider for Apple platform services
final applePlatformServiceProvider = Provider<ApplePlatformService>((ref) {
  return ApplePlatformService();
});

/// Provider for Mac Catalyst helper
final macCatalystHelperProvider = Provider<MacCatalystHelper>((ref) {
  return MacCatalystHelper();
});

/// Provider for iOS notification service
final iosNotificationServiceProvider = Provider<IOSNotificationService>((ref) {
  return IOSNotificationService();
});

/// Provider for Apple hardware detection
final appleHardwareDetectorProvider = Provider<AppleHardwareDetector>((ref) {
  return AppleHardwareDetector();
});

/// Provider for platform initialization
final platformInitializationProvider = FutureProvider<void>((ref) async {
  final appleService = ref.read(applePlatformServiceProvider);
  await appleService.initialize();
  
  // Configure Mac Catalyst if needed
  final macCatalystHelper = ref.read(macCatalystHelperProvider);
  if (macCatalystHelper.isMacCatalyst) {
    macCatalystHelper.configureMacCatalystUI();
  }
  
  // Initialize iOS notifications if needed
  final iosNotificationService = ref.read(iosNotificationServiceProvider);
  await iosNotificationService.initialize();
  
  // Initialize hardware detection
  final hardwareDetector = ref.read(appleHardwareDetectorProvider);
  await hardwareDetector.initialize();
  
  // Add other platform initializations here as needed
  
  return;
}); 