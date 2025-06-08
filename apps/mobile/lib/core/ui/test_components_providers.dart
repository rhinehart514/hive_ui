import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the number of tabs for the test page's TabBar.
final testTabPageLengthProvider = Provider<int>((ref) {
  // Return the fixed number of tabs for the test scenario
  return 3; 
});

// We might add a provider for the TextEditingController later if needed,
// but for now, creating it locally in build is simpler for the test page. 