import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';  // For ImageFilter

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';  // For GlassmorphismGuide

// Models
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/event.dart';

// State Providers
import 'package:hive_ui/providers/club_providers.dart';

// Components

// Services
import 'package:hive_ui/services/event_service.dart';
import 'package:hive_ui/services/analytics_service.dart';

// Icons

/// Provider to track whether the club is being managed by the current user
final isCurrentUserManagerProvider = StateProvider<bool>((ref) => false);

// Define icon size constant for huge icons
const double _hugeIconSize = 32.0;

// Providers for club space functionality
/// Provider for accessing all events
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  return await EventService.getEvents();
});

/// Provider for user's followed clubs
final userFollowedClubsProvider = StateProvider<List<String>>((ref) => []);

class ClubSpacePage extends ConsumerStatefulWidget {
  final String? clubId;
  final Club? club;
  final Space? space;
  final String? spaceType;

  const ClubSpacePage({
    super.key,
    this.clubId,
    this.club,
    this.space,
    this.spaceType,
  }) : assert(clubId != null || club != null || space != null,
            'Must provide at least one of clubId, club, or space');

  @override
  ConsumerState<ClubSpacePage> createState() => _ClubSpacePageState();
}

// Data class for about carousel cards
class AboutCardData {
  final String title;
  final IconData icon;
  final String content;
  final String? secondaryInfo;
  final Widget? customWidget;
  final bool isEditable;

  AboutCardData({
    required this.title,
    required this.icon,
    required this.content,
    this.secondaryInfo,
    this.customWidget,
    this.isEditable = false,
  });
}

