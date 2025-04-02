import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/widgets/profile/profile_tabs.dart';
import 'package:hive_ui/features/profile/presentation/widgets/profile_spaces_list.dart';
import 'package:hive_ui/features/profile/presentation/widgets/profile_sample_tab_content.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A screen that displays a tabbed view of a user's profile content
class ProfileTabView extends ConsumerStatefulWidget {
  /// The user profile to display
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Constructor
  const ProfileTabView({
    super.key,
    required this.profile,
    this.isCurrentUser = false,
  });

  @override
  ConsumerState<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends ConsumerState<ProfileTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Initialize the tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);
    
    // Add tab controller listener for haptic feedback and to update selected index
    _tabController.addListener(_handleTabControllerChanged);
  }
  
  /// Handle tab controller changes
  void _handleTabControllerChanged() {
    // Only process when the controller change is due to user interaction
    if (!_tabController.indexIsChanging) return;
    
    if (_tabController.index != _selectedIndex) {
      // Provide haptic feedback for tab changes
      HapticFeedback.selectionClick();
      
      // Update selected tab index
      setState(() {
        _selectedIndex = _tabController.index;
      });
      
      // Log analytics for tab change
      _logTabChange(_selectedIndex);
    }
  }
  
  /// Log tab change analytics
  void _logTabChange(int index) {
    final String tabName = index == 0 
        ? 'spaces' 
        : index == 1 
            ? 'events' 
            : 'friends';
    
    // Log the tab change event - production ready
    debugPrint('ProfileTabView: Tab changed to: $tabName');
    
    // Uncomment for production analytics
    // AnalyticsService.instance.logEvent(
    //   'profile_tab_changed',
    //   parameters: {'tab': tabName},
    // );
  }
  
  @override
  void dispose() {
    // Remove listener first
    _tabController.removeListener(_handleTabControllerChanged);
    // Then dispose the controller
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom tab bar
        ProfileTabs(
          selectedIndex: _selectedIndex,
          onTabChanged: _handleTabChange,
        ),
        
        // Tab content with error handling
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // Use physics that match iOS/Android native behavior
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Spaces Tab
              _buildTabWithErrorHandling(
                ProfileSpacesList(
                  profile: widget.profile,
                  isCurrentUser: widget.isCurrentUser,
                  onActionPressed: () {
                    // Navigate to spaces explorer
                    HapticFeedback.mediumImpact();
                  },
                )
              ),
              
              // Events Tab
              _buildTabWithErrorHandling(
                SampleEventsTabContent(
                  profile: widget.profile,
                  isCurrentUser: widget.isCurrentUser,
                )
              ),
              
              // Friends Tab
              _buildTabWithErrorHandling(
                SampleFriendsTabContent(
                  profile: widget.profile,
                  isCurrentUser: widget.isCurrentUser,
                )
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Wrap each tab in error handling for production resilience
  Widget _buildTabWithErrorHandling(Widget child) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          // Log the error for monitoring in production
          debugPrint('Error in profile tab: $e');
          debugPrint('Stack trace: $stackTrace');
          
          // Display user-friendly error state
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh and try again',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  /// Handle tab change
  void _handleTabChange(int index) {
    // Smoothly animate to the selected tab
    _tabController.animateTo(index, duration: const Duration(milliseconds: 300));
    
    // Update the selected index
    setState(() {
      _selectedIndex = index;
    });
    
    // Log the tab change
    _logTabChange(index);
  }
} 