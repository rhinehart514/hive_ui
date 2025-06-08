import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// A collapsible header for the space detail screen with parallax effect
class SpaceHeader extends StatelessWidget {
  final SpaceEntity? space;
  final double scrollOffset;
  final bool isFollowing;
  final int memberCount;
  final int eventCount;
  final bool chatUnlocked;
  final VoidCallback onJoinPressed;
  final String? extraInfo;
  
  const SpaceHeader({
    Key? key,
    this.space,
    required this.scrollOffset,
    required this.isFollowing,
    required this.memberCount,
    required this.eventCount,
    required this.chatUnlocked,
    required this.onJoinPressed,
    this.extraInfo,
  }) : super(key: key);
  
  // Calculate header parameters based on scroll position - optimized for smooth animation
  // Reduced header height for mobile
  double get _headerHeight => 220.0; // Reduced from 250 for better mobile optimization
  double get _minHeight => 70.0; // Reduced from 85 for better mobile fit
  double get _currentHeight => (_headerHeight - scrollOffset.clamp(0.0, _headerHeight - _minHeight)).clamp(_minHeight, _headerHeight);
  double get _expandRatio => ((_currentHeight - _minHeight) / (_headerHeight - _minHeight)).clamp(0.0, 1.0);
  double get _imageParallaxOffset => scrollOffset.clamp(0.0, _headerHeight * 0.3); // Reduced parallax effect for better performance
  double get _blurAmount => (12.0 * (1 - _expandRatio)).clamp(0.0, 12.0); // Reduced blur amount for better performance
  
  @override
  Widget build(BuildContext context) {
    // Determine the space name and image url from either club or space
    final String spaceName = space?.name ?? "Space";
    final String? imageUrl = space?.imageUrl;
    
    // Get screen metrics safely
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    
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
                    // Optimize cache size based on screen size
                    memCacheHeight: (mediaQuery.size.height * 0.5 * mediaQuery.devicePixelRatio).round(),
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
                      Colors.black.withOpacity(0.6), // Increased opacity for better text visibility
                    ],
                  ),
                ),
              ),
            ),
            
            // Optimized blur effect - only apply when needed and avoid on low-end devices
            if (_blurAmount > 0.5) // Increased threshold to reduce unnecessary blurs
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAmount * 0.4, // Reduced blur intensity
                      sigmaY: _blurAmount * 0.4, // Reduced blur intensity
                    ),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
              ),
            
            // Content with safe layout constraints and better padding for small screens
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _expandRatio,
                duration: const Duration(milliseconds: 100), // Reduced animation duration
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16 : 20, 
                    mediaQuery.padding.top + (isSmallScreen ? 16 : 20), 
                    isSmallScreen ? 16 : 20, 
                    isSmallScreen ? 16 : 20
                  ),
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
                                fontSize: isSmallScreen ? 24 : 28, // Adaptive font size
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
                            height: 40, // Reduced fixed height
                            margin: const EdgeInsets.only(bottom: 4), // Reduced margin
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    Icons.people_outline,
                                    memberCount.toString(),
                                    'Members',
                                    isSmallScreen,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 16 : 24), // Adaptive spacing
                                Expanded(
                                  child: _buildStatColumn(
                                    Icons.event_outlined,
                                    eventCount.toString(),
                                    'Events',
                                    isSmallScreen,
                                  ),
                                ),
                                if (chatUnlocked) ...[
                                  SizedBox(width: isSmallScreen ? 16 : 24), // Adaptive spacing
                                  Expanded(
                                    child: _buildStatColumn(
                                      Icons.chat_bubble_outline,
                                      'Open',
                                      'Chat',
                                      isSmallScreen,
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
            
            // Collapsed header with safe layout - optimized for small screens
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: (1 - _expandRatio).clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 100), // Reduced animation duration
                child: Container(
                  height: _minHeight,
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 48 : 56, 
                    mediaQuery.padding.top, 
                    isSmallScreen ? 12 : 16, 
                    0
                  ),
                  child: Text(
                    spaceName,
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: isSmallScreen ? 18 : 20, // Adaptive font size
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            
            // Join button with safe positioning and better touch target
            Positioned(
              right: isSmallScreen ? 12 : 16,
              top: mediaQuery.padding.top + (isSmallScreen ? 6 : 8),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      minimumSize: Size(isSmallScreen ? 80 : 88, isSmallScreen ? 32 : 36),
                    ),
                    child: Text(
                      'Join',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 14 : 16, // Adaptive font size
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
            
            // Back button with safe positioning and better touch target
            Positioned(
              left: isSmallScreen ? 4 : 8,
              top: mediaQuery.padding.top + (isSmallScreen ? 2 : 0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                splashRadius: isSmallScreen ? 20 : 24,
                constraints: BoxConstraints(
                  minWidth: isSmallScreen ? 40 : 48,
                  minHeight: isSmallScreen ? 40 : 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a stat column with icon, value and label - optimized for mobile and reuse
  Widget _buildStatColumn(IconData icon, String value, String label, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: isSmallScreen ? 16 : 18, // Adaptive icon size
        ),
        const SizedBox(height: 2), // Reduced spacing
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isSmallScreen ? 12 : 14, // Adaptive font size
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 10 : 11, // Adaptive font size
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