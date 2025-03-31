import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/utils/mock_data/load_mock_data.dart';

/// A debug button widget for quickly signing in as the mock Goose Chaser profile
class MockLoginButton extends ConsumerWidget {
  /// Constructor
  const MockLoginButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Text(
            'Debug Options',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _loadMockProfile(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            icon: const Icon(Icons.bug_report_outlined, color: AppColors.gold),
            label: Text(
              'Load Mock Profile: Goose Chaser',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _signin(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: AppColors.gold, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Sign in as Goose Chaser',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Load the mock profile data into Firestore
  Future<void> _loadMockProfile(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await MockDataLoader.loadMockProfiles(context);
  }
  
  /// Sign in as the mock profile and navigate to the feed
  void _signin(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    // Here you would integrate with your actual authentication service
    // For now we'll just simulate the login with a success dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signed in as Goose Chaser'),
        content: const Text('This is a debug feature. You are now signed in as the mock Goose Chaser profile.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to the feed
              context.go('/feed');
            },
            child: const Text('Go to Feed'),
          ),
        ],
      ),
    );
  }
} 