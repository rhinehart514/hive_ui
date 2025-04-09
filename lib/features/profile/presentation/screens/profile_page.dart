import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/auth.dart'; // Import the barrel file
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/profile/presentation/screens/verified_plus_request_page.dart';
import 'package:hive_ui/features/profile/presentation/screens/profile_tab_view.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/components/moderation/report_dialog.dart';
import 'package:hive_ui/components/moderation/restrict_user_dialog.dart';
import 'package:hive_ui/widgets/profile/profile_header.dart';
import 'package:hive_ui/features/profile/presentation/pages/verification_request_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/core/providers/role_checker_provider.dart';

/// A complete profile page with header and tabbed content
class ProfilePage extends ConsumerStatefulWidget {
  /// The userId to display, if null will show current user
  final String? userId;
  
  /// Constructor
  const ProfilePage({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  /// Whether the header is expanded
  bool _isHeaderExpanded = true;

  /// Scroll controller for the page
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    
    // Load the user profile when the page initializes with retry logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileWithRetry();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events to collapse/expand header
  void _handleScroll() {
    if (_scrollController.offset > 80 && _isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = false;
      });
    } else if (_scrollController.offset <= 80 && !_isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = true;
      });
    }
  }

  /// Load profile with retry logic
  void _loadProfileWithRetry({int retryCount = 0}) {
    debugPrint('ProfilePage: Loading profile, attempt ${retryCount + 1}');
    
    if (widget.userId != null) {
      // Load another user's profile
      ref.read(profileProvider.notifier).loadProfile(widget.userId!).then((_) {
        _checkProfileLoadedSuccessfully(retryCount);
      }).catchError((error) {
        debugPrint('ProfilePage: Error loading profile: $error');
        _retryLoadingIfNeeded(retryCount);
      });
    } else {
      // Try to check if we already have profile data cached in UserPreferencesService first
      UserPreferencesService.getStoredProfile().then((cachedProfile) {
        if (cachedProfile != null) {
          debugPrint('ProfilePage: Found cached profile, using it while refreshing');
          // We have a cached profile, use it to update the provider state immediately
          ref.read(profileProvider.notifier).updateCachedProfile(cachedProfile);
        }
        
        // Always refresh to get the latest data
        return ref.read(profileProvider.notifier).refreshProfile();
      }).then((_) {
        _checkProfileLoadedSuccessfully(retryCount);
      }).catchError((error) {
        debugPrint('ProfilePage: Error refreshing profile: $error');
        _retryLoadingIfNeeded(retryCount);
      });
    }
  }

  /// Check if profile loaded successfully and retry if needed
  void _checkProfileLoadedSuccessfully(int retryCount) {
    final profileState = ref.read(profileProvider);
    
    // If profile is still null or error occurred, retry
    if (profileState.profile == null) {
      debugPrint('ProfilePage: Profile not loaded successfully');
      _retryLoadingIfNeeded(retryCount);
    } else {
      debugPrint('ProfilePage: Profile loaded successfully: ${profileState.profile!.displayName}');
    }
  }

  /// Retry loading if needed and not exceeded max retries
  void _retryLoadingIfNeeded(int retryCount) {
    const maxRetries = 2;
    if (retryCount < maxRetries) {
      debugPrint('ProfilePage: Retrying profile load (${retryCount + 1}/$maxRetries)');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _loadProfileWithRetry(retryCount: retryCount + 1);
        }
      });
    } else {
      debugPrint('ProfilePage: Max retries exceeded, showing error state');
    }
  }

  /// Format display name
  String _formatDisplayName(String displayName, String username) {
    // Check if the displayName looks like a Firebase UID
    if (displayName.startsWith('user_') || 
        (displayName.length > 20 && displayName.contains(RegExp(r'[A-Za-z0-9]{20,}')))) {
      // Use username if available, otherwise a generic name
      return username.isNotEmpty ? username.split('_').first : 'HIVE User';
    }
    return displayName;
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.userId == null;
    // Watch the profile being viewed
    final viewedProfileState = ref.watch(profileProvider);
    // Watch the current user's profile specifically for role checks
    final currentUserProfileState = ref.watch(currentUserProfileProvider);
    
    // Fix AccountTier nullability issue in comparison with pattern matching 
    final bool isAdmin = currentUserProfileState.maybeWhen(
      data: (profile) {
        if (profile == null) return false;
        return profile.accountTier == AccountTier.verifiedPlus;
      },
      orElse: () => false,
    );

    // Add debug prints to check profile state
    debugPrint('Profile state: isLoading=${viewedProfileState.isLoading}, hasError=${viewedProfileState.error != null}');
    debugPrint('Profile data: hasProfile=${viewedProfileState.profile != null}');
    if (viewedProfileState.profile != null) {
      debugPrint('Saved events count: ${viewedProfileState.profile!.savedEvents.length}');
      debugPrint('Event count: ${viewedProfileState.profile!.eventCount}');
      // Print first few event IDs if available
      if (viewedProfileState.profile!.savedEvents.isNotEmpty) {
        final eventIds = viewedProfileState.profile!.savedEvents.take(3).map((e) => e.id).join(', ');
        debugPrint('First few event IDs: $eventIds');
      }
    }
    
    // Show loading state while profile is loading
    if (viewedProfileState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      );
    }
    
    // Get the profile being viewed from state or use default
    final viewedProfile = viewedProfileState.profile ?? UserProfile(
      id: widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'current_user',
      username: FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'hive_user',
      displayName: FirebaseAuth.instance.currentUser?.displayName ?? 'HIVE User',
      profileImageUrl: null, // Use null to show default avatar
      bio: 'Welcome to HIVE!',
      year: 'Student',
      major: 'Undeclared',
      residence: 'Campus',
      eventCount: 0,
      spaceCount: 0,
      friendCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      interests: const ['Music', 'Sports', 'Technology'],
      savedEvents: const [],
    );

    return Scaffold(
      backgroundColor: AppColors.black,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.black,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: ProfileHeader(
                  profile: viewedProfile,
                  isCurrentUser: isCurrentUser,
                  onImageFromCamera: (_) {},
                  onImageFromGallery: (_) {},
                  onImageRemoved: () {},
                  onEditProfile: (_, __) {},
                  onRequestFriend: (_) {},
                  onMessage: (_) {},
                  onShareProfile: (_, __) {},
                  firstName: viewedProfile.firstName,
                  lastName: viewedProfile.lastName,
                ),
              ),
              elevation: 0,
              centerTitle: false,
              title: !_isHeaderExpanded
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDisplayName(viewedProfile.displayName, viewedProfile.username),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Show verification badge next to the name
                      if (!isCurrentUser)
                        _buildVerificationBadge(viewedProfile)
                      else
                        _buildCurrentUserVerificationBadge(),
                    ],
                  )
                : null,
              actions: [
                _buildProfileActionsButton(viewedProfile, isAdmin, isCurrentUser),
              ],
            ),
          ];
        },
        body: ProfileTabView(
          profile: viewedProfile,
          isCurrentUser: isCurrentUser,
        ),
      ),
      // Add a floating action button for current user to create content
      floatingActionButton: isCurrentUser
          ? Consumer(
              builder: (context, ref, child) {
                return PermissionGate(
                  requiredRole: UserRole.verified, // Require at least verified status to create content
                  fallbackWidget: FloatingActionButton(
                    heroTag: 'profile_page_verify_fab',
                    backgroundColor: Colors.black45, // Use Colors.black45 instead of AppColors.darkGrey
                    foregroundColor: AppColors.gold,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VerificationRequestPage()),
                      );
                    },
                    child: const Icon(Icons.verified_outlined),
                  ),
                  showPlaceholder: true,
                  placeholderBuilder: null,
                  allowPlaceholderInteraction: true,
                  onPlaceholderTap: null,
                  child: FloatingActionButton(
                    heroTag: 'profile_page_fab',
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // Show create content options
                    },
                    child: const Icon(Icons.add),
                  ),
                );
              },
            )
          : null,
    );
  }

  /// Builds the action button (PopupMenuButton) for the profile page AppBar
  Widget _buildProfileActionsButton(UserProfile profile, bool isAdmin, bool isCurrentUser) {
    return Builder(
      builder: (context) {
        if (isCurrentUser) {
          // Current user - show settings and upgrade options
          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.black87,
            onSelected: (option) => _handleProfileOption(context, option, profile),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit Profile', style: TextStyle(color: Colors.white)),
              ),
              // Only show Verification options with appropriate gates
              if (profile.accountTier != AccountTier.verified && profile.accountTier != AccountTier.verifiedPlus)
                const PopupMenuItem<String>(
                  value: 'verify',
                  child: Text('Request Verification', style: TextStyle(color: Colors.white)),
                ),
              // Wrap verified+ upgrade in PermissionGate
              if (profile.accountTier == AccountTier.verified)
                const PopupMenuItem<String>(
                  value: 'verifyPlus',
                  child: Text('Upgrade to Verified+', style: TextStyle(color: AppColors.gold)),
                ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem<String>(
                value: 'signOut',
                child: Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        } else {
          // Other user - show report, block, etc.
          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.black87,
            onSelected: (option) => _handleProfileOption(context, option, profile),
            itemBuilder: (BuildContext context) {
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Report User', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Text('Block User', style: TextStyle(color: Colors.redAccent)),
                ),
              ];
              
              // Add moderation option if user has permission (wrap in Consumer outside the list)
              return items;
            },
          );
        }
      },
    );
  }

  /// Show dialog to report a user profile
  void _showReportDialog(UserProfile profile) {
    showReportDialog(
      context,
      contentId: profile.id,
      contentType: ReportedContentType.profile,
      contentPreview: 'User profile: ${profile.displayName} (@${profile.username})',
      ownerId: profile.id, // The user being reported is the owner of the profile content
    );
    // Success/failure is handled within showReportDialog
  }
  
  /// Show dialog to restrict a user
  void _showRestrictDialog(UserProfile profile) {
    showDialog<bool>(
      context: context,
      builder: (context) => RestrictUserDialog(targetUser: profile),
    ).then((success) {
      if (success == true) {
        // Optional: Refresh profile data or show confirmation
      }
    });
  }

  // Fix the unnecessary null comparison
  Widget _buildVerificationBadge(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: RoleBadge(
        role: _getEquivalentUserRole(profile.accountTier),
        size: RoleBadgeSize.small,
      ),
    );
  }
  
  // Fix the constant value issue by making it non-const
  Widget _buildCurrentUserVerificationBadge() {
    return Consumer(
      builder: (context, ref, _) {
        final userRoleAsync = ref.watch(currentUserRoleProvider);
        
        return userRoleAsync.when(
          data: (role) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: RoleBadge(
              role: role,
              size: RoleBadgeSize.small,
            ),
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  // Helper to map AccountTier to VerificationLevel
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

  // Helper to map AccountTier to UserRole
  UserRole _getEquivalentUserRole(AccountTier tier) {
    switch (tier) {
      case AccountTier.verified:
        return UserRole.verified;
      case AccountTier.verifiedPlus:
        return UserRole.verifiedPlus;
      default:
        return UserRole.public;
    }
  }

  // Add _handleProfileOption method that was missing
  void _handleProfileOption(BuildContext context, String option, UserProfile profile) {
    switch (option) {
      case 'edit':
        // Handle edit profile
        break;
      case 'verify':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const VerificationRequestPage(),
          ),
        );
        break;
      case 'verifyPlus':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const VerifiedPlusRequestPage(),
          ),
        );
        break;
      case 'settings':
        // Navigate to settings
        break;
      case 'signOut':
        FirebaseAuth.instance.signOut();
        break;
      case 'report':
        _showReportDialog(profile);
        break;
      case 'moderate':
        _showRestrictDialog(profile);
        break;
      case 'block':
        // Handle block user
        break;
    }
  }
} 