import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../../theme/glassmorphism_guide.dart';
import '../optimized_image.dart';

/// A component that displays the event header with image, title, and organizer information
class EventHeaderSection extends StatelessWidget {
  /// The event to display
  final Event event;

  /// Hero tag for animation
  final String heroTag;

  /// Scroll offset for parallax effect
  final double scrollOffset;

  /// Animation controller for entrance animations
  final AnimationController animationController;

  /// Constructor
  const EventHeaderSection({
    Key? key,
    required this.event,
    required this.heroTag,
    required this.scrollOffset,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCancelled = event.isCancelled;
    final height = MediaQuery.of(context).size.height * 0.45;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Hero image with parallax effect
          SizedBox(
            height: height,
            width: double.infinity,
            child: Hero(
              tag: heroTag,
              child: Transform.scale(
                scale: 1 + (scrollOffset * 0.0005),
                child: OptimizedImage(
                  imageUrl: _getSafeImageUrl(),
                  fit: BoxFit.cover,
                  backgroundColor: AppColors.cardBackground,
                ),
              ),
            ),
          ),

          // Gradient overlay with stronger contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withOpacity(0.5),
                    AppColors.black.withOpacity(0.8),
                    AppColors.black.withOpacity(0.95),
                  ],
                  stops: const [0.4, 0.65, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // Cancelled overlay with diagonal strike-through for cancelled events
          if (isCancelled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                ),
                child: Stack(
                  children: [
                    // Diagonal strike-through line
                    Center(
                      child: Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        transform: Matrix4.rotationZ(0.1),
                      ),
                    ),
                    // Cancelled badge
                    Positioned(
                      top: 80,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy,
                              color: AppColors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Cancelled',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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

          // Event date display
          Positioned(
            top: 96,
            left: 24,
            child: FadeTransition(
              opacity: animationController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animationController,
                  curve: Curves.easeOutCubic,
                )),
                child: _buildDateContainer(),
              ),
            ),
          ),

          // Title and subtitle at the bottom
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organizer name with icon
                FadeTransition(
                  opacity: animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    )),
                    child: Row(
                      children: [
                        Icon(
                          _isClubCreated() ? Icons.groups : Icons.person,
                          color: AppColors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.organizerName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Event title - large and prominent
                FadeTransition(
                  opacity: animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    )),
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Location with icon
                FadeTransition(
                  opacity: animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    )),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location.isNotEmpty
                                ? event.location
                                : 'Location not specified',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the date container with month, day, and year
  Widget _buildDateContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusFull),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.startDate.day.toString(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMonth(event.startDate),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatYear(event.startDate),
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format month to abbreviated name
  String _formatMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[date.month - 1];
  }

  /// Format year
  String _formatYear(DateTime date) {
    return date.year.toString();
  }

  // Helper method to get a safe image URL
  String _getSafeImageUrl() {
    // Return the image URL if it exists and is not empty, otherwise return an empty string
    return event.imageUrl.isNotEmpty ? event.imageUrl : '';
  }

  // Helper method to check if event was created by a club
  bool _isClubCreated() {
    return event.source == EventSource.club;
  }
}
