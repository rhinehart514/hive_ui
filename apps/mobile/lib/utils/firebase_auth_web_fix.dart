import 'package:flutter/foundation.dart';

/// This file previously contained platform-specific implementations for Firebase Auth
/// It's now simplified as we use real Firebase on all platforms
///
/// Keeping minimal stubs for backward compatibility

/// Apply platform-specific adaptations for Firebase Auth
void applyFirebaseAuthFixes() {
  // No-op: Now using real Firebase implementation on all platforms
  if (kDebugMode) {
    debugPrint('Using real Firebase implementation on all platforms');
  }
}

/// Mock class for backward compatibility
class FirebaseAuthMock {
  // This is always false now
  static bool get isActive => false;
}
