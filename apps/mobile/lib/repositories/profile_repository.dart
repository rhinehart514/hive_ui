import 'package:hive_ui/models/user_profile.dart';

/// Mock repository for accessing user profile data
class ProfileRepository {
  /// Get a mock user profile by ID
  Future<UserProfile> getUserProfile(String userId) async {
    // Mock implementation that returns a fixed profile
    return _createMockProfile(userId);
  }
  
  /// Create a mock profile with valid data
  UserProfile _createMockProfile(String userId) {
    // Create a profile with minimum required fields and correct parameter names
    return UserProfile(
      id: userId,
      username: 'user_$userId',
      displayName: 'User $userId',
      firstName: 'User',
      lastName: userId,
      year: 'Senior',
      major: 'Computer Science',
      residence: 'On Campus',
      eventCount: 5,
      spaceCount: 3,
      friendCount: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now(),
      interests: const ['technology', 'music', 'sports'],
    );
  }
} 