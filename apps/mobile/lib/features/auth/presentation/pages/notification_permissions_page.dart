import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_ui/features/auth/presentation/widgets/auth_screen_scaffold.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/services/analytics_service.dart';

/// The Notification Permissions page requests notification permissions from the user.
///
/// This page explains why notifications are important and guides the user
/// through granting notification permissions.
class NotificationPermissionsPage extends ConsumerStatefulWidget {
  const NotificationPermissionsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationPermissionsPage> createState() => _NotificationPermissionsPageState();
}

class _NotificationPermissionsPageState extends ConsumerState<NotificationPermissionsPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  PermissionStatus _notificationStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check permission status when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      title: 'Notifications',
      isLoading: _isLoading,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 50,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Stay Connected',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enable notifications to stay updated on events, friend activity, and important updates.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          _buildPermissionBenefits(),
          
          const SizedBox(height: 40),
          
          // Button states change based on permission status
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePermissionRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _getButtonText(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip button
          if (_notificationStatus != PermissionStatus.granted)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : _skipPermission,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Not Now',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionBenefits() {
    return Column(
      children: [
        _buildBenefitItem(
          icon: Icons.event_outlined,
          title: 'Event Reminders',
          description: 'Get notified when events are starting soon',
        ),
        _buildBenefitItem(
          icon: Icons.message_outlined,
          title: 'Direct Messages',
          description: 'Never miss important messages from friends',
        ),
        _buildBenefitItem(
          icon: Icons.groups_outlined,
          title: 'Community Activity',
          description: 'See updates when your friends join events',
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
            size: 24,
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
                    fontWeight: FontWeight.w500,
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

  Future<void> _handlePermissionRequest() async {
    if (_notificationStatus == PermissionStatus.granted) {
      _continueToNextScreen();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Request notification permission
      final status = await Permission.notification.request();
      
      setState(() {
        _notificationStatus = status;
      });
      
      // Log analytics
      AnalyticsService.logEvent(
        'notification_permission_result',
        parameters: {'status': status.toString()},
      );
      
      // Provide haptic feedback
      HapticFeedback.lightImpact();
      
      if (status == PermissionStatus.granted) {
        // If granted, continue to the next screen
        _continueToNextScreen();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _skipPermission() {
    // Log analytics
    AnalyticsService.logEvent('notification_permission_skipped');
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Continue to the next screen
    _continueToNextScreen();
  }

  void _continueToNextScreen() {
    if (mounted) {
      // Navigate to the next screen in the onboarding flow
      context.go('/onboarding/location-permissions');
    }
  }

  String _getButtonText() {
    switch (_notificationStatus) {
      case PermissionStatus.granted:
        return 'Continue';
      case PermissionStatus.denied:
        return 'Enable Notifications';
      case PermissionStatus.permanentlyDenied:
        return 'Open Settings';
      default:
        return 'Enable Notifications';
    }
  }

  Color _getButtonColor() {
    if (_notificationStatus == PermissionStatus.granted) {
      return AppColors.success;
    }
    return AppColors.gold;
  }
} 