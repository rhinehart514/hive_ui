import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to access the system's reduced motion setting.
/// 
/// Reads the setting initially and allows overriding for testing/debugging.
/// TODO: Implement actual system setting detection.
final reducedMotionProvider = StateProvider<bool>((ref) {
  // Placeholder: Replace with actual system setting detection
  // final mediaQuery = MediaQuery.maybeOf(NavigationService.navigatorKey.currentContext!); // Needs context
  // return mediaQuery?.disableAnimations ?? false;
  return false; // Default to false for now
}); 