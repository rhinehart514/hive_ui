import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/widgets/profile/profile_header.dart';
import 'package:hive_ui/widgets/profile/profile_tab_content.dart' as content;
import 'package:hive_ui/widgets/profile/profile_skeleton_loader.dart';
import 'package:hive_ui/widgets/profile/profile_image_viewer.dart';
import 'package:hive_ui/widgets/profile/verified_plus_dialog.dart';
import 'package:hive_ui/widgets/profile/profile_tab_bar.dart';
import 'package:hive_ui/widgets/profile/profile_share_modal.dart';
import 'package:hive_ui/constants/interest_options.dart';
import 'package:hive_ui/providers/admin_provider.dart';
import 'package:hive_ui/providers/friend_providers.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/profile/activity_feed.dart';
import 'package:hive_ui/widgets/profile/enhanced_profile_editor.dart';
import 'package:hive_ui/widgets/friends/friend_request_button.dart';

// New architecture providers
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart' as profile_providers;
import 'package:hive_ui/features/profile/presentation/providers/profile_media_provider.dart';

// Keep services
import 'package:hive_ui/services/profile_sharing_service.dart';

// Theme and Styling
import 'package:hive_ui/theme/huge_icons.dart';

// Add this import to fix the ProfileTrailTab reference
import 'package:hive_ui/features/profile/presentation/widgets/trail_visualization.dart';

