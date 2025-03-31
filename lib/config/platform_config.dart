import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Platform configuration helpers to provide consistent behavior
/// across different platforms (web, mobile, desktop).

/// Determines if the current platform should use web implementation
/// of Firebase plugins
bool shouldUseWebImplementation() {
  // Web already uses web implementation
  if (kIsWeb) return true;

  // Windows and Linux now use real Firebase implementation
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    return false; // Use real implementation, not web
  }

  // All other platforms use native implementation
  return false;
}

/// Class for platform-specific settings
class PlatformConfig {
  /// Check if we're running on a desktop platform
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Check if we're running on a mobile platform
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Check if we're running on Windows
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Checks if we should use mock implementations
  /// Using real Firebase on all platforms
  static bool get shouldUseMockImplementation => false;

  /// Detects if we're running in a terminal testing environment
  static bool get isTerminalTesting {
    try {
      // Check common terminal environment variables
      if (!kIsWeb) {
        return Platform.environment.containsKey('TERM') ||
            Platform.environment.containsKey('SHELL') ||
            isCI;
      }
    } catch (e) {
      // Fallback if platform access fails
    }
    return false;
  }

  /// Detects if running in CI environment
  static bool get isCI {
    try {
      if (!kIsWeb) {
        final envVars = [
          'CI',
          'CONTINUOUS_INTEGRATION',
          'GITHUB_ACTIONS',
          'CIRCLECI',
          'TRAVIS',
          'GITLAB_CI'
        ];

        for (final envVar in envVars) {
          if (Platform.environment.containsKey(envVar)) {
            return true;
          }
        }
      }
    } catch (e) {
      // Fallback if platform access fails
    }
    return false;
  }

  /// Get detailed platform information for debugging
  static Map<String, dynamic> get platformInfo {
    final info = <String, dynamic>{
      'platform': platformName,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'isWeb': kIsWeb,
      'isTerminalTesting': isTerminalTesting,
      'isCI': isCI,
    };

    try {
      if (!kIsWeb) {
        info['operatingSystem'] = Platform.operatingSystem;
        info['operatingSystemVersion'] = Platform.operatingSystemVersion;
      }
    } catch (e) {
      info['platformAccessError'] = e.toString();
    }

    return info;
  }

  /// Get a string identifier for the current platform
  static String get platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }
}
