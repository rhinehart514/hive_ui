import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import 'event_time_display.dart';

/// A component that displays detailed event information like time, location, and metadata
class EventDetailsSection extends StatelessWidget {
  /// The event to display
  final Event event;

  /// Animation controller for entrance animation
  final AnimationController animationController;

  /// Callback when tapping on the organizer to navigate to club space
  final VoidCallback? onOrganizerTap;

  /// Constructor
  const EventDetailsSection({
    Key? key,
    required this.event,
    required this.animationController,
    this.onOrganizerTap,
  }) : super(key: key);

  // Helper method to check if event was created by a club
  bool _isClubCreated() {
    return event.source == EventSource.club;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animationController,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time section with visual indicator
              EventTimeDisplay(
                startDate: event.startDate,
                endDate: event.endDate,
                showYear: true,
                showWeekday: true,
                showEndTime: true,
              ),

              const SizedBox(height: 16),

              // Divider line
              Container(
                height: 1,
                width: double.infinity,
                color: AppColors.white.withOpacity(0.1),
              ),

              const SizedBox(height: 16),

              // Location details
              if (event.location.isNotEmpty)
                _buildInfoSection(
                  title: 'Location',
                  icon: Icons.location_on_outlined,
                  content: _buildLocation(),
                ),

              // Organizer details
              if (event.organizerName.isNotEmpty)
                _buildInfoSection(
                  title: 'Organizer',
                  icon: _isClubCreated() ? Icons.groups : Icons.person,
                  content: _buildOrganizer(),
                  onTap: _isClubCreated() ? onOrganizerTap : null,
                ),

              // Category
              if (event.category.isNotEmpty)
                _buildInfoSection(
                  title: 'Category',
                  icon: Icons.category_outlined,
                  content: _buildCategory(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section with title, icon, and content
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Widget content,
    VoidCallback? onTap,
  }) {
    final Widget sectionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
                size: 12,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Section content
        content,
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: sectionContent,
            )
          : sectionContent,
    );
  }

  /// Build location section with map link if available
  Widget _buildLocation() {
    final bool canShowMap = event.location.isNotEmpty && 
        !event.location.toLowerCase().contains('virtual') &&
        !event.location.toLowerCase().contains('online') &&
        !event.location.toLowerCase().contains('zoom') &&
        !event.location.toLowerCase().contains('teams') &&
        !event.location.toLowerCase().contains('meet');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.location,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Add map link button if location is physical
          if (canShowMap)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () {
                  // In the future, this could open a map
                  // Implement map opening functionality
                },
                icon: const Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: AppColors.white,
                ),
                label: const Text(
                  'View on Map',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.white.withOpacity(0.5),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build organizer section with contact info if available
  Widget _buildOrganizer() {
    final bool hasEmail = event.organizerEmail.isNotEmpty;
    final bool isClub = _isClubCreated();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClub
              ? AppColors.white.withOpacity(0.2)
              : AppColors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organizer name with arrow if it's a club
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.organizerName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isClub)
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.white,
                  size: 16,
                ),
            ],
          ),

          // Organizer email if available
          if (hasEmail) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: AppColors.white.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.organizerEmail,
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build category with styled chip
  Widget _buildCategory() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            event.category,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