class _ClubSpacePageState extends ConsumerState<ClubSpacePage>
    with SingleTickerProviderStateMixin {
  // Standard spacing values for consistent UI
  static const double kSpacingXs = 4.0;
  static const double kSpacingSm = 8.0;
  static const double kSpacingMd = 16.0;
  static const double kSpacingLg = 24.0;
  static const double kSpacingXl = 32.0;
  
  // Standard padding values 
  static const EdgeInsets kPaddingXs = EdgeInsets.all(4.0);
  static const EdgeInsets kPaddingSm = EdgeInsets.all(8.0);
  static const EdgeInsets kPaddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets kPaddingLg = EdgeInsets.all(24.0);
  
  // Standard horizontal paddings
  static const EdgeInsets kPaddingHorizMd = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets kPaddingHorizLg = EdgeInsets.symmetric(horizontal: 24.0);
  
  // Standard vertical paddings
  static const EdgeInsets kPaddingVertSm = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets kPaddingVertMd = EdgeInsets.symmetric(vertical: 16.0);
  
  Club? _club;
  bool _loading = true;
  bool _isClubManager = false;
  bool _isFollowing = false;

  // Animation controller for smooth transitions
  late AnimationController _animationController;

  // UI state
  int _followerCount = 0;
  final int _mediaCount = 0;
  int _eventCount = 0;
  final bool _hasAttendedEvent = false;
  bool _chatUnlocked = false;

  // Custom about text (added to store editable about content)
  String? _customAboutText;

  // Events data
  List<Event> _events = [];

  // Dynamic message data
  String? _pinnedMessage;

  // Chat data
  final List<Map<String, dynamic>> _recentChatMessages = [];

  // Social links
  Map<String, String> _socialLinks = {};

  // Scroll controller for the SliverAppBar
  late ScrollController _scrollController;

  // Add a page controller for message board swipe functionality
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with faster duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Reduced from 400ms
      vsync: this,
    );

    // Initialize club data and events
    _initializeData();
    
    // Log analytics for space view
    AnalyticsService.logEvent(
      'view_space_details',
      parameters: {
        'space_id': widget.clubId ?? widget.club?.id ?? widget.space?.id ?? 'unknown',
        'space_name': widget.club?.name ?? widget.space?.name ?? 'unknown',
        'space_type': widget.spaceType ?? widget.space?.spaceType.toString() ?? 'unknown',
      },
    );

    // Initialize scroll controller
    _scrollController = ScrollController();

    // Initialize the page controller for swiping
    _pageController = PageController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _pageController.dispose(); // Dispose the page controller
    super.dispose();
  }

  // Fetch real events for this club
  Future<void> _fetchEvents() async {
    if (_club == null) return;

    try {
      // Use Firestore to directly fetch events associated with this club
      final eventsRef = FirebaseFirestore.instance.collection('events');
      List<Event> fetchedEvents = [];

      // Try multiple approaches in case some queries fail due to missing indexes
      try {
        // Approach 1: Find events where spaceId matches club.id (preferred)
        final spaceEventsSnapshot =
            await eventsRef.where('spaceId', isEqualTo: _club!.id).get();

        if (spaceEventsSnapshot.docs.isNotEmpty) {
          fetchedEvents = spaceEventsSnapshot.docs
              .map((doc) => Event.fromJson(doc.data()))
              .toList();
        }
      } catch (e) {
        debugPrint('Error with spaceId query: $e');
        // Continue to next approach
      }

      // If no events found by spaceId, try organizerId
      if (fetchedEvents.isEmpty) {
        try {
          final organizerEventsSnapshot =
              await eventsRef.where('organizerId', isEqualTo: _club!.id).get();

          if (organizerEventsSnapshot.docs.isNotEmpty) {
            fetchedEvents = organizerEventsSnapshot.docs
                .map(
                    (doc) => Event.fromJson(doc.data()))
                .toList();
          }
        } catch (e) {
          debugPrint('Error with organizerId query: $e');
          // Continue to next approach
        }
      }

      // If still no events, try matching by club name in organizer name field
      if (fetchedEvents.isEmpty) {
        try {
          final nameEventsSnapshot = await eventsRef
              .where('organizerName', isEqualTo: _club!.name)
              .get();

          if (nameEventsSnapshot.docs.isNotEmpty) {
            fetchedEvents = nameEventsSnapshot.docs
                .map(
                    (doc) => Event.fromJson(doc.data()))
                .toList();
          }
        } catch (e) {
          debugPrint('Error with organizerName query: $e');
          // Continue to next approach
        }
      }

      // Last resort: query all events and filter in memory
      if (fetchedEvents.isEmpty) {
        try {
          // Get a limited set of all events (most recent ones)
          final allEventsSnapshot = await eventsRef
              .orderBy('startDate', descending: true)
              .limit(100)
              .get();

          if (allEventsSnapshot.docs.isNotEmpty) {
            // Filter in memory by matching club name or ID
            final allEvents = allEventsSnapshot.docs
                .map(
                    (doc) => Event.fromJson(doc.data()))
                .toList();

            fetchedEvents = allEvents.where((event) {
              // Match by organizer name (case insensitive)
              if (event.organizerName.toLowerCase() ==
                  _club!.name.toLowerCase()) {
                return true;
              }

              // Match by tag containing club name or ID
              final hasTags = event.tags.any((tag) =>
                  tag.toLowerCase().contains(_club!.id.toLowerCase()) ||
                  tag.toLowerCase().contains(_club!.name.toLowerCase()));

              return hasTags;
            }).toList();
          }
        } catch (e) {
          debugPrint('Error with fallback query: $e');
        }
      }

      // Sort events by date (soonest first)
      fetchedEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      // Update events list and count
      if (mounted) {
        setState(() {
          _events = fetchedEvents;
          _eventCount = _events.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching events for club: $e');
      // Initialize with empty list if there's an error
      if (mounted) {
        setState(() {
          _events = [];
        });
      }
    }
  }

  // Fetch club social links
  void _initializeSocialLinks() {
    if (_club == null) return;

    final Map<String, String> links = {};

    // Add website if available
    if (_club!.website != null && _club!.website!.isNotEmpty) {
      links['website'] = _club!.website!;
    }

    // Add email if available
    if (_club!.email != null && _club!.email!.isNotEmpty) {
      links['email'] = _club!.email!;
    }

    // Get social links from club data
    if (_club!.socialLinks.isNotEmpty) {
      for (final link in _club!.socialLinks) {
        if (link.contains('instagram')) {
          links['instagram'] = link;
        } else if (link.contains('discord')) {
          links['discord'] = link;
        } else if (link.contains('facebook')) {
          links['facebook'] = link;
        } else if (link.contains('twitter') || link.contains('x.com')) {
          links['twitter'] = link;
        } else if (link.contains('linkedin')) {
          links['linkedin'] = link;
        }
      }
    }

    // If we have no links, provide some defaults based on name
    if (links.isEmpty) {
      final slug =
          _club!.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      links['website'] =
          'https://www.buffalo.edu/studentlife/clubs/$slug.html';
    }

    if (mounted) {
      setState(() {
        _socialLinks = links;
      });
    }
  }

  // Check if current user is a manager of this club
  Future<void> _checkUserPermissions() async {
    // This would normally use a provider or service to check user permissions
    // For now, we'll set manager status based on provider state
    try {
      final isManager = ref.read(isCurrentUserManagerProvider);

      if (mounted) {
        setState(() {
          _isClubManager = isManager;
        });
      }
    } catch (e) {
      debugPrint('Error checking user permissions: $e');
      // Default to false for safety
      if (mounted) {
        setState(() {
          _isClubManager = false;
        });
      }
    }
  }

  // Check if user is following this club
  Future<void> _checkFollowStatus() async {
    if (_club == null) return;

    try {
      // Get followed clubs IDs
      final followedClubs = ref.read(userFollowedClubsProvider);

      if (mounted) {
        setState(() {
          _isFollowing = followedClubs.contains(_club!.id);

          // Update follower count based on club data
          _followerCount = _club!.followersCount;
          if (_followerCount <= 0) {
            // Use memberCount as fallback
            _followerCount = _club!.memberCount;
          }

          // Ensure we have at least a count of 1 if member count is 0
          if (_followerCount <= 0) {
            _followerCount = 1; // Default minimum to show "<10"
          }

          // Determine if chat is unlocked (requires at least 10 followers)
          _chatUnlocked = _followerCount >= 10;
        });
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  // Get the pinned message for this club
  void _getPinnedMessage() {
    if (_club == null) return;

    // In a real app, this would come from a database
    // For now, we'll generate a contextual message based on club data
    String message = '';

    if (_club!.resources.isNotEmpty) {
      // Use a resource as a pinned message
      final resourceEntry = _club!.resources.entries.first;
      message = '${resourceEntry.key} available at ${resourceEntry.value}';
    } else if (_events.isNotEmpty) {
      // Use the next event as a pinned message
      final nextEvent = _events.first;
      final formatter = DateFormat('MMM d');
      message =
          'Join us for ${nextEvent.title} on ${formatter.format(nextEvent.startDate)}!';
    } else if (_club!.requirements.isNotEmpty) {
      // Use membership requirements
      message = 'Membership requirements: ${_club!.requirements.first}';
    } else if (_club!.meetingTimes.isNotEmpty) {
      // Use meeting times
      message = 'We meet at: ${_club!.meetingTimes.first}';
    } else {
      // Default message
      message = 'Welcome to ${_club!.name}! Check out our upcoming events.';
    }

    if (mounted) {
      setState(() {
        _pinnedMessage = message;
      });
    }
  }

  void _initializeData() {
    // Determine if we already have a club or space
    if (widget.club != null) {
      // Use the club directly
      setState(() {
        _loading = false;
        _club = widget.club;

        // Initialize UI state based on club data
        _followerCount = widget.club!.memberCount;
        _chatUnlocked = _followerCount >= 10;
      });

      // Complete initialization with additional data
      _completeInitialization();
    } else if (widget.space != null) {
      // Convert space to club format
      setState(() {
        _loading = false;

        // Create club from space data
        _club = Club(
          id: widget.space!.id,
          name: widget.space!.name,
          description: widget.space!.description,
          category: widget.space!.tags.isNotEmpty
              ? widget.space!.tags.first
              : 'General',
          memberCount: widget.space!.metrics.memberCount ?? 0,
          status: widget.space!.isPrivate ? 'private' : 'active',
          icon: widget.space!.icon,
          imageUrl: widget.space!.imageUrl,
          createdAt: widget.space!.createdAt,
          updatedAt: widget.space!.updatedAt,
          tags: widget.space!.tags,
        );

        // Initialize UI state based on space data
        _followerCount = widget.space!.metrics.memberCount ?? 0;
        _eventCount = widget.space!.metrics.weeklyEvents;
        _chatUnlocked = _followerCount >= 10;
      });

      // Complete initialization with additional data
      _completeInitialization();
    } else if (widget.clubId != null) {
      // Fetch club data using clubId from provider
      // Use the spaceType parameter if provided, otherwise use a default
      final spaceType = widget.spaceType ?? 'spaces';

      // Log the spaceType passed to the page
      debugPrint(
          'Fetching club with ID: ${widget.clubId} and type: $spaceType');

      // Check if the spaceType starts with "spacetype." and handle that format
      String displayType = spaceType;
      if (spaceType.toLowerCase().startsWith('spacetype.')) {
        // Use the plain name for logging
        displayType = spaceType.substring('spacetype.'.length);

        // Map to the correct type for path
        if (displayType.toLowerCase() == 'fraternityandsorority') {
          displayType = 'fraternity_and_sorority';
        } else if (displayType.toLowerCase() == 'universityorg') {
          displayType = 'university_organizations';
        }
      } else if (spaceType.startsWith('SpaceType.')) {
        // Handle capitalized SpaceType format
        displayType = spaceType.substring('SpaceType.'.length);

        // Map to the correct type for path
        if (displayType == 'fraternityAndSorority') {
          displayType = 'fraternity_and_sorority';
        } else if (displayType == 'universityOrg') {
          displayType = 'university_organizations';
        }
      }

      // Custom path construction for the club reference
      // This builds a path that matches the Firestore structure allowed by your security rules
      final String clubPath = 'spaces/$displayType/spaces/${widget.clubId}';

      debugPrint('Attempting to fetch club data from: $clubPath');

      ref.read(clubByIdProvider(widget.clubId!).future).then((club) {
        if (mounted) {
          setState(() {
            _loading = false;
            if (club != null) {
              _club = club;
              _followerCount = club.memberCount;
              _chatUnlocked = _followerCount >= 10;
            } else {
              // Fallback if club is null - use clubId to format a better name
              // Parse the clubId into a better name (assuming format like 'space_name_with_underscores')
              String displayName = "Unknown Club";
              if (widget.clubId!.contains('space_')) {
                displayName = widget.clubId!
                    .replaceFirst('space_', '')
                    .split('_')
                    .map((word) => word.isNotEmpty
                        ? '${word[0].toUpperCase()}${word.substring(1)}'
                        : '')
                    .join(' ');
              }

              _club = Club(
                id: widget.clubId!,
                name: displayName,
                description: 'Information for this club is not yet available.',
                category: 'General',
                memberCount: 0,
                status: 'active',
                icon: Icons.groups,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }
          });

          // Complete initialization with additional data
          _completeInitialization();
        }
      }).catchError((error) {
        debugPrint('Error fetching club data: $error');
        if (mounted) {
          setState(() {
            _loading = false;

            // Parse the clubId into a better name for fallback
            String displayName = "Unknown Club";
            if (widget.clubId!.contains('space_')) {
              displayName = widget.clubId!
                  .replaceFirst('space_', '')
                  .split('_')
                  .map((word) => word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '')
                  .join(' ');
            }

            // Fallback club on error with better formatting
            _club = Club(
              id: widget.clubId!,
              name: displayName,
              description:
                  'We encountered an error loading data for this club. Please try again later.',
              category: 'General',
              memberCount: 0,
              status: 'error',
              icon: Icons.error_outline,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          });

          // Still try to complete initialization even with fallback club
          _completeInitialization();
        }
      });
    } else {
      // This should never happen due to assertion in constructor
      setState(() {
        _loading = false;
        _club = Club(
          id: 'not-found',
          name: 'Club Not Found',
          description: 'No valid club information was provided',
          category: 'Error',
          memberCount: 0,
          status: 'error',
          icon: Icons.error_outline,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  // Complete initialization with all additional data once club is loaded
  Future<void> _completeInitialization() async {
    // Fetch all required data in parallel
    await Future.wait([
      _fetchEvents(),
      _checkUserPermissions(),
      _checkFollowStatus(),
    ]);

    // Initialize UI components that depend on the above data
    _initializeSocialLinks();
    _getPinnedMessage();
  }

  // Add method to build the locked message board UI with Hive branding
  Widget _buildLockedMessageBoard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hive logo with lock overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/images/hivelogo.png',
                  width: 120,
                  height: 120,
                  color: AppColors.gold,
                ),
              ),
              Container(
                width: 140,
                height: 140, 
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ),
          const SizedBox(height: kSpacingLg),
          Text(
            'Message Board Locked',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: kSpacingSm),
          Container(
            padding: kPaddingHorizLg,
            child: Text(
              'Club needs at least 10 members to unlock message board functionality',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8), // Improved contrast
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: kSpacingLg),
          Container(
            margin: kPaddingHorizMd,
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Current members: ',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  TextSpan(
                    text: '$_followerCount',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  TextSpan(
                    text: ' / 10',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kSpacingXl),
          // Add tooltip to explain why the board is locked
          Tooltip(
            message: 'Get 10 members to unlock the message board',
            child: ElevatedButton(
              onPressed: () => _pageController.animateToPage(0, 
                duration: const Duration(milliseconds: 250), // Faster transition
                curve: Curves.easeInOut),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.gold,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                minimumSize: const Size(44, 44), // Minimum touch target
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppColors.gold,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Back to Club Space',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Clean black and white design with gold accent for join button
  Widget _buildJoinButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _isFollowing = !_isFollowing;
            _followerCount =
                _isFollowing ? _followerCount + 1 : _followerCount - 1;
            _chatUnlocked = _followerCount >= 10;
          });
        },
        // Add visual feedback with splash and highlight colors
        splashColor: _isFollowing ? Colors.white.withOpacity(0.1) : AppColors.gold.withOpacity(0.1),
        highlightColor: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isFollowing ? Colors.black.withOpacity(0.5) : AppColors.gold,
            borderRadius: BorderRadius.circular(30),
            border: _isFollowing
                ? Border.all(color: AppColors.gold, width: 1)
                : null,
          ),
          child: Text(
            _isFollowing ? 'Joined' : 'Join',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _isFollowing ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // Add this method to the class to override the message board page with enhanced Hive styling
  Widget _buildMessageBoardPage() {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Message Board',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: _hugeIconSize),
          onPressed: () => _pageController.animateToPage(0, 
            duration: const Duration(milliseconds: 250), // Faster transition
            curve: Curves.easeInOut),
          tooltip: 'Back to club',
        ),
      ),
      body: _chatUnlocked 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    'assets/images/hivelogo.png',
                    width: 100,
                    height: 100,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: kSpacingLg),
                Text(
                  'Message Board',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: kSpacingSm),
                Padding(
                  padding: kPaddingHorizLg,
                  child: Text(
                    'Chat functionality coming soon',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8), // Improved contrast
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: kSpacingXl),
                ElevatedButton(
                  onPressed: () => _pageController.animateToPage(0, 
                    duration: const Duration(milliseconds: 250), // Faster transition
                    curve: Curves.easeInOut),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    minimumSize: const Size(44, 44), // Minimum touch target
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Back to Club Space',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        : _buildLockedMessageBoard(),
    );
  }

  // Modify the build method to use the enhanced message board page
  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    // Enhance page view with PageController event listeners for feedback
    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Semantics(
            label: 'Club space page with swipeable content',
            hint: 'Swipe left or right to navigate between club space and message board',
            child: PageView(
              controller: _pageController,
              // Add semantics for better accessibility
              children: [
                // Main club space content with semantics
                Semantics(
                  label: 'Club space main content',
                  explicitChildNodes: true,
                  child: _buildMainClubSpace(isMobile),
                ),
                
                // Message board page with semantics
                Semantics(
                  label: 'Club space message board',
                  explicitChildNodes: true,
                  child: _buildMessageBoardPage(),
                ),
              ],
              // Add page change notifications to improve feedback
              onPageChanged: (index) {
                HapticFeedback.lightImpact();
                // Provide visual feedback
                if (index == 0) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Club Space'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.black.withOpacity(0.7),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Message Board'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.black.withOpacity(0.7),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Create a method to build the main club space content (from original Scaffold body)
  Widget _buildMainClubSpace(bool isMobile) {
    // Return your existing Scaffold containing all the club space UI
    // This keeps your layout as requested while adding swipe functionality
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _loading
          ? _buildLoadingState()
          : _club == null
              ? _buildErrorState()
              : _buildClubContent(isMobile),
    );
  }

  // Updated header design with focus on member growth for cold start
  Widget _buildClubHeader() {
    // Get image URL with fallback to a local asset
    final imageUrl = _club?.imageUrl;
    final bool hasProfileImage = imageUrl != null && imageUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image with a monochromatic overlay for black/white aesthetic
        PageView.builder(
          itemCount: 3, // Profile card + Photos + Details
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Main profile card
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: hasProfileImage
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    
                    // If no profile image, show Hive logo centered
                    if (!hasProfileImage)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: 0.7,
                              child: Image.asset(
                                'assets/images/hivelogo.png',
                                width: 120,
                                height: 120,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: kSpacingSm),
                            Text(
                              'This space has yet to add a profile picture',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            } else if (index == 1) {
              // Members showcase - improve layout for small screens
              return Container(
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.7,
                      child: Image.asset(
                        'assets/images/hivelogo.png',
                        width: 80,
                        height: 80,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: kSpacingMd),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _followerCount >= 10 
                          ? 'Message Board Unlocked!' 
                          : 'Help Unlock Message Board',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _followerCount >= 10 ? AppColors.gold : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: kSpacingSm),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 40),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_alt,
                            size: 20,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: kSpacingSm),
                          Text(
                            '$_followerCount / 10 members',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: kSpacingMd),
                    if (_followerCount < 10) 
                      ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Once this club reaches 10 members,\nthe message board will be unlocked',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: kSpacingMd),
                        if (!_isFollowing)
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _isFollowing = true;
                                _followerCount += 1;
                                _chatUnlocked = _followerCount >= 10;
                              });
                            },
                            icon: Icon(Icons.add, size: 18),
                            label: Text('Join Club'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                      ]
                    else 
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Swipe right to access the message board',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.gold,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            } else {
              // Quick bio
              return Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      !hasProfileImage
                      ? Opacity(
                          opacity: 0.7,
                          child: Image.asset(
                            'assets/images/hivelogo.png',
                            width: 80,
                            height: 80,
                            color: AppColors.gold,
                          ),
                        )
                      : const Icon(
                          Icons.info_outline,
                          size: _hugeIconSize,
                          color: AppColors.gold,
                        ),
                      const SizedBox(height: kSpacingMd),
                      Text(
                        'Quick Bio',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: kSpacingSm),
                      Text(
                        _club?.description.substring(
                                0,
                                _club!.description.length > 100
                                    ? 100
                                    : _club!.description.length) ??
                            'No description available',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),

        // Page indicator dots
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0
                      ? AppColors.gold
                      : Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),

        // Club name overlay at the bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 70, // Make room for the join button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _club?.name ?? 'Club Name',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Fix overflow by using Flexible and ellipsis for member count text
              Row(
                mainAxisSize: MainAxisSize.min, // Only take as much space as needed
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_followerCount ${_followerCount == 1 ? 'member' : 'members'}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  if (_followerCount < 10)
                    Flexible(
                      child: Text(
                        ' • Need ${10 - _followerCount} more to unlock',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gold.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Join button as overlay in the bottom right corner
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildJoinButton(),
        ),
      ],
    );
  }

  // New blank customizable about section with glassmorphism
  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassmorphismGuide.kCardBlur, 
            sigmaY: GlassmorphismGuide.kCardBlur
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.1, 1.0],
              ),
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.1),
                width: GlassmorphismGuide.kBorderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About section header with edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'About',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_isClubManager)
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _showAboutEditor();
                          },
                          icon: const Icon(Icons.edit, size: _hugeIconSize * 0.5),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
                              side: BorderSide(
                                color: AppColors.gold.withOpacity(0.3),
                                width: GlassmorphismGuide.kBorderThin,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description with expandable text for long descriptions
                  Text(
                    _customAboutText ?? _club?.description ?? 'No description available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  
                  // Space for social links
                  if (_socialLinks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Connect With Us',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSocialLinks(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Optimize social links section by reducing use of backdrop filters
  Widget _buildSocialLinks() {
    return Wrap(
      spacing: kSpacingSm,
      runSpacing: kSpacingSm,
      children: _socialLinks.entries.map((entry) {
        final String platform = entry.key;
        final String url = entry.value;
        
        // Create simplified button without backdrop filter for better performance
        return Material(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
          child: InkWell(
            onTap: () => _launchSocialLink(url),
            borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
            // Add hover color for better feedback
            hoverColor: AppColors.gold.withOpacity(0.1),
            // Add splash color for better pressed state feedback
            splashColor: AppColors.gold.withOpacity(0.2),
            highlightColor: Colors.black.withOpacity(0.3),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.1),
                  width: GlassmorphismGuide.kBorderThin,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getSocialIcon(platform),
                    size: 18,
                    color: AppColors.gold.withOpacity(0.8),
                  ),
                  const SizedBox(width: kSpacingXs),
                  Text(
                    _getSocialLabel(platform),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Get social media icon based on platform name
  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'twitter':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook_outlined;
      case 'discord':
        return Icons.forum_outlined;
      case 'website':
        return Icons.language_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'linkedin':
        return Icons.work_outline;
      case 'youtube':
        return Icons.play_circle_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      default:
        return Icons.link;
    }
  }

  // Get social media label for display
  String _getSocialLabel(String platform) {
    // Capitalize first letter
    return platform.substring(0, 1).toUpperCase() + platform.substring(1);
  }

  // Launch social link
  void _launchSocialLink(String url) {
    // TODO: Implement URL launching
    // For now, show a snackbar
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Format category name for better display
  String _getTagline() {
    if (_club?.description == null || _club!.description.isEmpty) {
      return 'No description available';
    }

    // If description is short, use it as is
    if (_club!.description.length < 100) {
      return _club!.description;
    }

    // Get first sentence or first 80 chars
    final firstSentence = _club!.description.split('.').first;
    if (firstSentence.length < 100) {
      return '$firstSentence.';
    }

    return '${_club!.description.substring(0, 80)}...';
  }

  // Modified quick stats row with focus on unlocking features
  Widget _buildQuickStatsRow() {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    
    // Calculate progress percentage for member count
    final double memberProgress = _followerCount / 10.0;
    final bool isUnlocked = _followerCount >= 10;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4, vertical: 16),
      child: Column(
        children: [
          // Member count progress indicator
          if (!isUnlocked)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Progress to Message Board',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$_followerCount/10 members',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      // Background track
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Progress indicator with max width constraint
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final progressWidth = maxWidth * memberProgress;
                          return Container(
                            height: 8,
                            width: progressWidth,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: 'Members',
                value: '$_followerCount',
                icon: Icons.people_outline,
                onTap: () {
                  // Members view will be implemented in future update
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_followerCount < 10 
                        ? 'Need ${10 - _followerCount} more members to unlock message board' 
                        : 'Members view coming soon'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isSmallScreen: isSmallScreen,
              ),
              _buildStatItem(
                label: 'Events',
                value: '$_eventCount',
                icon: Icons.event_note,
                onTap: _events.isNotEmpty ? _showEventsList : null,
                isSmallScreen: isSmallScreen,
              ),
              _buildStatItem(
                label: 'Chat',
                value: isUnlocked ? 'Open' : 'Locked',
                icon: isUnlocked ? Icons.chat_bubble_outline : Icons.lock_outline,
                onTap: isUnlocked 
                  ? () => _pageController.animateToPage(1, 
                      duration: const Duration(milliseconds: 250), 
                      curve: Curves.easeInOut)
                  : null,
                isComingSoon: !isUnlocked,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pageController.animateToPage(1, 
                duration: const Duration(milliseconds: 250), 
                curve: Curves.easeInOut),
              borderRadius: BorderRadius.circular(20),
              splashColor: AppColors.gold.withOpacity(0.1),
              highlightColor: Colors.black.withOpacity(0.2),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe_right,
                      size: isSmallScreen ? 24 : _hugeIconSize,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isUnlocked 
                          ? 'Swipe right for message board' 
                          : 'Join to help unlock message board',
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build individual stat item with glassmorphism effect
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool isComingSoon = false,
    bool isSmallScreen = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.mediumImpact();
                onTap();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.all(isSmallScreen ? 2 : 4),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16, 
            horizontal: isSmallScreen ? 4 : 8
          ),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 80),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.1),
              width: GlassmorphismGuide.kBorderThin,
            ),
            boxShadow: onTap != null ? GlassmorphismGuide.goldAccentShadows : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isComingSoon
                    ? Colors.white.withOpacity(0.5)
                    : AppColors.gold.withOpacity(0.8),
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: isComingSoon
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w500,
                  color: isComingSoon
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white.withOpacity(0.9),
                ),
              ),
              if (isComingSoon)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Coming Soon',
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 8 : 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build event card with glassmorphism effect
  Widget _buildEventCard(Event event) {
    final bool isPastEvent = event.startDate.isBefore(DateTime.now());
    final bool isLiveEvent = event.startDate.isBefore(DateTime.now()) &&
        event.endDate.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateToEventDetail(event);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassmorphismGuide.kCardBlur / 2, 
            sigmaY: GlassmorphismGuide.kCardBlur / 2
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
              border: Border.all(
                color: isLiveEvent
                    ? AppColors.gold
                    : isPastEvent
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.gold.withOpacity(0.2),
                width: isLiveEvent
                    ? GlassmorphismGuide.kBorderStandard
                    : GlassmorphismGuide.kBorderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLiveEvent
                      ? AppColors.gold.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event image with overlay
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        image: event.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(event.imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  isPastEvent 
                                      ? Colors.black.withOpacity(0.7)
                                      : Colors.black.withOpacity(0.3),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Gradient overlay for better text readability
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
                          
                          // Date display in bottom left
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatEventDate(event.startDate),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.location,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Event details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: GoogleFonts.outfit(
                              color: isPastEvent
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: GoogleFonts.inter(
                              color: isPastEvent
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Live event or past event indicator
                if (isLiveEvent || isPastEvent)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLiveEvent
                            ? AppColors.gold.withOpacity(0.9)
                            : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusFull),
                        border: Border.all(
                          color: isLiveEvent
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                        boxShadow: isLiveEvent
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLiveEvent) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isLiveEvent ? 'LIVE NOW' : 'PAST EVENT',
                            style: GoogleFonts.inter(
                              color: isLiveEvent ? Colors.black : Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Empty events card with glassmorphism
  Widget _buildEmptyEventsCard() {
    return Material(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
      child: InkWell(
        onTap: _isClubManager ? _handleAddEvent : null,
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        // Only show effects if user is a manager
        splashColor: _isClubManager ? AppColors.gold.withOpacity(0.1) : Colors.transparent,
        highlightColor: _isClubManager ? Colors.black.withOpacity(0.3) : Colors.transparent,
        child: Container(
          padding: kPaddingLg,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: GlassmorphismGuide.kBorderThin,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: _hugeIconSize,
                color: AppColors.gold,
              ),
              const SizedBox(height: kSpacingMd),
              Text(
                'No Upcoming Events',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: kSpacingSm),
              Text(
                _isClubManager 
                  ? 'Tap here to add your first event' 
                  : 'Check back later for updates or follow this space to get notified.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              if (_isClubManager) ...[
                const SizedBox(height: kSpacingMd),
                ElevatedButton.icon(
                  onPressed: _handleAddEvent,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Add method to handle adding an event
  void _handleAddEvent() {
    HapticFeedback.mediumImpact();
    // In a real app, navigate to event creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create a new event for this club'),
        action: SnackBarAction(
          label: 'Create',
          textColor: AppColors.gold,
          onPressed: () {
            // Navigate to event creation
          },
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
    );
  }

  // Method to show bundled events detail in a new modal
  void _showBundledEventsDetail(List<Event> events) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event_repeat,
                              size: _hugeIconSize,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Event Series',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          events.first.title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: _hugeIconSize),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withOpacity(0.1)),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${events.length} related events',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      // Handle RSVP for all events
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('RSVP to all events in series'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: _hugeIconSize * 0.5),
                    label: Text(
                      'RSVP to All',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),

            // Event list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];

                  // Format date parts
                  final day = DateFormat('d').format(event.startDate);
                  final month = DateFormat('MMM').format(event.startDate);
                  final weekday = DateFormat('E').format(event.startDate);
                  final time = DateFormat('h:mm a').format(event.startDate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          // Navigate to event details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening event: ${event.title}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date container with gold accent
                              Container(
                                width: 50,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.cardHighlight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      month,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    Text(
                                      day,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Event details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: _hugeIconSize * 0.7,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          time,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: _hugeIconSize * 0.7,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // RSVP button - made more compact for mobile
                              ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  // RSVP to this individual event
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('RSVP to: ${event.title}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'RSVP',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle edit club action
  void _handleEditClub() {
    HapticFeedback.mediumImpact();
    // Navigate to edit page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit club details'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show events list in a modal
  void _showEventsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'All Events',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_events.length} event${_events.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Event list
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Text(
                        'No upcoming events',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        return _buildEventListItem(_events[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Build event list item for the modal
  Widget _buildEventListItem(Event event) {
    // Format date parts
    final day = DateFormat('d').format(event.startDate);
    final month = DateFormat('MMM').format(event.startDate);
    final time = DateFormat('h:mm a').format(event.startDate);

    // Check if event is cancelled
    final bool isCancelled = event.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
            // Navigate to event details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening event: ${event.title}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date container with gold accent
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.cardHighlight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCancelled
                              ? Colors.red.withOpacity(0.3)
                              : AppColors.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            month,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isCancelled ? Colors.red : AppColors.gold,
                            ),
                          ),
                          Text(
                            day,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCancelled
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCancelled)
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_busy,
                                  size: _hugeIconSize * 1.5,
                                  color: Colors.white24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cancelled',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                          if (isCancelled) const SizedBox(height: 4),
                          Text(
                            event.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCancelled
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.white,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: _hugeIconSize * 0.7,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: _hugeIconSize * 0.7,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (!isCancelled)
                      // RSVP button for the list item
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('RSVP to: ${event.title}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'RSVP',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Cancelled badge in top-right corner if needed
              if (isCancelled)
                Positioned(
                  top: -10,
                  right: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Message board button with clean black/white design
  Widget _buildMessageBoardButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: null, // Disabled as requested
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: _hugeIconSize,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message Board',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coming soon',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.gold.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the loading state with glassmorphism effect
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated logo that rotates for better feedback
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 2 * 3.14159),
            duration: const Duration(seconds: 2),
            builder: (context, double value, child) {
              return Transform.rotate(
                angle: value,
                child: Opacity(
                  opacity: 0.8,
                  child: Image.asset(
                    'assets/images/hivelogo.png',
                    width: 80,
                    height: 80,
                    color: AppColors.gold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: kSpacingLg),
          // Progress indicator with gold color
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: kSpacingMd),
          Text(
            'Loading club space...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: kSpacingSm),
          Text(
            'Please wait while we fetch the latest information',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Show editor dialog for about section with glassmorphism design
  void _showAboutEditor() {
    // Text controller for editor
    final TextEditingController aboutController = TextEditingController(
      text: _customAboutText ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassmorphismGuide.kModalBlur, 
          sigmaY: GlassmorphismGuide.kModalBlur
        ),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(
              maxHeight: 400,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.2),
                width: GlassmorphismGuide.kBorderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassmorphismGuide.kModalBlur / 2, 
                  sigmaY: GlassmorphismGuide.kModalBlur / 2
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit About Section',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          controller: aboutController,
                          maxLines: null,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Describe your space, mission, meeting times, requirements, etc...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
                              borderSide: BorderSide(
                                color: AppColors.gold,
                                width: GlassmorphismGuide.kBorderStandard,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.7),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // In a real app, you would save this to the database
                                _customAboutText = aboutController.text.trim();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Format event date for display
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);
    
    final time = DateFormat('h:mm a').format(date);
    
    if (eventDate == today) {
      return 'Today, $time';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow, $time';
    } else if (date.isBefore(now)) {
      return 'Past Event';
    } else {
      final monthDay = DateFormat('MMM d').format(date);
      return '$monthDay, $time';
    }
  }
  
  // Navigate to event detail page
  void _navigateToEventDetail(Event event) {
    // For now, just show a snackbar with event information
    // This would be replaced with actual navigation in the production app
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening event: ${event.title}'),
        backgroundColor: Colors.black.withOpacity(0.7),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusXs),
        ),
      ),
    );
    
    // In the real implementation, navigate to the event details page:
    // context.push('/events/${event.id}');
  }

  // Error state when club cannot be loaded
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: _hugeIconSize * 2,
            color: AppColors.error,
          ),
          const SizedBox(height: kSpacingMd),
          Text(
            'Could not load club',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: kSpacingSm),
          Padding(
            padding: kPaddingHorizLg,
            child: Text(
              'There was a problem connecting to the server. Please check your internet connection and try again.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: kSpacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  minimumSize: const Size(44, 44),
                ),
                child: const Text('Go Back'),
              ),
              const SizedBox(width: kSpacingMd),
              // Retry button
              ElevatedButton(
                onPressed: () {
                  // Show loading state again
                  setState(() {
                    _loading = true;
                  });
                  // Re-initialize data
                  _initializeData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  minimumSize: const Size(44, 44),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Main club content with all features
  Widget _buildClubContent(bool isMobile) {
    return SafeArea(
      bottom: false, // Allow content to extend behind bottom system UI
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        slivers: [
          // Header section with Tinder-style profile
          SliverAppBar(
            expandedHeight: isMobile ? 350 : 400,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate scroll progress for animations
                final scrollProgress = constraints.biggest.height < 120 
                    ? 1.0 
                    : 1.0 - (constraints.biggest.height - 120) / (isMobile ? 230 : 280);
                
                return Stack(
                  children: [
                    // Background image with parallax effect
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: 1.0 - (scrollProgress * 0.3),
                        child: _buildClubHeader(),
                      ),
                    ),
                    
                    // Glassmorphic header overlay that appears when scrolling
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 60 + (scrollProgress * 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(scrollProgress * 0.7),
                              Colors.black.withOpacity(scrollProgress * 0.3),
                            ],
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: scrollProgress * GlassmorphismGuide.kHeaderBlur,
                            sigmaY: scrollProgress * GlassmorphismGuide.kHeaderBlur,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.gold.withOpacity(scrollProgress * 0.3),
                                  width: scrollProgress * GlassmorphismGuide.kBorderThin,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Condensed title that appears when scrolled
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 56),
                          child: Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: scrollProgress,
                              child: Text(
                                _club?.name ?? 'Club Space',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: _hugeIconSize),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            actions: [
              if (_isClubManager)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusFull),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: GlassmorphismGuide.kCardBlur / 2,
                      sigmaY: GlassmorphismGuide.kCardBlur / 2,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: _hugeIconSize),
                      onPressed: _handleEditClub,
                      tooltip: 'Edit club',
                    ),
                  ),
                ),
            ],
          ),

          // Quick stats row
          SliverToBoxAdapter(
            child: _buildQuickStatsRow(),
          ),

          // About Section - Now blank and customizable
          SliverToBoxAdapter(
            child: _buildAboutSection(),
          ),

          // Upcoming Events Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming Events',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_events.isNotEmpty)
                        TextButton(
                          onPressed: _showEventsList,
                          child: Text(
                            'See All',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _events.isNotEmpty
                      ? _buildEventCard(_events.first)
                      : _buildEmptyEventsCard(),
                ],
              ),
            ),
          ),

          // Add swipe right instruction for message board
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe_right,
                      size: _hugeIconSize,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe right for message board',
                      style: GoogleFonts.inter(
                        fontSize: 14, // Increased from 12
                        color: Colors.white.withOpacity(0.7), // Increased from 0.5
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom padding for safe area
          SliverToBoxAdapter(
            child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 80),
          ),
        ],
      ),
    );
  }
}
