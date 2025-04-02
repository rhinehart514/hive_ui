import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/pages/main_feed.dart';
import 'package:hive_ui/pages/profile_page.dart';
import 'package:hive_ui/features/spaces/presentation/pages/spaces_page.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_list_screen.dart';
import 'package:hive_ui/utils/navigation_transitions.dart';
import 'package:hive_ui/components/navigation_bar.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/theme/app_colors.dart';

class AppContainer extends StatefulWidget {
  const AppContainer({super.key});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  // Track the previous index to determine direction
  int _previousIndex = 0;

  final List<Widget> _pages = [
    const MainFeed(),
    const SpacesPage(),
    const ChatListScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();

    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      // Store the previous index before updating
      _previousIndex = _selectedIndex;

      // Apply appropriate haptic feedback
      NavigationTransitions.applyNavigationFeedback(
        type: NavigationFeedbackType.tabChange,
      );

      setState(() {
        _selectedIndex = index;
      });

      // Animate to the selected page with a fluid motion
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Custom page builder that applies fluid transitions
  Widget _buildPage(BuildContext context, int index) {
    // Determine if page is current, next, or previous
    final isCurrentPage = index == _selectedIndex;
    final isNextPage = index == _selectedIndex + 1;
    final isPreviousPage = index == _selectedIndex - 1;

    // Add logic to use _previousIndex for direction awareness
    final isComingFromPrevious =
        _previousIndex < _selectedIndex && index == _previousIndex;
    final isComingFromNext =
        _previousIndex > _selectedIndex && index == _previousIndex;

    // Only animate pages that are adjacent or current
    if (!isCurrentPage &&
        !isNextPage &&
        !isPreviousPage &&
        !isComingFromPrevious &&
        !isComingFromNext) {
      return _pages[index];
    }

    // Calculate animation progress
    double animationProgress = 0.0;
    if (isCurrentPage) {
      animationProgress = 1.0;
    } else if (isNextPage ||
        isPreviousPage ||
        isComingFromPrevious ||
        isComingFromNext) {
      // For adjacent pages, safely calculate animation progress
      // The PageController.page property is only available after the PageView has been built
      // So we need to handle the case when it's null
      double pageOffset;
      try {
        // Only try to access page if controller is attached and has clients
        pageOffset = _pageController.hasClients
            ? (_pageController.page ?? _selectedIndex.toDouble())
            : _selectedIndex.toDouble();
      } catch (e) {
        // Fallback to selected index if any error occurs
        pageOffset = _selectedIndex.toDouble();
      }
      final double distance = (pageOffset - index).abs();
      animationProgress = 1.0 - distance;
    }

    // Apply subtle scale, translation and fade effects
    return Transform.scale(
      scale: 0.9 + (0.1 * animationProgress),
      child: Transform.translate(
        offset: Offset(
          isNextPage
              ? 20.0 * (1.0 - animationProgress)
              : (isPreviousPage || isComingFromPrevious
                  ? -20.0 * (1.0 - animationProgress)
                  : 0.0),
          0.0,
        ),
        child: Opacity(
          opacity: 0.7 + (0.3 * animationProgress),
          child: _pages[index],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI properties - ensure navigation bar is black
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          _pages.length,
          (index) => _buildPage(context, index),
        ),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: HiveNavigationBar(
        key: const ValueKey('main_nav_bar'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavItemTapped,
        style: HiveNavigationBarStyle.ios,
        selectedItemColor: AppColors.gold,
        destinations: const [
          HiveNavigationDestination(
            icon: HugeIcons.home,
            selectedIcon: HugeIcons.home,
            label: 'Feed',
          ),
          HiveNavigationDestination(
            icon: HugeIcons.constellation,
            selectedIcon: HugeIcons.constellation,
            label: 'Spaces',
          ),
          HiveNavigationDestination(
            icon: HugeIcons.message,
            selectedIcon: HugeIcons.message,
            label: 'Messages',
          ),
          HiveNavigationDestination(
            icon: HugeIcons.user,
            selectedIcon: HugeIcons.user,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
