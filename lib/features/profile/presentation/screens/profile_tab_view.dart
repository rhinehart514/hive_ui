import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/widgets/profile/profile_tabs.dart';
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

class _ProfileTabViewState extends ConsumerState<ProfileTabView> {
  /// The currently selected tab index
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom tab bar
        ProfileTabs(
          selectedIndex: _selectedIndex,
          onTabChanged: _handleTabChange,
        ),
        
        // Tab content
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              // Spaces Tab
              SampleSpacesTabContent(
                profile: widget.profile,
                isCurrentUser: widget.isCurrentUser,
              ),
              
              // Events Tab
              SampleEventsTabContent(
                profile: widget.profile,
                isCurrentUser: widget.isCurrentUser,
              ),
              
              // Friends Tab
              SampleFriendsTabContent(
                profile: widget.profile,
                isCurrentUser: widget.isCurrentUser,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Handle tab change
  void _handleTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Log analytics event for tab change
    final String tabName = index == 0 
        ? 'spaces' 
        : index == 1 
            ? 'events' 
            : 'friends';
    
    // TODO: Add analytics tracking when tab changes
    // AnalyticsService.instance.logEvent(
    //   'profile_tab_changed',
    //   parameters: {'tab': tabName},
    // );
  }
} 