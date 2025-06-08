import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:hive_ui/features/onboarding/state/onboarding_state.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';
import 'package:hive_ui/features/user/domain/repositories/user_repository.dart';
import 'package:hive_ui/features/user/providers/user_providers.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

/// Service responsible for submitting the completed onboarding profile data.
class ProfileSubmissionService {
  final UserRepository _userRepository;
  final FirebaseAuth _firebaseAuth;

  ProfileSubmissionService(this._userRepository, this._firebaseAuth);

  /// Submits the onboarding profile data to the backend.
  /// 
  /// Takes the current [OnboardingState] and builds a [UserProfile] object
  /// to be saved via the [UserRepository].
  Future<void> submitProfile(OnboardingState state) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      debugPrint('ProfileSubmissionService: No authenticated user found');
      throw Exception('User not authenticated during profile submission.');
    }
    final userId = user.uid;
    debugPrint('ProfileSubmissionService: Processing profile submission for user $userId');

    // EXTREMELY MINIMAL VALIDATION - only requires an authenticated user
    // All other fields will use fallbacks if missing
    debugPrint('ProfileSubmissionService: Current state values:');
    debugPrint('  First name: ${state.firstName}');
    debugPrint('  Last name: ${state.lastName}');
    debugPrint('  Username: ${state.username}');
    debugPrint('  Year: ${state.year}');
    debugPrint('  Major: ${state.major}');
    debugPrint('  Residence: ${state.residenceType}');
    debugPrint('  Interests: ${state.interests.length} items');

    // Map AccountTier string to enum
    AccountTier tier = AccountTier.standard; // Default
    if (state.accountTier == 'verified') {
       tier = AccountTier.verified;
    } else if (state.accountTier == 'verified_plus') {
       tier = AccountTier.verifiedPlus;
    }
    debugPrint('ProfileSubmissionService: User tier set to ${tier.name}');

    // Build the UserProfile entity with fallbacks for ALL fields
    final profileData = UserProfile(
      id: userId, 
      displayName: state.firstName != null && state.firstName!.isNotEmpty 
          ? '${state.firstName} ${state.lastName ?? ""}'
          : user.email?.split('@').first ?? 'New User',
      username: (state.username != null && state.username!.isNotEmpty)
          ? state.username
          : 'user_${DateTime.now().millisecondsSinceEpoch % 10000}',
      email: user.email, // Get email from FirebaseAuth user
      interests: state.interests.isNotEmpty ? state.interests : ['general'],
      year: state.year ?? '',
      major: state.major ?? '',
      residenceType: state.residenceType ?? '',
      accountTier: tier, 
      bio: '', // Empty for now
      // Other fields like location, photoUrl will be updated later via profile editing
      // createdAt will be set by Firestore on first creation
      // updatedAt will be set by the repository on update
    );
    
    debugPrint('ProfileSubmissionService: Submitting profile for user $userId');

    try {
      // Track submission start for analytics
      // Check if Realtime Database is supported on this platform (Windows issue)
      if (!RealtimeDbWindowsFix.needsSpecialHandling || RealtimeDbWindowsFix.isSupported) {
        AnalyticsService.logEvent('onboarding_profile_submission_attempt', parameters: {
          'user_id': userId,
          'has_interests': profileData.interests.isNotEmpty,
          'tier': tier.name,
        });
      } else {
        // Still log locally on Windows platform
        debugPrint('📊 Local analytics (Windows): onboarding_profile_submission_attempt - userId: $userId, interests: ${profileData.interests.length}, tier: ${tier.name}');
      }
      
      // Update the user profile
      await _userRepository.updateUserProfile(userId, profileData);
      
      // Track successful submission
      if (!RealtimeDbWindowsFix.needsSpecialHandling || RealtimeDbWindowsFix.isSupported) {
        AnalyticsService.logEvent('onboarding_profile_completed', parameters: {
          'user_id': userId,
          'interests_count': profileData.interests.length,
          'tier': tier.name,
        });
      } else {
        debugPrint('ProfileSubmissionService: Skipping analytics event due to Realtime Database issues on Windows');
      }
      
      debugPrint('ProfileSubmissionService: Profile submitted successfully for user $userId');
    } catch (e) {
      // Track failed submission
      if (!RealtimeDbWindowsFix.needsSpecialHandling || RealtimeDbWindowsFix.isSupported) {
        AnalyticsService.logEvent('onboarding_profile_submission_failed', parameters: {
          'user_id': userId,
          'error': e.toString(),
        });
      } else {
        debugPrint('ProfileSubmissionService: Skipping analytics event due to Realtime Database issues on Windows');
      }
      
      debugPrint('ProfileSubmissionService: Error submitting profile for user $userId: $e');
      // Propagate error to be handled by the UI/notifier
      rethrow;
    }
  }
}

/// Provider for the ProfileSubmissionService.
final profileSubmissionServiceProvider = Provider<ProfileSubmissionService>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return ProfileSubmissionService(userRepository, firebaseAuth);
}); 