import 'package:flutter/material.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// A utility script to reset onboarding status.
/// 
/// This script can be used during development or for testing purposes to reset
/// the onboarding status flag, forcing users to go through the onboarding flow again.
class ResetOnboardingStatusScript {
  /// Resets the onboarding status flag only.
  static Future<bool> resetOnboardingFlag() async {
    try {
      // First initialize the service
      await UserPreferencesService.initialize();
      
      // Reset the onboarding status
      final result = await UserPreferencesService.setOnboardingCompleted(false);
      
      debugPrint('ResetOnboardingStatusScript: Reset onboarding status result: $result');
      return result;
    } catch (e) {
      debugPrint('ResetOnboardingStatusScript: Error resetting onboarding status: $e');
      return false;
    }
  }
  
  /// Resets both the onboarding status flag and clears the profile data.
  /// 
  /// This is a more aggressive reset that will clear all user profile data,
  /// forcing a complete fresh start through the onboarding process.
  static Future<bool> resetOnboardingComplete() async {
    try {
      // First initialize the service
      await UserPreferencesService.initialize();
      
      // Clear the profile data
      final clearResult = await UserPreferencesService.clearProfile();
      debugPrint('ResetOnboardingStatusScript: Clear profile result: $clearResult');
      
      // Reset the onboarding status
      final resetResult = await UserPreferencesService.resetOnboardingStatus();
      debugPrint('ResetOnboardingStatusScript: Reset onboarding status result: $resetResult');
      
      return clearResult && resetResult;
    } catch (e) {
      debugPrint('ResetOnboardingStatusScript: Error performing complete reset: $e');
      return false;
    }
  }
  
  /// Execute the script from a widget for testing.
  static Widget buildTestButton() {
    return Builder(
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await resetOnboardingFlag();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Reset onboarding flag: ${result ? "SUCCESS" : "FAILED"}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Reset Onboarding Flag'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final result = await resetOnboardingComplete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Complete reset: ${result ? "SUCCESS" : "FAILED"}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Complete Reset (Clear Profile)'),
            ),
          ],
        );
      },
    );
  }
} 