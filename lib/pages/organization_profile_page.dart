import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/providers/event_providers.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/theme/app_colors.dart' as app_colors;
import 'package:hive_ui/services/url_service.dart';
import 'package:hive_ui/services/event_segmentation_service.dart';

// Provider to get events for a specific organization
final organizationEventsProvider = FutureProvider.family
    .autoDispose<List<Event>, String>((ref, orgName) async {
  final events = await ref.watch(eventsProvider.future);
  if (events.isEmpty) return [];

  return events
      .where((event) =>
          (event.organizerName == orgName ||
              event.organizerName.contains(orgName)) &&
          event.status != 'cancelled' &&
          event.status != 'canceled')
      .toList();
});

// Provider to check if user follows the organization
final isFollowingProvider = Provider.family<bool, String>((ref, orgId) {
  final userData = ref.watch(userProvider);
  return userData?.joinedClubs.contains(orgId) ?? false;
});

@immutable
class OrganizationProfilePage extends ConsumerStatefulWidget {
  final Club organization;

  const OrganizationProfilePage({
    super.key,
    required this.organization,
  });

  @override
  ConsumerState<OrganizationProfilePage> createState() =>
      _OrganizationProfilePageState();
}

class _OrganizationProfilePageState
    extends ConsumerState<OrganizationProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isHeaderExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = ref.watch(isFollowingProvider(widget.organization.id));
    final eventsAsync =
        ref.watch(organizationEventsProvider(widget.organization.name));

    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(isFollowing),
          _buildSliverHeader(),
          _buildSliverTabs(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(),
            _buildEventsTab(eventsAsync),
            _buildResourcesTab(),
            _buildMembersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isFollowing) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image or gradient background
            widget.organization.bannerUrl != null
                ? Image.network(
                    widget.organization.bannerUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.organization.brandColor.withOpacity(0.4),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
        IconButton(
          icon: Icon(isFollowing
              ? Icons.notifications_active
              : Icons.notifications_none),
          onPressed: () {
            // TODO: Implement notification toggle
          },
        ),
      ],
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => setState(() => _isHeaderExpanded = !_isHeaderExpanded),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildOrganizationAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.organization.name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildVerificationBadge(),
                            if (widget.organization.isUniversityDepartment) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'UB Department',
                                      style: GoogleFonts.inter(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedCrossFade(
                firstChild: Text(
                  widget.organization.shortDescription,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                secondChild: Text(
                  widget.organization.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                crossFadeState: _isHeaderExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 16),
              _buildMetricsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    final Color badgeColor;
    final String label;
    final IconData icon;

    if (widget.organization.isVerifiedPlus) {
      badgeColor = app_colors.AppColors.gold;
      label = 'Verified+';
      icon = Icons.verified;
    } else if (widget.organization.isVerified) {
      badgeColor = Colors.blue;
      label = 'Verified';
      icon = Icons.verified;
    } else if (widget.organization.isOfficial) {
      badgeColor = Colors.green;
      label = 'Official';
      icon = Icons.check_circle;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricItem(
          icon: Icons.event,
          value: widget.organization.eventCount.toString(),
          label: 'Events',
        ),
        _buildMetricItem(
          icon: Icons.people,
          value: widget.organization.formattedMemberCount,
          label: 'Members',
        ),
        _buildMetricItem(
          icon: Icons.favorite,
          value: widget.organization.followersCount.toString(),
          label: 'Followers',
        ),
        _buildMetricItem(
          icon: Icons.trending_up,
          value: widget.organization.engagementLevel,
          label: 'Engagement',
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: app_colors.AppColors.gold,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: app_colors.AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Events'),
            Tab(text: 'Resources'),
            Tab(text: 'Members'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.organization.mission != null) ...[
          _buildSectionTitle('Mission'),
          Text(
            widget.organization.mission!,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (widget.organization.vision != null) ...[
          _buildSectionTitle('Vision'),
          Text(
            widget.organization.vision!,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildSectionTitle('Contact Information'),
        _buildContactInfo(),
        const SizedBox(height: 24),
        if (widget.organization.meetingTimes.isNotEmpty) ...[
          _buildSectionTitle('Meeting Times'),
          _buildMeetingTimes(),
          const SizedBox(height: 24),
        ],
        if (widget.organization.requirements.isNotEmpty) ...[
          _buildSectionTitle('Membership Requirements'),
          _buildRequirements(),
          const SizedBox(height: 24),
        ],
        if (widget.organization.achievements.isNotEmpty) ...[
          _buildSectionTitle('Achievements'),
          _buildAchievements(),
          const SizedBox(height: 24),
        ],
        if (widget.organization.socialLinks.isNotEmpty) ...[
          _buildSectionTitle('Social Media'),
          _buildSocialLinks(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildEventsTab(AsyncValue<List<Event>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events found',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for upcoming events',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final segments = EventSegmentationService.segmentEvents(
          events,
          isClubMember: false,
        );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: segments.length,
          itemBuilder: (context, index) {
            final segment = segments[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  segment.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // TODO: Add event cards here
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(app_colors.AppColors.gold),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading events: $error',
          style: GoogleFonts.inter(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    if (widget.organization.resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No resources available',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.organization.resources.length,
      itemBuilder: (context, index) {
        final resource = widget.organization.resources.entries.elementAt(index);
        return ListTile(
          leading: const Icon(
            Icons.link,
            color: app_colors.AppColors.gold,
          ),
          title: Text(
            resource.key,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => UrlService.openUrl(resource.value),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    // TODO: Implement members tab
    return const Center(
      child: Text(
        'Members tab coming soon',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.organization.fullLocation.isNotEmpty)
          _buildContactItem(
            icon: Icons.location_on,
            text: widget.organization.fullLocation,
            onTap: () {
              // TODO: Open maps
            },
          ),
        if (widget.organization.email != null)
          _buildContactItem(
            icon: Icons.email,
            text: widget.organization.email!,
            onTap: () =>
                UrlService.openUrl('mailto:${widget.organization.email}'),
          ),
        if (widget.organization.website != null)
          _buildContactItem(
            icon: Icons.language,
            text: widget.organization.website!,
            onTap: () => UrlService.openUrl(widget.organization.website!),
          ),
        ...widget.organization.contactInfo.entries.map(
          (entry) => _buildContactItem(
            icon: _getContactIcon(entry.key),
            text: entry.value,
            onTap: () {
              // TODO: Handle contact action based on type
            },
          ),
        ),
      ],
    );
  }

  IconData _getContactIcon(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return Icons.phone;
      case 'fax':
        return Icons.print;
      case 'discord':
        return Icons.discord;
      case 'slack':
        return Icons.chat;
      default:
        return Icons.contact_mail;
    }
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: app_colors.AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingTimes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.organization.meetingTimes.map((time) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: app_colors.AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.organization.requirements.map((req) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: app_colors.AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.organization.achievements.map((achievement) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.star,
                color: app_colors.AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialLinks() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: widget.organization.socialLinks.map((link) {
        final platform = _getSocialPlatform(link);
        return InkWell(
          onTap: () => UrlService.openUrl(link),
          child: Column(
            children: [
              Icon(
                _getSocialIcon(platform),
                color: app_colors.AppColors.gold,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                platform,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getSocialPlatform(String url) {
    if (url.contains('instagram')) return 'Instagram';
    if (url.contains('facebook')) return 'Facebook';
    if (url.contains('twitter')) return 'Twitter';
    if (url.contains('linkedin')) return 'LinkedIn';
    if (url.contains('youtube')) return 'YouTube';
    if (url.contains('discord')) return 'Discord';
    if (url.contains('github')) return 'GitHub';
    return 'Website';
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.photo_camera;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.flutter_dash;
      case 'linkedin':
        return Icons.work;
      case 'youtube':
        return Icons.play_circle_filled;
      case 'discord':
        return Icons.chat;
      case 'github':
        return Icons.code;
      default:
        return Icons.link;
    }
  }

  Widget _buildOrganizationAvatar() {
    const double size = 80;

    if (widget.organization.isUniversityDepartment) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/ublogo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.organization.avatarColor,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        image: widget.organization.logoUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.organization.logoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.organization.logoUrl == null
          ? Center(
              child: Text(
                widget.organization.initial,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
