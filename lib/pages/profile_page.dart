import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/widgets/profile/profile_header.dart';
import 'package:hive_ui/widgets/profile/profile_tab_content.dart' as content;
import 'package:hive_ui/widgets/profile/profile_skeleton_loader.dart';
import 'package:hive_ui/widgets/profile/modern_profile_editor.dart';
import 'package:hive_ui/widgets/profile/profile_image_viewer.dart';
import 'package:hive_ui/widgets/profile/verified_plus_dialog.dart';
import 'package:hive_ui/widgets/profile/profile_tab_bar.dart';
import 'package:hive_ui/widgets/profile/profile_share_modal.dart';
import 'package:hive_ui/widgets/profile/profile_interaction_buttons.dart';
import 'package:hive_ui/constants/interest_options.dart';
import 'package:hive_ui/providers/admin_provider.dart';
import 'package:hive_ui/providers/friend_providers.dart';

// Models
import 'package:hive_ui/models/user_profile.dart';

// New architecture providers
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_media_provider.dart';
import 'package:hive_ui/features/profile/presentation/providers/social_providers.dart';

// Keep services
import 'package:hive_ui/services/profile_sharing_service.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/features/profile/presentation/widgets/profile_accessibility_helper.dart';

/// Provider to track whether the profile page is viewing the current user or another user
final isCurrentUserProfileProvider = StateProvider<bool>((ref) => true);

@RoutePage()
class ProfilePage extends ConsumerStatefulWidget {
  final String? userId; // If null, shows the current user's profile
  final bool fromOnboarding; // Flag to indicate if coming from onboarding

