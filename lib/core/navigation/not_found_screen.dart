import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_text_styles.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/utils/glass_effect.dart';

/// A 404 screen with recovery options and popular destinations
class NotFoundScreen extends ConsumerWidget {
  /// The requested path that wasn't found
  final String? path;
  /// Whether this is a deep link error
  final bool isDeepLinkError;
  
  /// Constructor
  const NotFoundScreen({
    super.key, 
    this.path,
    this.isDeepLinkError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 404 Error Icon
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 80,
                ),
                
                const SizedBox(height: 24),
                
                // 404 Text
                Text(
                  '404',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Page Not Found Text
                Text(
                  isDeepLinkError ? 'Invalid Link' : 'Page Not Found',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Path Info
                if (path != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      path!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'RobotoMono',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Description
                Text(
                  isDeepLinkError
                      ? 'The link you followed doesn\'t appear to be valid. It may have expired or been removed.'
                      : 'Sorry, we couldn\'t find the page you were looking for. It might have been moved or deleted.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Go Home Button
                SizedBox(
                  width: size.width * 0.7,
                  child: ElevatedButton.icon(
                    onPressed: () => GoRouter.of(context).go(AppRoutes.home),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Return to Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Popular Destinations Header
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Popular Destinations',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Popular Destinations Shortcuts
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildDestinationCard(
                      context,
                      title: 'Feed',
                      icon: Icons.dynamic_feed_rounded,
                      route: AppRoutes.home,
                    ),
                    _buildDestinationCard(
                      context,
                      title: 'Spaces',
                      icon: Icons.groups_rounded,
                      route: AppRoutes.spaces,
                    ),
                    _buildDestinationCard(
                      context,
                      title: 'Events',
                      icon: Icons.event_rounded,
                      route: AppRoutes.spaces,
                    ),
                    _buildDestinationCard(
                      context,
                      title: 'Profile',
                      icon: Icons.person_rounded,
                      route: AppRoutes.profile,
                    ),
                    _buildDestinationCard(
                      context,
                      title: 'Organizations',
                      icon: Icons.business_rounded,
                      route: AppRoutes.getOrganizationsPath(),
                    ),
                    _buildDestinationCard(
                      context,
                      title: 'Settings',
                      icon: Icons.settings_rounded,
                      route: AppRoutes.settings,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Back Button
                if (GoRouter.of(context).canPop())
                  TextButton.icon(
                    onPressed: () => GoRouter.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build a destination shortcut card
  Widget _buildDestinationCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).go(route),
      child: GlassContainer(
        borderRadius: 12.0,
        opacity: 0.1,
        blur: 10.0,
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.gold,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 