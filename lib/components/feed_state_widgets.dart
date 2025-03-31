import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/glassmorphism_guide.dart';
import '../extensions/glassmorphism_extension.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Loading state widget for the feed
class FeedLoadingState extends StatelessWidget {
  /// Constructor
  const FeedLoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildLoadingCard(),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a loading card placeholder
  Widget _buildLoadingCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        border: Border.all(
          color: AppColors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GlassmorphismGuide.kRadiusMd),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Content placeholders
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                Container(
                  height: 20,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),

                // Info row placeholder
                Row(
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description placeholder
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).addGlassmorphism(
      blur: GlassmorphismGuide.kCardBlur,
      opacity: GlassmorphismGuide.kCardGlassOpacity,
      borderRadius: GlassmorphismGuide.kRadiusMd,
    );
  }
}

/// Error state widget for the feed
class FeedErrorState extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Callback for retry button
  final VoidCallback onRetry;

  /// Constructor
  const FeedErrorState({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.1),
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
                ),
              ),
            ),
          ],
        ),
      ).addGlassmorphism(
        blur: GlassmorphismGuide.kCardBlur,
        opacity: GlassmorphismGuide.kCardGlassOpacity,
        borderRadius: GlassmorphismGuide.kRadiusMd,
      ),
    );
  }
}

/// Empty state widget for the feed
class FeedEmptyState extends StatelessWidget {
  /// Message to display
  final String message;

  /// Icon to display
  final IconData icon;

  /// Optional action button
  final Widget? actionButton;

  /// Constructor
  const FeedEmptyState({
    Key? key,
    required this.message,
    this.icon = Icons.event_busy_outlined,
    this.actionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) const SizedBox(height: 24),
            if (actionButton != null) actionButton!,
          ],
        ),
      ).addGlassmorphism(
        blur: GlassmorphismGuide.kCardBlur,
        opacity: GlassmorphismGuide.kCardGlassOpacity,
        borderRadius: GlassmorphismGuide.kRadiusMd,
      ),
    );
  }
}

/// Pagination loading indicator
class FeedLoadingIndicator extends StatefulWidget {
  /// Callback when the indicator becomes visible
  final VoidCallback onVisible;

  /// Constructor
  const FeedLoadingIndicator({
    Key? key,
    required this.onVisible,
  }) : super(key: key);

  @override
  State<FeedLoadingIndicator> createState() => _FeedLoadingIndicatorState();
}

class _FeedLoadingIndicatorState extends State<FeedLoadingIndicator> {
  @override
  void initState() {
    super.initState();
    // Call onVisible when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
