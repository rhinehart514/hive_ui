import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';

/// A collapsible header for the space detail screen with parallax effect
class SpaceHeader extends StatelessWidget {
  final Club? club;
  final Space? space;
  final double scrollOffset;
  final bool isFollowing;
  final int memberCount;
  final int eventCount;
  final bool chatUnlocked;
  final VoidCallback onJoinPressed;
  final String? extraInfo;
  
  const SpaceHeader({
    Key? key,
    this.club,
    this.space,
    required this.scrollOffset,
    required this.isFollowing,
    required this.memberCount,
    required this.eventCount,
    required this.chatUnlocked,
    required this.onJoinPressed,
    this.extraInfo,
  }) : super(key: key);
  
  // Calculate header parameters based on scroll position
  double get _headerHeight => 250.0;
  double get _minHeight => 85.0;
  double get _currentHeight => (_headerHeight - scrollOffset.clamp(0.0, _headerHeight - _minHeight)).clamp(_minHeight, _headerHeight);
  double get _expandRatio => ((_currentHeight - _minHeight) / (_headerHeight - _minHeight)).clamp(0.0, 1.0);
  double get _imageParallaxOffset => scrollOffset.clamp(0.0, _headerHeight * 0.4); // Clamped parallax effect
  double get _blurAmount => (15.0 * (1 - _expandRatio)).clamp(0.0, 15.0); // Clamped blur amount
  
  @override
  Widget build(BuildContext context) {
    // Determine the space name and image url from either club or space
    final String spaceName = club?.name ?? space?.name ?? "Space";
    final String? imageUrl = club?.imageUrl ?? space?.imageUrl;
    
    // Get screen metrics safely
    final mediaQuery = MediaQuery.of(context);
    final maxTextHeight = mediaQuery.size.height * 0.1;
    
    return RepaintBoundary(
      child: SizedBox(
        height: _currentHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with parallax effect and caching
            Positioned(
              top: -_imageParallaxOffset,
              left: 0,
              right: 0,
              height: _headerHeight,
              child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholderBackground(),
                    errorWidget: (context, url, error) => _buildPlaceholderBackground(),
                    memCacheHeight: (mediaQuery.size.height * mediaQuery.devicePixelRatio).round(),
                    memCacheWidth: (mediaQuery.size.width * mediaQuery.devicePixelRatio).round(),
                  )
                : _buildPlaceholderBackground(),
            ),
            
            // Gradient overlay with safe opacity values
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
            
            // Optimized blur effect
            if (_blurAmount > 0.1)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAmount * 0.5,
                      sigmaY: _blurAmount * 0.5,
                    ),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ),
            
            // Content with safe layout constraints
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _expandRatio,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, mediaQuery.padding.top + 20, 20, 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * 0.3,
                            ),
                            child: Text(
                              spaceName,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4), // Reduced spacing
                          Container(
                            height: 44, // Reduced fixed height
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    Icons.people_outline,
                                    memberCount.toString(),
                                    'Members',
                                  ),
                                ),
                                const SizedBox(width: 24), // Reduced spacing
                                Expanded(
                                  child: _buildStatColumn(
                                    Icons.event_outlined,
                                    eventCount.toString(),
                                    'Events',
                                  ),
                                ),
                                if (chatUnlocked) ...[
                                  const SizedBox(width: 24), // Reduced spacing
                                  Expanded(
                                    child: _buildStatColumn(
                                      Icons.chat_bubble_outline,
                                      'Open',
                                      'Chat',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Collapsed header with safe layout
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: (1 - _expandRatio).clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: _minHeight,
                  padding: EdgeInsets.fromLTRB(56, mediaQuery.padding.top, 16, 0),
                  child: Text(
                    spaceName,
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            
            // Join button with safe positioning
            Positioned(
              right: 16,
              top: mediaQuery.padding.top,
              child: !isFollowing
                ? TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onJoinPressed();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          GlassmorphismGuide.kRadiusMd,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      minimumSize: const Size(88, 36),
                    ),
                    child: Text(
                      'Join',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
            
            // Back button with safe positioning
            Positioned(
              left: 8,
              top: mediaQuery.padding.top,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                splashRadius: 24,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a stat column with icon, value and label - optimized for reuse
  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: 18, // Slightly reduced size
        ),
        const SizedBox(height: 2), // Reduced spacing
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14, // Slightly reduced font size
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11, // Slightly reduced font size
            color: AppColors.white.withOpacity(0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  // Build a placeholder gradient background when no image is available - optimized for reuse
  Widget _buildPlaceholderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.groups,
          size: 48,
          color: AppColors.white.withOpacity(0.3),
        ),
      ),
    );
  }
} 