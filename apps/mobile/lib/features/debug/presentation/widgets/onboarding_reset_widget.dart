import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/scripts/reset_onboarding_status.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:go_router/go_router.dart';

/// A widget that provides controls to reset onboarding status.
///
/// This widget is intended for debugging purposes and should only be
/// included in development builds.
class OnboardingResetWidget extends ConsumerWidget {
  /// Creates an instance of [OnboardingResetWidget].
  const OnboardingResetWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboarding Debug Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Current onboarding status:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            _buildOnboardingStatus(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResetButton(context),
                _buildGoToOnboardingButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOnboardingStatus() {
    return Builder(
      builder: (context) {
        final hasCompleted = UserPreferencesService.hasCompletedOnboarding();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasCompleted ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            hasCompleted ? 'Completed' : 'Not Completed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildResetButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        // Show confirmation dialog
        final shouldReset = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Onboarding?'),
            content: const Text('This will reset the onboarding status and force '
                'the user to go through onboarding again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ?? false;
        
        if (!shouldReset || !context.mounted) return;
        
        // Reset onboarding
        final result = await ResetOnboardingStatusScript.resetOnboardingComplete();
        
        if (!context.mounted) return;
        
        // Show result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reset result: ${result ? "SUCCESS" : "FAILED"}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
        
        // Force widget to rebuild to show updated status
        (context as Element).markNeedsBuild();
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Reset Onboarding'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  Widget _buildGoToOnboardingButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Navigate to onboarding
        context.go('/onboarding');
      },
      icon: const Icon(Icons.navigate_next),
      label: const Text('Go to Onboarding'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
} 