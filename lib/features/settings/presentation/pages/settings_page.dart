import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/core/providers/role_checker_provider.dart';
import 'package:hive_ui/core/services/role_checker.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';

/// The main settings screen
class SettingsPage extends ConsumerWidget {
  /// Creates a SettingsPage instance
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access auth controller for sign out functionality
    final authController = ref.watch(authControllerProvider.notifier);
    
    // Check if user is admin for admin-only sections
    final isAdmin = ref.watch(hasRoleProvider(UserRole.admin));
    
    return Scaffold(
      appBar: const HiveAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 8),
          
          // Account Section
          _buildSection(
            title: 'Account',
            icon: Icons.person_outline,
            subtitle: 'Manage your profile and account settings',
            onTap: () {
              // Navigate to account settings
            },
          ),
          
          const Divider(),
          
          // Appearance Section
          _buildSection(
            title: 'Appearance',
            icon: Icons.color_lens_outlined,
            subtitle: 'Theme, font size, display options',
            onTap: () {
              // Navigate to appearance settings
            },
          ),
          
          const Divider(),
          
          // Notifications Section
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            subtitle: 'Manage how you receive notifications',
            onTap: () {
              // Navigate to notification settings
            },
          ),
          
          const Divider(),
          
          // Privacy & Security
          _buildSection(
            title: 'Privacy & Security',
            icon: Icons.security_outlined,
            subtitle: 'Control your data and privacy settings',
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          
          const Divider(),
          
          // Admin Section - only visible to admins
          isAdmin.when(
            data: (isAdmin) {
              if (!isAdmin) return const SizedBox.shrink();
              
              return Column(
                children: [
                  _buildSection(
                    title: 'Verification Admin',
                    icon: Icons.verified_user,
                    subtitle: 'Manage verification requests',
                    onTap: () {
                      context.go(AppRoutes.adminVerification);
                    },
                    color: Colors.amber,
                  ),
                  const Divider(),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // About
          _buildSection(
            title: 'About',
            icon: Icons.info_outline,
            subtitle: 'App version, terms, and support',
            onTap: () {
              // Show about dialog
            },
          ),
          
          const Divider(),
          
          // Sign Out
          _buildSection(
            title: 'Sign Out',
            icon: Icons.exit_to_app,
            subtitle: 'Sign out of your account',
            onTap: () async {
              await authController.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully')),
                );
              }
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 