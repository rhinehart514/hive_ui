// This file has been removed as it contains only legacy code.
// The application now uses real Firebase implementation on all platforms.
// Any references to this file should be updated to use the appropriate Firebase services directly.

/// This file provides centralized export of Firebase utilities
/// It used to contain mock implementations, but now we use real Firebase on all platforms
/// Keeping this file for backward compatibility

// No longer exporting mocks as they're not needed
// export 'utils/firebase_js_interop.dart';
// export 'utils/firebase_web_fix.dart' hide PromiseJsImpl;
// export 'utils/firebase_auth_web_fix.dart';
// export 'config/firebase_windows_support.dart';

import 'package:flutter/foundation.dart';

/// We no longer need mocks as Firebase is fully configured for all platforms
bool get needsFirebaseMocks => false;

/// Initialize Firebase platform support
/// This is now a no-op since all platforms use real Firebase
void initializeFirebaseWindowsSupport() {
  // No-op: All platforms now use real Firebase implementation
  debugPrint('Using real Firebase implementation on all platforms');
}
