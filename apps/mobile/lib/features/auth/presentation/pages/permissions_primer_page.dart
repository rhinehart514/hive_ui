import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/presentation/widgets/auth_screen_scaffold.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/services/analytics_service.dart';

/// The Permissions Primer page explains why the app needs certain permissions.
///
/// This page is shown during the onboarding flow to set user expectations
/// about permissions the app will request.
class PermissionsPrimerPage extends ConsumerStatefulWidget {
  const PermissionsPrimerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PermissionsPrimerPage> createState() => _PermissionsPrimerPageState();
}

class _PermissionsPrimerPageState extends ConsumerState<PermissionsPrimerPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      title: 'App Permissions',
      isLoading: _isLoading,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'A Few Things HIVE Needs',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'To create the best experience, HIVE will ask for these permissions when you need them:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 40),
          
          // Notifications permission
          _buildPermissionCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            description: 'Stay updated about events, messages, and important happenings',
            accentColor: AppColors.gold,
          ),
          
          // Location permission
          _buildPermissionCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            description: 'Check in to events and discover happenings nearby',
            accentColor: AppColors.info,
          ),
          
          // Camera permission
          _buildPermissionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            description: 'Scan QR codes for events and upload photos to your profile',
            accentColor: AppColors.success,
          ),
          
          const SizedBox(height: 40),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _continueToAccessPass,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Got It',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy note
          Center(
            child: Text(
              'We value your privacy. Permissions are only requested when needed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _continueToAccessPass() {
    setState(() {
      _isLoading = true;
    });

    // Log analytics
    AnalyticsService.logEvent('permissions_primer_completed');

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Navigate to access pass
    if (mounted) {
      context.go('/onboarding/access-pass');
    }

    setState(() {
      _isLoading = false;
    });
  }
} 