import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/core/utils/apple_platform_integration.dart';

/// Mac Catalyst helper utilities for handling Mac-specific behaviors 
/// when running iOS apps on macOS through Catalyst.
class MacCatalystHelper {
  /// Singleton instance
  static final MacCatalystHelper _instance = MacCatalystHelper._internal();
  
  /// Factory constructor
  factory MacCatalystHelper() => _instance;
  
  /// Private constructor
  MacCatalystHelper._internal();
  
  /// The Apple platform integration utilities
  final ApplePlatformIntegration _platformIntegration = ApplePlatformIntegration();
  
  /// Checks if the app is running on macOS via Mac Catalyst.
  /// This detection is approximate since Flutter doesn't have direct access
  /// to this information, but we can make educated guesses.
  bool get isMacCatalyst {
    // Direct detection not possible in Flutter, so we use approximation
    // When running on Mac Catalyst, Platform.isIOS reports true, but we're on macOS hardware
    // We can look for larger screen sizes and other macOS characteristics
    
    if (!_platformIntegration.isIOS) return false;
    
    // Check for mac-like screen dimensions (wider screens)
    WidgetsBinding.instance.window;
    final size = PlatformDispatcher.instance.views.first.physicalSize;
    final ratio = size.width / size.height;
    
    // Typical Mac aspect ratios are wider than iOS devices
    if (ratio > 1.7) return true;
    
    // Check for physical size much larger than typical iOS devices
    if (size.width > 1200) return true;
    
    // Currently no completely reliable way to detect, so default to false
    return false;
  }
  
  /// Configure the UI specifically for Mac Catalyst
  void configureMacCatalystUI() {
    if (!isMacCatalyst) return;
    
    // Mac Catalyst specific UI configurations would go here
    debugPrint('Configuring UI for Mac Catalyst');
  }
  
  /// Gets the appropriate scaling factor for UI elements on Mac Catalyst
  double getScalingFactor(BuildContext context) {
    if (!isMacCatalyst) return 1.0;
    
    // Mac Catalyst UI generally needs slightly larger touch targets
    // since users are using mouse/trackpad instead of direct touch
    return 1.1;
  }
  
  /// Gets Mac Catalyst specific padding adjustments
  EdgeInsets getCatalystPadding(BuildContext context) {
    if (!isMacCatalyst) return EdgeInsets.zero;
    
    // Mac windows typically need different padding
    return const EdgeInsets.symmetric(horizontal: 16.0);
  }
  
  /// Adjusts a widget for Mac Catalyst if needed
  Widget adaptForCatalyst({
    required Widget child,
    required BuildContext context,
  }) {
    if (!isMacCatalyst) return child;
    
    // Apply Mac Catalyst specific adaptations to the widget
    return Padding(
      padding: getCatalystPadding(context),
      child: child,
    );
  }
  
  /// Detects if keyboard shortcuts should be enabled (for Mac Catalyst)
  bool get shouldEnableKeyboardShortcuts => isMacCatalyst;
  
  /// Gets a set of keyboard shortcuts appropriate for Mac Catalyst
  Map<ShortcutActivator, VoidCallback> getKeyboardShortcuts({
    VoidCallback? onRefresh,
    VoidCallback? onNew,
    VoidCallback? onSave,
    VoidCallback? onSearch,
  }) {
    if (!isMacCatalyst) return {};
    
    // Mac-style keyboard shortcuts
    final shortcuts = <ShortcutActivator, VoidCallback>{};
    
    if (onRefresh != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyR, meta: true)] = onRefresh;
    }
    
    if (onNew != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyN, meta: true)] = onNew;
    }
    
    if (onSave != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyS, meta: true)] = onSave;
    }
    
    if (onSearch != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.keyF, meta: true)] = onSearch;
    }
    
    return shortcuts;
  }
  
  /// Adjusts scrolling behavior for Mac Catalyst
  ScrollPhysics getScrollPhysics() {
    if (!isMacCatalyst) return const AlwaysScrollableScrollPhysics();
    
    // Mac trackpads work better with bouncing physics
    return const BouncingScrollPhysics();
  }
} 