// Add this import to fix the ActivityFeedTab reference

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
  late ScrollController _scrollController;
  bool _isHeaderExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize timezone database
    tz.initializeTimeZones();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isHeaderExpanded = _scrollController.hasClients &&
              _scrollController.offset <= (240 - kToolbarHeight);
        });
      });
    _tabController = TabController(length: 5, vsync: this);

    // Set initial tab index to 0 (Trail) to showcase the new feature
    _tabController.index = 0;
    
    // Schedule profile sync after showing the page
    // We do this after a short delay to avoid UI jank
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(profile_providers.profileSyncProvider.notifier).scheduleSyncProfile();
      }
    });
    
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
          ref.read(profile_providers.profileProvider.notifier).loadProfile(widget.userId!);
        } else {
          // For current user profile, refresh to ensure data is up-to-date
          ref.read(profile_providers.profileProvider.notifier).refreshProfile();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminStatus = ref.watch(adminStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      // Add a FloatingActionButton for the sync menu (only for current user)
      floatingActionButton: widget.userId == null ? 
        FloatingActionButton(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          tooltip: 'Profile Options',
          onPressed: () {
            final profileState = ref.read(profile_providers.profileProvider);
            if (profileState.profile != null) {
              _showProfileOptions(context, profileState.profile!);
            }
          },
          child: const Icon(Icons.sync),
        ) : null,
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
          final profileState = ref.watch(profile_providers.profileProvider);

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
                ref.read(profile_providers.profileProvider.notifier).refreshProfile();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: ProfileHeader(
                profile: profile,
                isCurrentUser: widget.userId == null,
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
                onVerifiedPlusTap: widget.userId == null
                    ? () => showVerifiedPlusDialog(context, ref, profile)
                    : null,
                onEditProfile: _handleEditProfile,
                onRequestFriend: _handleRequestFriend,
                onMessage: _handleMessage,
                onShareProfile: _handleShareProfile,
                onAddTagsTapped: () => _showTagsDialog(context),
                firstName: profile.firstName,
                lastName: profile.lastName,
              ),
            ),
            SliverPersistentHeader(
              delegate: ProfileTabBarDelegate(
                tabController: _tabController,
                isSmallScreen: MediaQuery.of(context).size.width < 360,
                profile: profile,
              ),
              pinned: true,
              floating: false,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Trail Tab (new)
            TrailVisualization(
              userId: widget.userId,
              showHeader: false,
            ),
            
            // Existing tabs
            ActivityFeedTab(
              profile: profile,
              userId: widget.userId,
            ),
            content.ProfileTabContent(
              tabType: content.ProfileTabType.spaces,
              profile: profile,
              isCurrentUser: widget.userId == null,
            ),
            content.ProfileTabContent(
              tabType: content.ProfileTabType.events,
              profile: profile,
              isCurrentUser: widget.userId == null,
            ),
            content.ProfileTabContent(
              tabType: content.ProfileTabType.friends,
              profile: profile,
              isCurrentUser: widget.userId == null,
            ),
          ],
        ),
      ),
    );
  }

  void _initializeServices() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Initialize any required services here
    });
  }

  // Preload profile image to avoid jank when showing the profile
  void _preloadProfileImage() {
    try {
      final profileState = ref.read(profile_providers.profileProvider);

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

    // Store context references before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Use the enhanced profile editor instead of the modern editor
    showEnhancedProfileEditor(
      context,
      profile,
      (updatedProfile) async {
        try {
          // Update the profile provider
          await _handleProfileUpdate();
        } catch (error) {
          // Show error message
          if (mounted) {
            scaffoldMessenger.showSnackBar(
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

  Future<void> _handleProfileUpdate() async {
    // Store necessary context references before async operation
    final navigatorState = Navigator.of(context);
    final scaffoldState = ScaffoldMessenger.of(context);
    
    try {
      await ref.read(profile_providers.profileProvider.notifier).refreshProfile();
      
      // Check if still mounted before using context or stored references
      if (!mounted) return;
      scaffoldState.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      navigatorState.pop();
    } catch (e) {
      if (!mounted) return;
      scaffoldState.showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  // Show tags dialog when "Add" is tapped on profile tags section
  void _showTagsDialog(BuildContext context) {
    final userProfileAsync = ref.read(profile_providers.profileProvider);

    // Early return if profile is loading or has error
    if (userProfileAsync.profile == null) return;

    // Extract actual profile from ProfileState
    final userProfile = userProfileAsync.profile!;

    // Create controllers and states for the dialog
    final selectedInterests = userProfile.interests.toList() ?? [];
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
                                      
                                      // Use the dedicated method for updating interests
                                      await _handleInterestUpdate(cleanInterests);
                                      
                                      // Force a refresh to ensure we see the changes
                                      await ref.read(profile_providers.profileProvider.notifier).refreshProfile();
                                      
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

  Future<void> _handleInterestUpdate(List<String> interests) async {
    try {
      final success = await ref.read(profile_providers.profileProvider.notifier).updateUserInterests(interests);
      
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interests updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update interests'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating interests: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleRequestFriend(UserProfile profile) {
    HapticFeedback.mediumImpact();
    _sendFriendRequest(profile);
  }

  void _handleMessage(BuildContext context) {
    HapticFeedback.mediumImpact();
    final userProfile = ref.read(profile_providers.profileProvider).value;
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
      context.push(AppRoutes.createChat, extra: {'initialUserId': targetUserId});
    } else {
      context.push(AppRoutes.messaging);
    }
  }

  void _navigateToSpaces(BuildContext context) {
    context.pushNamed('spaces');
  }

  void _sendFriendRequest(UserProfile profile) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final friendRequestParams = profile.id;
    
    // Clear any existing call to avoid conflicts
    ref.refresh(sendFriendRequestProvider(friendRequestParams));
    
    try {
      // Send the friend request
      final success = await ref.read(sendFriendRequestProvider(friendRequestParams).future);
      
      if (!mounted) return;
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${profile.username}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to send friend request'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error sending friend request: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _handleAsyncOperation(BuildContext context, Future<void> Function() operation) async {
    // Store scaffoldMessenger before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await operation();
    } catch (e) {
      // Check mounted before using stored reference
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onInterestSelected(String interest) async {
    final currentProfile = ref.read(profile_providers.profileProvider).profile;
    if (currentProfile == null) return;

    // Fix dead null-aware expression - remove unnecessary null check
    final currentInterests = List<String>.from(currentProfile.interests);
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
    } else {
      currentInterests.add(interest);
    }

    await ref.read(profile_providers.profileProvider.notifier).updateUserInterests(currentInterests);
  }

  void _showProfileOptions(BuildContext context, UserProfile profile) {
    // Show a bottom sheet with different profile actions
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sync, color: AppColors.gold),
                title: const Text(
                  'Sync Profile', 
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Update joined spaces and RSVPs',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  // Store context references before closing bottom sheet
                  final scaffoldState = ScaffoldMessenger.of(context);
                  Navigator.pop(context); // Close the bottom sheet
                  
                  // Show loading indicator
                  scaffoldState.showSnackBar(
                    const SnackBar(
                      content: Text('Syncing profile data...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  // Use sync provider to update profile data
                  try {
                    await ref.read(profile_providers.profileSyncProvider.notifier).syncProfile();
                    
                    if (mounted) {
                      scaffoldState.showSnackBar(
                        const SnackBar(
                          content: Text('Profile synced successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldState.showSnackBar(
                        SnackBar(
                          content: Text('Error syncing profile: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.gold),
                title: const Text(
                  'Share Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleShareProfile(context, profile);
                },
              ),
              if (widget.userId == null) // Only show for current user
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.gold),
                  title: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleEditProfile(context, profile);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileActions(UserProfile profile) {
    final isCurrentUser = profile.id == FirebaseAuth.instance.currentUser?.uid;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCurrentUser)
            // Edit profile button for current user
            OutlinedButton.icon(
              onPressed: () => _handleEditProfile(context, profile),
              icon: const Icon(Icons.edit, color: AppColors.yellow),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.yellow,
                side: const BorderSide(color: AppColors.yellow, width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) {
                    if (states.contains(MaterialState.pressed)) {
                      return AppColors.yellow.withOpacity(0.15);
                    }
                    return null;
                  },
                ),
              ),
            )
          else
            // Friend request button for other users
            FriendRequestButton(
              userId: profile.id,
              onConnectionStateChanged: (state) {
                // Optionally refresh the profile or update UI
              },
            ),
        ],
      ),
    );
  }

  /// Refresh profile on pull to refresh
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    debugPrint('Refreshing profile...');
    try {
      await ref.read(profile_providers.profileProvider.notifier).refreshProfile();
      // Sync profile after refresh
      await ref.read(profile_providers.profileSyncProvider.notifier).syncProfile();
      debugPrint('Profile refreshed successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