  const ProfilePage({
    super.key,
    this.userId,
    this.fromOnboarding = false,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize timezone database
    tz.initializeTimeZones();

    // Initialize TabController with correct length
    // (3 tabs - Spaces, Events, Friends)
    _tabController = TabController(length: 3, vsync: this);

    // Set initial tab index to 2 (Friends) for debugging the friends tab
    _tabController.index = 2;

    // DON'T modify providers in initState - moved to didChangeDependencies
    
    // Add tab controller listener for haptic feedback
    // Wrap in try-catch to prevent any TabController issues
    try {
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          HapticFeedback.selectionClick();
        }
      });
    } catch (e) {
      debugPrint('Error adding TabController listener: $e');
    }

    // Add auth state listener
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && mounted) {
        // If user is not authenticated, redirect to sign in
        context.go('/sign-in');
      }
    });

    // Schedule initialization for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safely set isCurrentUserProfile here instead of in initState
    // This is called after the widget is fully built
    final isCurrentUserProfile = widget.userId == null;
    Future.microtask(() {
      if (mounted) {
        ref.read(isCurrentUserProfileProvider.notifier).state = isCurrentUserProfile;
      }
    });
    
    // Always use real data for both current user and other profiles
    Future.microtask(() {
      if (mounted) {
        debugPrint('Profile page: Loading profile data for ${widget.userId ?? 'current user'}');
        if (widget.userId != null) {
          // Load another user's profile using loadProfile with userId parameter
          ref.read(profileProvider.notifier).loadProfile(widget.userId!);
        } else {
          // For current user profile, refresh to ensure data is up-to-date
          ref.read(profileProvider.notifier).refreshProfile();
        }
      }
    });
  }

  @override
  void dispose() {
    // Clean up controllers properly to prevent memory leaks
    try {
      _tabController.removeListener(() {});
      _tabController.dispose();
    } catch (e) {
      debugPrint('Error disposing TabController: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminStatus = ref.watch(adminStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final profileState = ref.watch(profileProvider);

          // Use our custom whenWidget method
          return profileState.whenWidget(
            data: (profile) {
              _initializeServices();
              return _buildProfileView(profile, adminStatus);
            },
            loading: () => const ProfileSkeletonLoader(),
            error: (error) => _buildErrorState(error ?? 'Unknown error'),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.profile,
              size: 48.0,
              color: Colors.red,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12.0),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: () {
                // Use the new provider
                ref.read(profileProvider.notifier).refreshProfile();
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const HugeIcon(
                icon: HugeIcons.profile,
                size: 20,
                color: Colors.black,
              ),
              label: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile, AsyncValue<bool> adminStatus) {
    final isCurrentUser = widget.userId == null;

    // Using media query to adapt to different screen sizes
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Tab view content with optimized accessibility
    final tabViews = [
      content.ProfileTabContent(
        tabType: content.ProfileTabType.spaces,
        profile: profile,
        isCurrentUser: isCurrentUser,
        onActionPressed: () {
          // Navigate to spaces discovery
          HapticFeedback.mediumImpact();
          _navigateToSpaces(context);
        },
      ),
      content.ProfileTabContent(
        tabType: content.ProfileTabType.events,
        profile: profile,
        isCurrentUser: isCurrentUser,
        onActionPressed: () {
          // Navigate to events discovery
          HapticFeedback.mediumImpact();
        },
      ),
      content.ProfileTabContent(
        tabType: content.ProfileTabType.friends,
        profile: profile,
        isCurrentUser: isCurrentUser,
        onActionPressed: () {
          // Navigate to friends discovery
          HapticFeedback.mediumImpact();
        },
      ),
    ];

    // Use the accessible tab view from our helper
    final accessibleTabBarView = ProfileAccessibilityHelper.createAccessibleTabView(
      tabController: _tabController,
      children: tabViews,
      tabLabels: ['Spaces', 'Events', 'Friends'],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            // Build the profile header
            return <Widget>[
              SliverToBoxAdapter(
                child: ProfileHeader(
                  profile: profile,
                  isCurrentUser: isCurrentUser,
                  onImageFromCamera: (imagePath) {
                    // Update profile image
                    ref.read(profileMediaProvider.notifier)
                        .updateProfileImageFromCamera();
                  },
                  onImageFromGallery: (imagePath) {
                    // Update profile image
                    ref.read(profileMediaProvider.notifier)
                        .updateProfileImageFromGallery();
                  },
                  onImageRemoved: () {
                    // Remove profile image
                    ref.read(profileMediaProvider.notifier)
                        .removeProfileImage();
                  },
                  onImageTap: () {
                    if (profile.profileImageUrl?.isNotEmpty == true) {
                      showProfileImageViewer(context, profile.profileImageUrl!);
                    }
                  },
                  onVerifiedPlusTap: isCurrentUser
                      ? () => showVerifiedPlusDialog(context, ref, profile)
                      : null,
                  onEditProfile: _handleEditProfile,
                  onRequestFriend: _handleRequestFriend,
                  onMessage: _handleMessage,
                  onShareProfile: _handleShareProfile,
                  onAddTagsTapped: () => _showTagsDialog(context),
                ),
              ),
              // Use the ProfileTabBarDelegate for a sticky tab bar
              SliverPersistentHeader(
                delegate: ProfileTabBarDelegate(
                  tabController: _tabController,
                  isSmallScreen: isSmallScreen,
                  profile: profile,
                ),
                pinned: true, // Keep the tabs visible when scrolling
              ),
            ];
          },
          // Use the optimized and accessible TabBarView
          body: accessibleTabBarView,
        ),
      ),
    );
  }

  void _initializeServices() {
    if (!mounted) return;

    try {
      // Initialize user profile data if needed
      if (!_isInitialized) {
        _isInitialized = true;

        Future(() async {
          if (!mounted) return;

          try {
            // Check if we already have profile data
            final profileState = ref.read(profileProvider);
            final hasProfileData = profileState.profile != null &&
                !profileState.isLoading &&
                !profileState.hasError;

            if (!hasProfileData) {
              // If no profile data, show loading and refresh
              debugPrint(
                  'Profile page: No profile data available, refreshing...');
              await ref.read(profileProvider.notifier).refreshProfile();
            } else {
              // If we have data, still refresh in the background
              debugPrint(
                  'Profile page: Data available, refreshing in background');
              ref.read(profileProvider.notifier).refreshProfile();
            }

            // If viewing another user's profile, initialize social status
            if (mounted && widget.userId != null) {
              ref
                  .read(socialProvider.notifier)
                  .initializeFollowingStatus(widget.userId!);
            }

            // Pre-load profile image to avoid jank
            _preloadProfileImage();
          } catch (e) {
            debugPrint('Error initializing profile: $e');
            if (mounted) {
              // Only show error if we don't have any profile data
              final profileState = ref.read(profileProvider);
              if (profileState.profile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Error loading profile. Please try again.'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        if (mounted) {
                          Future(() {
                            ref.read(profileProvider.notifier).refreshProfile();
                          });
                        }
                      },
                    ),
                  ),
                );
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error in _initializeServices: $e');
    }
  }

  // Preload profile image to avoid jank when showing the profile
  void _preloadProfileImage() {
    try {
      final profileState = ref.read(profileProvider);

      // Only try to preload if the profile is already loaded
      if (profileState.profile != null) {
        final profile = profileState.profile;
        if (profile != null &&
            profile.profileImageUrl != null &&
            profile.profileImageUrl!.isNotEmpty &&
            (profile.profileImageUrl!.startsWith('http://') ||
                profile.profileImageUrl!.startsWith('https://'))) {
          // Use a try-catch block to handle any image loading errors
          try {
            // Create image provider with error handling
            final imageProvider = NetworkImage(profile.profileImageUrl!);

            // Add an error listener to avoid crashes
            final stream = imageProvider.resolve(const ImageConfiguration());
            stream.addListener(
              ImageStreamListener(
                (info, _) {
                  // Image loaded successfully
                  debugPrint('Profile image preloaded successfully');
                },
                onError: (exception, stackTrace) {
                  // Safely handle errors
                  debugPrint('Error preloading profile image: $exception');
                },
              ),
            );
          } catch (e) {
            // Catch any synchronous exceptions during image preloading
            debugPrint('Exception during image provider creation: $e');
          }
        } else {
          debugPrint('Skipping profile image preload: URL empty or invalid');
        }
      }
    } catch (e) {
      // Silently ignore errors in preloading - this is just an optimization
      debugPrint('Error in preloadProfileImage: $e');
    }
  }

  // Edit profile action
  void _handleEditProfile(BuildContext context, UserProfile profile) {
    HapticFeedback.mediumImpact();

    // Hide bottom navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );

    // Go directly to the full profile editor
    showModernProfileEditor(
      context,
      profile,
      (updatedProfile) async {
        try {
          // Update the profile provider
          await _handleProfileUpdate(updatedProfile);
        } catch (error) {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to update profile',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            );
          }
        } finally {
          // Restore bottom navigation bar after editing is complete
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.edgeToEdge,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );
        }
      },
    );
  }

  Future<void> _handleProfileUpdate(UserProfile updatedProfile) async {
    // Store context in local variable
    final currentContext = context;

    try {
      // Log the profile update for debugging
      debugPrint('⏳ Updating profile with tags: ${updatedProfile.interests}');
      
      // Ensure we have the latest profile before updating
      if (updatedProfile.interests != null) {
        debugPrint('📋 Number of interests: ${updatedProfile.interests!.length}');
      }
      
      // Use the new providers to update profile
      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      
      // Refresh profile to verify the update took effect
      await ref.read(profileProvider.notifier).refreshProfile();
      
      debugPrint('✅ Profile updated successfully');

      if (!mounted) return;

      // Use stored context for feedback
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Log error details
      debugPrint('❌ Error updating profile: $e');
      
      if (!mounted) return;

      // Use stored context for error notification
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show tags dialog when "Add" is tapped on profile tags section
  void _showTagsDialog(BuildContext context) {
    final userProfileAsync = ref.read(profileProvider);

    // Early return if profile is loading or has error
    if (userProfileAsync.profile == null) return;

    // Extract actual profile from ProfileState
    final userProfile = userProfileAsync.profile!;

    // Create controllers and states for the dialog
    final selectedInterests = userProfile.interests?.toList() ?? [];
    final searchController = TextEditingController();
    final interestsProvider =
        StateProvider<List<String>>((ref) => InterestOptions.options);

    HapticFeedback.mediumImpact();

    // Helper widget for delayed animations
    Widget delayedAnimation({
      required Widget child,
      required int delayMillis,
      required bool translateY,
      double scaleFrom = 1.0,
    }) {
      return FutureBuilder(
        future: Future.delayed(Duration(milliseconds: delayMillis)),
        builder: (context, snapshot) {
          final showChild = snapshot.connectionState == ConnectionState.done;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: showChild ? 1.0 : 0.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..translate(0.0, translateY && !showChild ? 20.0 : 0.0)
                ..scale(showChild ? 1.0 : scaleFrom),
              child: child,
            ),
          );
        },
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  // Watch the filtered interests based on search
                  final filteredInterests = ref.watch(interestsProvider);

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with animation
                        delayedAnimation(
                          delayMillis: 0,
                          translateY: true,
                          child: Text(
                            'Select Interests',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle with animation
                        delayedAnimation(
                          delayMillis: 100,
                          translateY: true,
                          child: Text(
                            'Choose up to 10 interests that describe you',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Counter with animation
                        delayedAnimation(
                          delayMillis: 150,
                          translateY: false,
                          child: Row(
                            children: [
                              Text(
                                '${selectedInterests.length}/10',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: selectedInterests.length / 10,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      selectedInterests.length >= 5
                                          ? AppColors.gold
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search field with animation
                        delayedAnimation(
                          delayMillis: 200,
                          translateY: true,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: searchController,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              cursorColor: AppColors.gold,
                              decoration: InputDecoration(
                                hintText: 'Search interests...',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 15,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 20,
                                ),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.white.withOpacity(0.4),
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          searchController.clear();
                                          ref
                                              .read(interestsProvider.notifier)
                                              .state = InterestOptions.options;
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  ref.read(interestsProvider.notifier).state =
                                      InterestOptions.options;
                                } else {
                                  ref.read(interestsProvider.notifier).state =
                                      InterestOptions.options
                                          .where((interest) => interest
                                              .toLowerCase()
                                              .contains(value.toLowerCase()))
                                          .toList();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Interests grid with animation
                        delayedAnimation(
                          delayMillis: 250,
                          translateY: true,
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 12,
                                children: List.generate(
                                  filteredInterests.length,
                                  (index) {
                                    final interest = filteredInterests[index];
                                    return delayedAnimation(
                                      delayMillis: 300 + (index % 15) * 30,
                                      translateY: false,
                                      scaleFrom: 0.8,
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            if (selectedInterests
                                                .contains(interest)) {
                                              selectedInterests
                                                  .remove(interest);
                                            } else {
                                              if (selectedInterests.length <
                                                  10) {
                                                selectedInterests.add(interest);
                                              } else {
                                                HapticFeedback.heavyImpact();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Maximum 10 interests allowed',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        Colors.grey[800],
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    duration: const Duration(
                                                        seconds: 1),
                                                  ),
                                                );
                                              }
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selectedInterests
                                                    .contains(interest)
                                                ? AppColors.gold
                                                    .withOpacity(0.2)
                                                : Colors.grey[850],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: selectedInterests
                                                      .contains(interest)
                                                  ? AppColors.gold
                                                  : Colors.white
                                                      .withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                interest,
                                                style: GoogleFonts.inter(
                                                  color: selectedInterests
                                                          .contains(interest)
                                                      ? AppColors.gold
                                                      : Colors.white
                                                          .withOpacity(0.7),
                                                  fontSize: 14,
                                                  fontWeight: selectedInterests
                                                          .contains(interest)
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                              if (selectedInterests
                                                  .contains(interest)) ...[
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.gold,
                                                  size: 14,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Buttons row with animation
                        delayedAnimation(
                          delayMillis: 350,
                          translateY: true,
                          child: Row(
                            children: [
                              // Cancel button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Save button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    HapticFeedback.mediumImpact();

                                    try {
                                      // Show loading indicator
                                      showDialog(
                                        context: context, 
                                        barrierDismissible: false,
                                        builder: (context) => const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.gold,
                                          ),
                                        ),
                                      );
                                      
                                      // Create a clean, valid interests list
                                      final List<String> cleanInterests = selectedInterests
                                          .where((interest) => interest.isNotEmpty)
                                          .toList();
                                      
                                      // Get the current user ID from the profile
                                      final userId = userProfile.id;
                                      if (userId.isEmpty) {
                                        throw Exception('User ID is missing or invalid');
                                      }
                                      
                                      // Use the dedicated method for updating interests
                                      await ref.read(profileProvider.notifier).updateUserInterests(
                                        userId,
                                        cleanInterests,
                                      );
                                      
                                      // Force a refresh to ensure we see the changes
                                      await ref.read(profileProvider.notifier).refreshProfile();
                                      
                                      // Close the loading dialog
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      
                                      // Close the tags dialog after successful update
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        
                                        // Show success feedback
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Interests updated successfully',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.green[700],
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Close loading dialog if it's open
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      
                                      debugPrint('❌ Error saving tags: $e');
                                      if (context.mounted) {
                                        // Close the tags dialog
                                        Navigator.of(context).pop();
                                        
                                        // Show error message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update interests: $e',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red[700],
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Save',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
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
              ),
            );
          },
        );
      },
    );
  }

  void _handleRequestFriend(UserProfile profile) {
    HapticFeedback.mediumImpact();
    _sendFriendRequest(profile);
  }

  void _handleMessage(BuildContext context) {
    HapticFeedback.mediumImpact();
    final userProfile = ref.read(profileProvider).value;
    if (userProfile != null) {
      _navigateToChat(context, userProfile.id);
    }
  }

  void _handleShareProfile(BuildContext context, UserProfile profile) {
    HapticFeedback.mediumImpact();

    // Use the profile sharing service
    final sharingService = ref.read(profileSharingServiceProvider);

    // Show the peeking QR code UI
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) => ProfileShareModal(
        profile: profile,
        onShareLinkPressed: () {
          // Use the share service when share button is pressed
          sharingService.shareProfile(profile);
        },
        onCopyLinkPressed: () {
          // Use the copy to clipboard method
          sharingService.copyProfileLinkToClipboard(profile);
        },
      ),
    );
  }

  // Updated method to use the centralized navigation implementation
  void _navigateToChat(BuildContext context, String? targetUserId) {
    if (targetUserId != null) {
      context
          .push(AppRoutes.createChat, extra: {'initialUserId': targetUserId});
    } else {
      context.push(AppRoutes.messaging);
    }
  }

  void _navigateToSpaces(BuildContext context) {
    context.pushNamed('spaces');
  }

  Widget _buildProfileInteractionButtons(
      UserProfile profile, bool isCurrentUserProfile) {
    return ProfileInteractionButtons(
      profile: profile,
      isCurrentUser: isCurrentUserProfile,
      onEditProfile: (context, profile) {
        HapticFeedback.mediumImpact();
        context.push('/profile/edit');
      },
      onRequestFriend: (profile) {
        HapticFeedback.mediumImpact();
        _sendFriendRequest(profile);
      },
      onMessage: (context) {
        HapticFeedback.mediumImpact();
        context.push('/messaging/chat/${profile.id}');
      },
      onShareProfile: (context, profile) {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return ProfileShareModal(
              profile: profile,
            );
          },
        );
      },
    );
  }
  
  void _sendFriendRequest(UserProfile profile) {
    final friendRequestParams = profile.id;
    
    // Clear any existing call to avoid conflicts
    ref.refresh(sendFriendRequestProvider(friendRequestParams));
    
    // Send the friend request
    ref.read(sendFriendRequestProvider(friendRequestParams).future).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${profile.username}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send friend request'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// Navigate to the profile photo page
  void _navigateToPhotoPage(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push('/profile/photo');
  }

  /// Show settings options dialog
  void _showSettingsOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.settings);
  }
}

/// Delegate for the persistent settings header
class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final VoidCallback onSettingsTap;
  final bool isAdmin;
  final VoidCallback onAdminTap;

  _SettingsHeaderDelegate({
    required this.statusBarHeight,
    required this.onSettingsTap,
    required this.isAdmin,
    required this.onAdminTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: minExtent,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Settings icon
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onSettingsTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Admin icon
          if (isAdmin)
            Positioned(
              top: 8,
              right: 60,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(
                    Icons.verified_user,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  onPressed: onAdminTap,
                  tooltip: 'Admin Panel',
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60 + statusBarHeight / 2;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _SettingsHeaderDelegate oldDelegate) {
    return statusBarHeight != oldDelegate.statusBarHeight || 
           isAdmin != oldDelegate.isAdmin;
  }
}
