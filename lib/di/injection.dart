import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/user/domain/repositories/user_repository.dart';

/// This file contains the dependency injection setup for the app.
/// It defines providers for repositories and services that can be injected
/// throughout the app.

/// Provider for the UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  // In a real implementation, this would be a concrete implementation
  // For now, we'll use a stub that will be implemented elsewhere
  throw UnimplementedError('UserRepository implementation required');
});

/// Initialize all dependencies
void initializeDependencies() {
  // Register any global dependencies or perform initialization here
  // This method would typically be called at app startup
}

/// Used with Provider overrides for testing
class TestDependencies {
  static final testUserRepositoryProvider = Provider<UserRepository>((ref) {
    // Return a mock implementation for testing
    throw UnimplementedError('Mock UserRepository required for testing');
  });
} 