import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart' hide VerificationStatus; // Hide to avoid conflict
import 'package:hive_ui/features/profile/presentation/widgets/profile_spaces_list.dart';
import 'package:hive_ui/widgets/profile/profile_tab_content.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/features/auth/auth.dart';
import 'package:hive_ui/features/profile/presentation/widgets/profile_role_indicator.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_request_page.dart';
import 'package:hive_ui/features/profile/presentation/screens/verified_plus_request_page.dart';

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
  List<Event> _userEvents = [];
  bool _isLoadingEvents = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize the tab controller with 4 tabs (About + 3 original tabs)
    _tabController = TabController(length: 4, vsync: this);
    
    // Add tab controller listener for haptic feedback and to update selected index
    _tabController.addListener(_handleTabControllerChanged);
    
    // Load events if we start on the events tab
    if (_selectedIndex == 2) { // Events tab is now index 2 instead of 1
      _loadUserEvents();
    }
  }
  
  /// Add a sample test event for debugging purposes
  void _addSampleEvent() {
    final now = DateTime.now();
    final event = Event(
      id: 'test_event_${now.millisecondsSinceEpoch}',
      title: 'Test Event ${now.hour}:${now.minute}',
      description: 'This is a test event added for debugging',
      location: 'Test Location',
      organizerEmail: 'test@example.com',
      organizerName: 'Test Organizer',
      category: 'Test',
      status: 'confirmed',
      link: 'https://example.com',
      startDate: now.add(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1, hours: 2)),
      imageUrl: '',
      source: EventSource.user,
    );
    
    // Add to state
    setState(() {
      _userEvents = [..._userEvents, event];
    });
    
    // Save to repository if this is the current user
    if (widget.isCurrentUser) {
      ref.read(profileProvider.notifier).saveEvent(event);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test event added!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// Load user events from the repository
  Future<void> _loadUserEvents() async {
    if (_isLoadingEvents) return;
    
    setState(() {
      _isLoadingEvents = true;
    });
    
    try {
      debugPrint('Loading user events from repository...');
      final events = await ref.read(profileProvider.notifier).loadSavedEvents();
      debugPrint('Got ${events.length} events from repository');
      
      if (mounted) {
        setState(() {
          _userEvents = events;
          _isLoadingEvents = false;
        });
        
        // If events were loaded but not showing in profile, refresh profile
        if (events.isNotEmpty && widget.profile.savedEvents.isEmpty) {
          debugPrint('Events found in repository but not in profile. Refreshing profile...');
          await ref.read(profileProvider.notifier).refreshProfile();
        }
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
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
      
      // Load events if switching to events tab
      if (_tabController.index == 2) {
        _loadUserEvents();
      }
    }
  }
  
  /// Log tab change analytics
  void _logTabChange(int index) {
    final String tabName = index == 0 
        ? 'about' 
        : index == 1 
            ? 'spaces' 
            : index == 2 
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
    // Add extensive debugging
    debugPrint('ProfileTabView build - profile events count: ${widget.profile.eventCount}');
    debugPrint('ProfileTabView build - profile saved events: ${widget.profile.savedEvents.length}');
    debugPrint('ProfileTabView build - local events: ${_userEvents.length}');
    
    // Print actual event details if available
    if (_userEvents.isNotEmpty) {
      debugPrint('Sample event from _userEvents: ${_userEvents.first.title}');
    }
    if (widget.profile.savedEvents.isNotEmpty) {
      debugPrint('Sample event from profile: ${widget.profile.savedEvents.first.title}');
    }
    
    // Update user events from profile if they're now available
    if (widget.profile.savedEvents.isNotEmpty && _userEvents.isEmpty) {
      _userEvents = widget.profile.savedEvents;
    }
    
    // If we have events from repository but profile doesn't, create a merged profile
    final UserProfile profileWithEvents = widget.profile.savedEvents.isEmpty && _userEvents.isNotEmpty
        ? widget.profile.copyWith(
            savedEvents: _userEvents,
            // Also update the eventCount to match the actual events
            eventCount: _userEvents.length,
          )
        : widget.profile;
    
    debugPrint('Final profile events count being displayed: ${profileWithEvents.savedEvents.length}');

    return Column(
      children: [
        // Custom tab bar with updated tabs to include "About"
        Container(
          color: AppColors.black,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.gold,
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Spaces'),
              Tab(text: 'Events'),
              Tab(text: 'Friends'),
            ],
          ),
        ),
        
        // Only show debug button in events tab and for current user in debug mode
        if (_selectedIndex == 2 && widget.isCurrentUser && true) // Set to false for production
          ElevatedButton(
            onPressed: _addSampleEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Test Event (Debug)'),
          ),
        
        // Tab content with error handling
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // Use physics that match iOS/Android native behavior
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // About Tab with Role Indicator
              _buildTabWithErrorHandling(
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile role indicator
                      Consumer(
                        builder: (context, ref, child) {
                          // Map profile tier to verification status
                          final verificationLevel = _mapToVerificationLevel(profileWithEvents.accountTier);
                          
                          // In a real implementation, this would come from auth providers
                          // For now, use a fixed status based on verification level
                          final verificationStatus = verificationLevel == VerificationLevel.public 
                              ? VerificationStatus.notVerified
                              : VerificationStatus.verified;
                          
                          return ProfileRoleIndicator(
                            isCurrentUser: widget.isCurrentUser,
                            verificationLevel: verificationLevel,
                            verificationStatus: verificationStatus,
                            onUpgradeTap: () {
                              if (verificationLevel == VerificationLevel.public) {
                                // Navigate to verification request
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const VerificationRequestPage(),
                                  ),
                                );
                              } else if (verificationLevel == VerificationLevel.verified) {
                                // Navigate to verified+ request
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const VerifiedPlusRequestPage(),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      
                      // Bio section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profileWithEvents.bio ?? 'No bio provided.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            
                            // More about sections can be added here
                          ],
                        ),
                      ),
                      
                      // Interests section
                      if (profileWithEvents.interests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Interests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profileWithEvents.interests.map((interest) {
                                  return Chip(
                                    label: Text(interest),
                                    backgroundColor: AppColors.black,
                                    side: const BorderSide(color: AppColors.gold, width: 1),
                                    labelStyle: const TextStyle(color: Colors.white),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Spaces Tab
              _buildTabWithErrorHandling(
                ProfileSpacesList(
                  profile: profileWithEvents,
                  isCurrentUser: widget.isCurrentUser,
                  onActionPressed: () {
                    // Navigate to spaces explorer
                    HapticFeedback.mediumImpact();
                  },
                )
              ),
              
              // Events Tab
              _buildTabWithErrorHandling(
                _isLoadingEvents 
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : ProfileTabContent(
                  tabType: ProfileTabType.events,
                  profile: profileWithEvents,
                  isCurrentUser: widget.isCurrentUser,
                  onActionPressed: () {
                    // Navigate to find events
                    HapticFeedback.mediumImpact();
                  },
                )
              ),
              
              // Friends Tab
              _buildTabWithErrorHandling(
                ProfileTabContent(
                  tabType: ProfileTabType.friends,
                  profile: profileWithEvents,
                  isCurrentUser: widget.isCurrentUser,
                  onActionPressed: () {
                    // Navigate to find friends
                    HapticFeedback.mediumImpact();
                  },
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
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
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

  /// Map AccountTier to VerificationLevel
  VerificationLevel _mapToVerificationLevel(AccountTier tier) {
    switch (tier) {
      case AccountTier.verified:
        return VerificationLevel.verified;
      case AccountTier.verifiedPlus:
        return VerificationLevel.verifiedPlus;
      default:
        return VerificationLevel.public;
    }
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