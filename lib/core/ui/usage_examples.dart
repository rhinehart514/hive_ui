import 'package:flutter/material.dart';
import 'hive_ui.dart';
import '../animation/staggered_animation_builder.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/platform_utils.dart';

/// Examples of how to use the HIVE UI system
/// This class is for documentation purposes only
class HiveUIExamples {
  /// Example app implementation with proper theming
  static Widget createApp() {
    return HiveUI.createThemedApp(
      title: 'HIVE Platform',
      home: const ExampleScreen(),
    );
  }
}

/// Example screen that showcases various UI components
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HIVE UI Examples', style: AppTypography.titleLarge),
        elevation: 0,
      ),
      body: HiveUI.animatedList(
        itemCount: 10,
        direction: StaggerDirection.bottomToTop,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildCardExample(context);
            case 1:
              return _buildGlassCardExample(context);
            case 2:
              return _buildButtonsExample(context);
            case 3:
              return _buildResponsiveExample(context);
            case 4:
              return _buildGlassBottomSheetExample(context);
            case 5:
              return _buildGlassDialogExample(context);
            default:
              return _buildBasicCardExample(context, 'Example Card $index');
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 0,
        onTap: (_) => PlatformUtils.triggerHaptic(HapticType.selection),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => PlatformUtils.triggerHaptic(HapticType.medium),
        backgroundColor: AppColors.yellow,
        child: const Icon(Icons.add, color: AppColors.black),
      ),
    );
  }

  Widget _buildCardExample(BuildContext context) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.card(
        onTap: () => HiveUI.haptic(HapticType.light),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Standard Card', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Cards are the primary container for content in the HIVE UI. They use the dark gray background with a subtle border.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            HiveUI.accentButton(
              text: 'RSVP Now',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCardExample(BuildContext context) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.card(
        useGlass: true,
        onTap: () => HiveUI.haptic(HapticType.light),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glass Card', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Glass cards use a blur effect for a premium feel. They work best when placed on top of image backgrounds.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            HiveUI.accentButton(
              text: 'View Details',
              onPressed: () {},
              isSmall: true,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsExample(BuildContext context) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Button Examples', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => HiveUI.haptic(HapticType.medium),
              child: const Text('Primary Button'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => HiveUI.haptic(HapticType.light),
              child: const Text('Secondary Button'),
            ),
            const SizedBox(height: 12),
            HiveUI.accentButton(
              text: 'Accent Button',
              onPressed: () {},
              icon: Icons.star,
            ),
            const SizedBox(height: 12),
            HiveUI.accentButton(
              text: 'Small Accent',
              onPressed: () {},
              isSmall: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveExample(BuildContext context) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.responsiveLayout(
        mobile: HiveUI.card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mobile Layout', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              Text(
                'This card adapts to different screen sizes. On mobile, it shows a compact layout.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        tablet: HiveUI.card(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tablet Layout', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'On tablet, this card shows a horizontal layout with more content space.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.tablet_mac, color: AppColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBottomSheetExample(BuildContext context) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glass Bottom Sheet', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Shows a bottom sheet with a glassmorphism effect.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            HiveUI.accentButton(
              text: 'Show Bottom Sheet',
              onPressed: () => _showExampleBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showExampleBottomSheet(BuildContext context) {
    HiveUI.showGlassBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Glass Bottom Sheet', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Text(
            'This is an example of a bottom sheet with a glass effect. It uses blur and transparency to create a premium feel.',
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              HiveUI.accentButton(
                text: 'Confirm',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassDialogExample(BuildContext context) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glass Dialog', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Shows a dialog with a glassmorphism effect.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            HiveUI.accentButton(
              text: 'Show Dialog',
              onPressed: () => _showExampleDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showExampleDialog(BuildContext context) {
    HiveUI.showGlassDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Glass Dialog', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Text(
              'This is an example of a dialog with a glass effect. It uses blur and transparency to create a premium feel.',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                HiveUI.accentButton(
                  text: 'Confirm',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicCardExample(BuildContext context, String title) {
    return Padding(
      padding: HiveUI.getScreenPadding(context),
      child: HiveUI.card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'This is a basic card example that can be used to display various types of content.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 