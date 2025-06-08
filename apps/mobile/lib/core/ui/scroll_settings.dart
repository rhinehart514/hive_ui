import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defines scroll behavior options for the app.
enum ScrollBounceMode {
  /// Allows overscroll bouncing effect.
  bounce,
  /// Disables overscroll bouncing effect (clamps scroll).
  noBounce
}

/// Provider to control the app-wide scroll bouncing behavior.
/// 
/// Defaults to [ScrollBounceMode.noBounce]. 
/// Widgets can watch this provider to adjust their `ScrollPhysics`.
final scrollModeProvider = StateProvider<ScrollBounceMode>((ref) {
  // Default mode can be changed here if needed.
  return ScrollBounceMode.noBounce;
}); 