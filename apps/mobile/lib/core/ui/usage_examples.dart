import 'package:flutter/material.dart';
import 'hive_ui.dart';
import '../animation/staggered_animation_builder.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/platform_utils.dart';
import 'responsive_layout.dart';

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

/// Example of the enhanced responsive layout system
/// Shows how to create responsive layouts that follow HIVE aesthetic guidelines
class ResponsiveLayoutExample extends StatelessWidget {
  const ResponsiveLayoutExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: ResponsiveLayout(
          // Mobile layout (portrait phones)
          mobile: _buildMobileLayout(context),
          
          // Tablet layout (larger devices and landscape)
          tablet: _buildTabletLayout(context),
          
          // Desktop layout (web and large screens)
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(isMobile: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              _buildFeaturedContent(),
              const SizedBox(height: 24),
              _buildContentGrid(crossAxisCount: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(isMobile: false),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Side navigation
              SizedBox(
                width: 80,
                child: _buildSideNav(),
              ),
              
              // Main content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildFeaturedContent(),
                    const SizedBox(height: 32),
                    _buildContentGrid(crossAxisCount: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(isMobile: false),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full side navigation
              SizedBox(
                width: 220,
                child: _buildSideNav(isExpanded: true),
              ),
              
              // Main content area
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        _buildFeaturedContent(isLarge: true),
                        const SizedBox(height: 40),
                        _buildContentGrid(crossAxisCount: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar({required bool isMobile}) {
    return ResponsiveContainer(
      height: 60,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 8,
      ),
      applyGlassmorphism: true,
      child: Row(
        children: [
          // Logo
          const Text(
            'HIVE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.white,
            ),
          ),
          
          const Spacer(),
          
          // Action buttons
          if (!isMobile) ...[
            _buildActionButton(Icons.search, 'Search'),
            const SizedBox(width: 16),
            _buildActionButton(Icons.notifications_outlined, 'Notifications'),
            const SizedBox(width: 16),
          ],
          _buildActionButton(Icons.account_circle_outlined, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSideNav({bool isExpanded = false}) {
    return ResponsiveContainer(
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 24,
        horizontal: isExpanded ? 16 : 8,
      ),
      applyGlassmorphism: true,
      child: Column(
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', isExpanded: isExpanded, isSelected: true),
          _buildNavItem(Icons.explore_outlined, 'Explore', isExpanded: isExpanded),
          _buildNavItem(Icons.event_outlined, 'Events', isExpanded: isExpanded),
          _buildNavItem(Icons.groups_outlined, 'Spaces', isExpanded: isExpanded),
          _buildNavItem(Icons.message_outlined, 'Messages', isExpanded: isExpanded),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isExpanded = false, bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.8),
            size: 28,
          ),
          if (isExpanded) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(
          icon, 
          color: AppColors.white,
          size: 24,
        ),
        onPressed: () {},
      ),
    );
  }

  Widget _buildFeaturedContent({bool isLarge = false}) {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        return ResponsiveContainer(
          applyGlassmorphism: true,
          height: isLarge ? 400 : 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image with overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The actual image would be here
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.darkGray,
                            AppColors.black,
                          ],
                        ),
                      ),
                    ),
                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content overlay
              Padding(
                padding: sizeInfo.contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Dynamic content size based on device
                    Text(
                      'THE BRACKET: FINAL ROUND',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: isLarge ? 36 : (sizeInfo.isMobile ? 24 : 28),
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: isLarge ? 16 : 8),
                    Text(
                      'CS vs Engineering — Vote for your department in the final showdown!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isLarge ? 20 : (sizeInfo.isMobile ? 14 : 16),
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: isLarge ? 24 : 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLarge ? 32 : 24, 
                          vertical: isLarge ? 16 : 12
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'CAST YOUR VOTE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: isLarge ? 16 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentGrid({required int crossAxisCount}) {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return ResponsiveContainer(
              applyGlassmorphism: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    index.isEven ? Icons.event : Icons.group,
                    color: AppColors.white,
                    size: sizeInfo.isMobile ? 40 : 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    index.isEven ? 'Event Card' : 'Space Card',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: sizeInfo.isMobile ? 14 : 16,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: sizeInfo.isMobile ? 12 : 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 