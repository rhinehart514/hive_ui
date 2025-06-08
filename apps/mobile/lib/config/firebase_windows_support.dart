import 'package:flutter/foundation.dart';

/// This file is maintained for backward compatibility
/// Windows now uses real Firebase implementation like all other platforms
class FirebaseWindowsSupport {
  /// This method is kept for backward compatibility
  /// It now does nothing as we use real Firebase on all platforms
  static void applyFixes() {
    // No-op: All platforms use real Firebase now
    if (kDebugMode) {
      debugPrint(
          'Using real Firebase implementation on all platforms including Windows');
    }
  }

  /// Checks if Firebase should use limited functionality on this platform
  /// Always returns false now that all platforms use real Firebase
  static bool get useLimitedFunctionality => false;
}
