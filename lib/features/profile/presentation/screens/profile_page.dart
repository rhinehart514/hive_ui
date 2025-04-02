import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/profile/profile_header.dart';
import 'package:hive_ui/features/profile/presentation/screens/profile_tab_view.dart';

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

  @override
  Widget build(BuildContext context) {
    // For demo purposes, create a mock profile
    // In a real app, you would use a provider to fetch the profile
    final profile = UserProfile(
      id: widget.userId ?? 'current_user',
      username: 'hive_user',
      displayName: 'HIVE User',
      profileImageUrl: 'https://via.placeholder.com/150',
      bio: 'Welcome to my HIVE profile!',
      year: 'Junior',
      major: 'Computer Science',
      residence: 'North Campus',
      eventCount: 7,
      clubCount: 3,
      friendCount: 53,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final isCurrentUser = widget.userId == null;

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
                  profile: profile,
                  isCurrentUser: isCurrentUser,
                  onImageFromCamera: (_) {},
                  onImageFromGallery: (_) {},
                  onImageRemoved: () {},
                  onEditProfile: (_, __) {},
                  onRequestFriend: (_) {},
                  onMessage: (_) {},
                  onShareProfile: (_, __) {},
                ),
              ),
              elevation: 0,
              centerTitle: false,
              title: !_isHeaderExpanded
                ? Text(
                    profile.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // Show profile options
                    HapticFeedback.mediumImpact();
                  },
                ),
              ],
            ),
          ];
        },
        body: ProfileTabView(
          profile: profile,
          isCurrentUser: isCurrentUser,
        ),
      ),
      // Add a floating action button for current user to create content
      floatingActionButton: isCurrentUser
          ? FloatingActionButton(
              heroTag: 'profile_page_fab',
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Show create content options
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 