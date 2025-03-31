import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the SharedPreferences instance
/// Must be overridden with an actual implementation at app startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This will be overridden in main.dart
  throw UnimplementedError('SharedPreferences instance not provided');
});

/// Initializes the SharedPreferences provider with an actual instance
/// Call this function during app startup
Future<void> initializeSharedPreferences(ProviderContainer container) async {
  // This will be called from main.dart with the overridden provider
  // No need to do anything here since we're directly overriding in main.dart
} 