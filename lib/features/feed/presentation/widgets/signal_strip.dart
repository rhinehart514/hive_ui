import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/presentation/providers/signal_provider.dart';
import 'package:hive_ui/features/feed/presentation/widgets/feed_friend_motion_card.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/main.dart' show firebaseVerificationProvider;

/// A horizontally-scrollable strip that appears at the top of the feed
/// Sets the tone, signals activity, and provides narrative framing
/// Follows brand aesthetic guidelines with glassmorphism effects
class SignalStrip extends ConsumerStatefulWidget {
  /// Custom height for the strip
  final double height;
  
  /// Custom padding for the strip
  final EdgeInsets padding;
  
  /// Callback when a card is tapped
  final Function(SignalContent content)? onCardTap;
  
  /// Maximum number of cards to display
  final int maxCards;
  
  /// Whether to show the header title text
  final bool showHeader;
  
  /// Optional filter for specific signal types
  final List<SignalType>? signalTypes;
  
  /// Whether to use glass effect
  final bool useGlassEffect;
  
  /// Custom opacity for glass effect
  final double glassOpacity;
  
  /// Optional pre-fetched signal content to display
  /// If provided, this will be used instead of fetching from the repository
  final List<SignalContent>? customSignalContent;

  /// Constructor
  const SignalStrip({
    super.key,
    this.height = 110.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.onCardTap,
    this.maxCards = 5,
    this.showHeader = true,
    this.signalTypes,
    this.useGlassEffect = true,
    this.glassOpacity = 0.15,
    this.customSignalContent,
  });

  @override
  ConsumerState<SignalStrip> createState() => _SignalStripState();
}

class _SignalStripState extends ConsumerState<SignalStrip> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Delay initialization to avoid Riverpod build-time errors
    Future.microtask(() => _ensureInitialized());
  }
  
  void _ensureInitialized() {
    // Check and ensure Firebase is initialized
    final firebaseVerifier = ref.read(firebaseVerificationProvider.future);
    firebaseVerifier.then((initialized) {
      if (!initialized) {
        debugPrint('Warning: Firebase not initialized in SignalStrip. Some features may not work.');
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) _buildHeader(),
          SizedBox(
            height: widget.height,
            child: Padding(
              padding: widget.padding,
              child: _buildSignalContent(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.padding.left, 
        right: widget.padding.right,
        bottom: 8,
        top: 4,
      ),
      child: Row(
        children: [
          Text(
            'SIGNAL',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignalContent() {
    // If custom signal content is provided, use it directly
    if (widget.customSignalContent != null) {
      final contentList = widget.customSignalContent!;
      
      if (contentList.isEmpty) {
        return _buildEmptyState();
      }
      
      // Mark the first item as viewed - AFTER the build is complete
      if (contentList.isNotEmpty) {
        // Use microtask to schedule after build completion
        Future.microtask(() {
          // Make sure the widget is still mounted
          if (mounted) {
            ref.read(signalStripProvider.notifier).logContentView(contentList[0].id);
          }
        });
      }
      
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          final content = contentList[index];
          return _buildSignalCard(content);
        },
      );
    }
    
    // Otherwise, fetch from the repository using the provider
    final signalParams = SignalContentParams(
      maxItems: widget.maxCards,
      types: widget.signalTypes,
    );
    
    final signalContentAsync = ref.watch(signalContentProvider(signalParams));
    
    return signalContentAsync.when(
      data: (contentList) {
        if (contentList.isEmpty) {
          return _buildEmptyState();
        }
        
        // Same logic as above - log view for first card
        Future.microtask(() {
          if (mounted && contentList.isNotEmpty) {
            ref.read(signalStripProvider.notifier).logContentView(contentList[0].id);
          }
        });
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final content = contentList[index];
            return _buildSignalCard(content);
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(),
    );
  }
  
  /// Builds a signal card based on the content type
  Widget _buildSignalCard(SignalContent content) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onCardTap != null) {
            widget.onCardTap!(content);
          }
        },
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Card content based on type
              _buildCardContent(content),
              
              // Glass effect overlay (optional)
              if (widget.useGlassEffect)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                      child: Container(
                        color: Colors.black.withOpacity(widget.glassOpacity),
                      ),
                    ),
                  ),
                ),
              
              // Indicator for hot/trending items
              if (content.isHot || content.isTrending)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: content.isHot ? Colors.red.withOpacity(0.9) : AppColors.accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      content.isHot ? '🔥 HOT' : 'TRENDING',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
              // Time indicator for recency
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    _formatTimeAgo(content.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Formats a timestamp into a human-readable string
  String _formatTimeAgo(DateTime? timestamp) {
    if (timestamp == null) return ''; 
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
  
  /// Builds the inner content of the card based on type
  Widget _buildCardContent(SignalContent content) {
    switch (content.type) {
      case SignalType.club:
        return _buildClubCard(content);
      case SignalType.friendMotion:
        return _buildFriendMotionCard(content);
      case SignalType.timeMarker:
        return _buildTimeMarkerCard(content);
      case SignalType.photo:
        return _buildPhotoCard(content);
      case SignalType.space:
        return _buildSpaceCard(content);
      default:
        return _buildDefaultCard(content);
    }
  }
  
  // Various card type implementations
  Widget _buildClubCard(SignalContent content) {
    return Container(
      color: AppColors.dark2,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title ?? 'Club Activity',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Description with emoji
          Text(
            content.description ?? 'Something is happening',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Members info
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${content.memberCount ?? 0} members',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFriendMotionCard(SignalContent content) {
    return Container(
      color: AppColors.dark2,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FeedFriendMotionCard.compact(
                avatarUrl: content.imageUrl,
                username: content.title ?? 'Friend',
                action: content.action ?? 'did something',
                onTap: () {
                  if (widget.onCardTap != null) {
                    widget.onCardTap!(content);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeMarkerCard(SignalContent content) {
    return Container(
      color: AppColors.dark2,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Clock icon
          Icon(
            Icons.access_time_rounded,
            size: 24,
            color: AppColors.accent,
          ),
          
          const SizedBox(height: 8),
          
          // Time text
          Text(
            content.title ?? 'Time marker',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          // Description
          Text(
            content.description ?? '',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoCard(SignalContent content) {
    return Stack(
      children: [
        // Image background
        Positioned.fill(
          child: content.imageUrl != null 
              ? Image.network(
                  content.imageUrl!,
                  fit: BoxFit.cover,
                )
              : Container(color: Colors.grey.shade800),
        ),
        
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Title at bottom
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Text(
            content.title ?? 'Photo Challenge',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpaceCard(SignalContent content) {
    return Container(
      color: AppColors.dark2,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Space title
          Text(
            content.title ?? 'Space Name',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Space description
          Text(
            content.description ?? 'Space description',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Members count
          Row(
            children: [
              const Icon(
                Icons.group,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${content.memberCount ?? 0} members',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultCard(SignalContent content) {
    return Container(
      color: AppColors.dark2,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title ?? 'Signal',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            content.description ?? 'Signal details',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  // State widgets
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No signals yet',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Container(
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.dark2,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Could not load signals',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
} 