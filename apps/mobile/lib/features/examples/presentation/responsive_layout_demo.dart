import 'package:flutter/material.dart';
import '../../../core/ui/responsive_layout.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:ui';

/// Demo screen showcasing the responsive layout implementation
/// following HIVE brand aesthetics
class ResponsiveLayoutDemo extends StatelessWidget {
  const ResponsiveLayoutDemo({Key? key}) : super(key: key);

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
              _buildHeader(context, "Mobile View"),
              const SizedBox(height: 24),
              _buildFeaturedContent(context),
              const SizedBox(height: 24),
              _buildContentGrid(crossAxisCount: 1),
              const SizedBox(height: 24),
              _buildBottomSection(),
            ],
          ),
        ),
        _buildBottomNav(),
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
                    _buildHeader(context, "Tablet View"),
                    const SizedBox(height: 24),
                    _buildFeaturedContent(context),
                    const SizedBox(height: 32),
                    _buildContentGrid(crossAxisCount: 2),
                    const SizedBox(height: 32),
                    _buildBottomSection(),
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
                width: 240,
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
                        _buildHeader(context, "Desktop View"),
                        const SizedBox(height: 24),
                        _buildFeaturedContent(context, isLarge: true),
                        const SizedBox(height: 40),
                        _buildContentGrid(crossAxisCount: 3),
                        const SizedBox(height: 40),
                        _buildBottomSection(),
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

  Widget _buildHeader(BuildContext context, String viewName) {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HIVE UI',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: sizeInfo.isMobile ? 28 : 36,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Responsive Layout Demo - $viewName',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: sizeInfo.isMobile ? 16 : 20,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This demo showcases the responsive layout system following HIVE\'s sophisticated dark infrastructure aesthetic with proper handling of different screen sizes.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: sizeInfo.isMobile ? 14 : 16,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar({required bool isMobile}) {
    return _buildGlassContainer(
      height: 60,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 8,
      ),
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
    return _buildGlassContainer(
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 24,
        horizontal: isExpanded ? 16 : 8,
      ),
      child: Column(
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', isExpanded: isExpanded, isSelected: true),
          _buildNavItem(Icons.explore_outlined, 'Explore', isExpanded: isExpanded),
          _buildNavItem(Icons.event_outlined, 'Events', isExpanded: isExpanded),
          _buildNavItem(Icons.groups_outlined, 'Spaces', isExpanded: isExpanded),
          _buildNavItem(Icons.message_outlined, 'Messages', isExpanded: isExpanded),
          const Spacer(),
          _buildNavItem(Icons.settings_outlined, 'Settings', isExpanded: isExpanded),
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

  Widget _buildFeaturedContent(BuildContext context, {bool isLarge = false}) {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        return _buildGlassContainer(
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
            return _buildGlassContainer(
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

  Widget _buildBottomSection() {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        return _buildGlassContainer(
          padding: sizeInfo.contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HIVE Brand Aesthetic',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: sizeInfo.isMobile ? 18 : 22,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "HIVE is a premium, living interface for real social energy. Every pixel should respond with calm clarity, subtle momentum, and system-level elegance. The platform doesn't show off - it implies energy through motion, restraint, and immersive tactility.",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: sizeInfo.isMobile ? 14 : 16,
                  height: 1.5,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildAestheticFeature(
                      icon: Icons.blur_on,
                      title: 'Kinetic Sophistication',
                      description: 'Visuals respond to pressure, tempo, and presence',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAestheticFeature(
                      icon: Icons.layers,
                      title: 'Invisible Depth',
                      description: 'Transparent, blurred, soft surfaces that feel like an OS layer',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAestheticFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ResponsiveBuilder(
      builder: (context, sizeInfo) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.gold,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: sizeInfo.isMobile ? 14 : 16,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: sizeInfo.isMobile ? 12 : 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return _buildGlassContainer(
      height: 60,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home_outlined, 'Home', isSelected: true),
          _buildBottomNavItem(Icons.explore_outlined, 'Explore'),
          _buildBottomNavItem(Icons.add_circle_outline, 'Create'),
          _buildBottomNavItem(Icons.message_outlined, 'Messages'),
          _buildBottomNavItem(Icons.person_outline, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: isSelected ? AppColors.gold : AppColors.white.withOpacity(0.8),
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// A helper method to create glass container with HIVE aesthetic
  Widget _buildGlassContainer({
    Widget? child,
    EdgeInsetsGeometry? padding,
    double? width,
    double? height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15.0,
          sigmaY: 15.0,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfacePrimary.withOpacity(0.8),
                AppColors.surfaceSecondary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
} 